// Dev-only DDP test source. Sends an animated rainbow to a DDP receiver so the
// viewer can be verified end-to-end with no hardware.
//
//   dart run tool/test_sender.dart                 # 32x16 -> 127.0.0.1:4048
//   dart run tool/test_sender.dart 10.0.0.42 64 32 # ip width height
//
// Packetization mirrors pixel_mapper's DdpSender.buildPackets (10-byte header,
// big-endian offset/length, PUSH on the final packet).

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int ddpPort = 4048;
const int maxPixelsPerPacket = 480;

Future<void> main(List<String> args) async {
  final ip = args.isNotEmpty ? args[0] : '127.0.0.1';
  final width = args.length > 1 ? int.parse(args[1]) : 32;
  final height = args.length > 2 ? int.parse(args[2]) : 16;
  final pixelCount = width * height;

  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final dest = InternetAddress(ip);
  final rgb = Uint8List(pixelCount * 3);

  stdout.writeln(
      'Sending ${width}x$height ($pixelCount px) rainbow to $ip:$ddpPort at 30fps. Ctrl+C to stop.');

  var sequence = 0;
  var phase = 0.0;
  Timer.periodic(const Duration(milliseconds: 33), (_) {
    // Diagonal moving rainbow.
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final hue = ((x + y) / (width + height) + phase) % 1.0;
        final c = _hsv(hue, 1.0, 1.0);
        final base = (y * width + x) * 3;
        rgb[base] = c[0];
        rgb[base + 1] = c[1];
        rgb[base + 2] = c[2];
      }
    }
    phase = (phase + 0.01) % 1.0;
    sequence = sequence >= 15 ? 1 : sequence + 1;
    for (final pkt in _buildPackets(rgb, sequence)) {
      socket.send(pkt, dest, ddpPort);
    }
  });
}

List<int> _hsv(double h, double s, double v) {
  final i = (h * 6).floor();
  final f = h * 6 - i;
  final p = v * (1 - s);
  final q = v * (1 - f * s);
  final t = v * (1 - (1 - f) * s);
  double r, g, b;
  switch (i % 6) {
    case 0:
      r = v; g = t; b = p; break;
    case 1:
      r = q; g = v; b = p; break;
    case 2:
      r = p; g = v; b = t; break;
    case 3:
      r = p; g = q; b = v; break;
    case 4:
      r = t; g = p; b = v; break;
    default:
      r = v; g = p; b = q; break;
  }
  return [(r * 255).round(), (g * 255).round(), (b * 255).round()];
}

/// Mirrors pixel_mapper's DdpSender.buildPackets — RGB byte order on the wire.
List<Uint8List> _buildPackets(Uint8List rgb, int sequence) {
  const destId = 0x01;
  final pixelCount = rgb.length ~/ 3;
  final packets = <Uint8List>[];
  if (pixelCount == 0) return packets;

  var pixel = 0;
  while (pixel < pixelCount) {
    final chunkPixels = math.min(maxPixelsPerPacket, pixelCount - pixel);
    final chunkStartByte = pixel * 3;
    final chunkLen = chunkPixels * 3;
    final isLast = (pixel + chunkPixels) >= pixelCount;

    final packet = Uint8List(10 + chunkLen);
    packet[0] = isLast ? 0x41 : 0x40; // PUSH on final packet
    packet[1] = sequence & 0x0F;
    packet[2] = 0x00;
    packet[3] = destId;
    packet[4] = (chunkStartByte >> 24) & 0xFF;
    packet[5] = (chunkStartByte >> 16) & 0xFF;
    packet[6] = (chunkStartByte >> 8) & 0xFF;
    packet[7] = chunkStartByte & 0xFF;
    packet[8] = (chunkLen >> 8) & 0xFF;
    packet[9] = chunkLen & 0xFF;
    packet.setRange(10, 10 + chunkLen, rgb, chunkStartByte);
    packets.add(packet);
    pixel += chunkPixels;
  }
  return packets;
}
