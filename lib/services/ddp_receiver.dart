import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Live counters shown in the stats overlay. Immutable snapshot republished
/// once per second.
@immutable
class DdpStats {
  final double fps; // frames per second
  final double packetsPerSecond;
  final int lastSequence; // 0..15
  final int pixelCount; // displayed channels / 3
  final String sourceIp; // last datagram source, or ''
  final bool receiving; // saw any data in the last ~2s

  const DdpStats({
    this.fps = 0,
    this.packetsPerSecond = 0,
    this.lastSequence = 0,
    this.pixelCount = 0,
    this.sourceIp = '',
    this.receiving = false,
  });
}

/// Listens for Distributed Display Protocol (DDP) pixel data on UDP [port] and
/// reassembles frames into a flat channel buffer.
///
/// Packet layout (inverse of pixel_mapper's `DdpSender`): a 10-byte header then
/// raw channel bytes. Byte 0 = flags (bit0 = PUSH), byte 1 = sequence (0..15),
/// bytes 4-7 = big-endian byte offset into the buffer, bytes 8-9 = big-endian
/// data length.
///
/// Rendering is decoupled from packet arrival to stay flicker-free regardless
/// of how a sender chunks frames or uses the PUSH flag:
///   * The channel [_buffer] is persistent — written in place at each packet's
///     absolute offset, never cleared between frames.
///   * A frame boundary is detected when a packet arrives at `offset == 0`; the
///     size of the just-completed frame becomes the sticky [_displayLen].
///   * A fixed-rate timer publishes a snapshot of the buffer to [frame], so the
///     UI repaints smoothly and never sees a half-assembled (dark) frame.
class DdpReceiver {
  static const int defaultPort = 4048;
  final int port;

  RawDatagramSocket? _socket;

  /// Latest frame snapshot (flat channel bytes). Listeners repaint on change.
  final ValueNotifier<Uint8List> frame = ValueNotifier(Uint8List(0));
  final ValueNotifier<DdpStats> stats = ValueNotifier(const DdpStats());
  final ValueNotifier<String?> error = ValueNotifier(null);

  /// This machine's local IPv4 address(es), each labelled with its interface
  /// name (e.g. "192.168.1.5 (Ethernet)") — where a sender should target DDP.
  final ValueNotifier<List<String>> localAddresses = ValueNotifier(const []);

  // Persistent channel buffer (offsets are absolute, so we keep it across
  // frames and just overwrite).
  Uint8List _buffer = Uint8List(0);
  int _curMax = 0; // max (offset+len) written in the in-progress frame
  int _displayLen = 0; // sticky size of the last complete frame
  bool _dirty = false; // new data since the last publish

  // Rolling 1-second counters.
  int _packetsThisSecond = 0;
  int _framesThisSecond = 0;
  int _lastSequence = 0;
  String _sourceIp = '';
  int _lastDataMs = 0;
  Timer? _statsTimer;
  Timer? _renderTimer;

  DdpReceiver({this.port = defaultPort});

  Future<void> start() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    } on SocketException catch (e) {
      error.value =
          'Could not listen on UDP $port: ${e.osError?.message ?? e.message}';
      return;
    }
    error.value = null;
    _socket!.listen(_onSocketEvent);
    _statsTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _publishStats());
    // ~60fps publish, but only when new data has arrived.
    _renderTimer =
        Timer.periodic(const Duration(milliseconds: 16), (_) => _publishFrame());
    await _loadLocalAddresses();
  }

  /// Enumerates non-loopback IPv4 interface addresses so the UI can tell the
  /// user where to point their DDP sender.
  Future<void> _loadLocalAddresses() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      final addrs = [
        for (final iface in interfaces)
          for (final addr in iface.addresses)
            '${addr.address} (${iface.name})',
      ];
      localAddresses.value = addrs;
    } catch (_) {
      // Non-fatal; the listen port still works even if enumeration fails.
    }
  }

  void _onSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    // Drain all queued datagrams: a single read event can represent several
    // datagrams, and receive() returns only one at a time. Reading just once
    // would silently drop the rest of a multi-packet frame.
    while (true) {
      final dg = _socket!.receive();
      if (dg == null) break;
      _handlePacket(dg.data, dg.address.address);
    }
  }

  void _handlePacket(Uint8List data, String src) {
    if (data.length < 10) return; // too short for a DDP header

    final sequence = data[1] & 0x0F;
    final offset = (data[4] << 24) | (data[5] << 16) | (data[6] << 8) | data[7];
    var length = (data[8] << 8) | data[9];

    // Clamp declared length to what actually arrived.
    final available = data.length - 10;
    if (length > available) length = available;
    if (length < 0 || offset < 0) return;

    // A packet at offset 0 starts a new frame: the previous one is now complete,
    // so its size becomes what we render. Keyed on offset (not the PUSH flag) so
    // senders that set PUSH on every packet don't cause partial-frame flicker.
    if (offset == 0 && _curMax > 0) {
      _displayLen = _curMax;
      _framesThisSecond++;
      _curMax = 0;
    }

    final end = offset + length;
    _ensureCapacity(end);
    _buffer.setRange(offset, end, data, 10);
    if (end > _curMax) _curMax = end;

    _packetsThisSecond++;
    _lastSequence = sequence;
    _sourceIp = src;
    _lastDataMs = DateTime.now().millisecondsSinceEpoch;
    _dirty = true;
  }

  void _ensureCapacity(int needed) {
    if (_buffer.length >= needed) return;
    var newLen = _buffer.isEmpty ? 1536 : _buffer.length;
    while (newLen < needed) {
      newLen *= 2;
    }
    final grown = Uint8List(newLen);
    grown.setRange(0, _buffer.length, _buffer);
    _buffer = grown;
  }

  void _publishFrame() {
    if (!_dirty) return;
    _dirty = false;
    // Render the larger of the last complete frame and the in-progress one, so
    // the visible length only ever grows or holds — never collapses to black.
    final renderLen = _displayLen > _curMax ? _displayLen : _curMax;
    if (renderLen <= 0 || renderLen > _buffer.length) return;
    frame.value = _buffer.sublist(0, renderLen);
  }

  void _publishStats() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final receiving = nowMs - _lastDataMs < 2000;
    stats.value = DdpStats(
      fps: _framesThisSecond.toDouble(),
      packetsPerSecond: _packetsThisSecond.toDouble(),
      lastSequence: _lastSequence,
      pixelCount: frame.value.length ~/ 3,
      sourceIp: _sourceIp,
      receiving: receiving,
    );
    _packetsThisSecond = 0;
    _framesThisSecond = 0;
  }

  void dispose() {
    _statsTimer?.cancel();
    _renderTimer?.cancel();
    _socket?.close();
    frame.dispose();
    stats.dispose();
    error.dispose();
    localAddresses.dispose();
  }
}
