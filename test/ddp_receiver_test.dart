import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:ddp_viewer/services/ddp_receiver.dart';

/// Builds a single DDP packet (10-byte header + payload). [push] sets the PUSH
/// flag that tells the receiver the frame is complete.
Uint8List _packet(int offset, List<int> data, {bool push = true, int seq = 1}) {
  final p = Uint8List(10 + data.length);
  p[0] = push ? 0x41 : 0x40;
  p[1] = seq & 0x0F;
  p[3] = 0x01;
  p[4] = (offset >> 24) & 0xFF;
  p[5] = (offset >> 16) & 0xFF;
  p[6] = (offset >> 8) & 0xFF;
  p[7] = offset & 0xFF;
  p[8] = (data.length >> 8) & 0xFF;
  p[9] = data.length & 0xFF;
  p.setRange(10, 10 + data.length, data);
  return p;
}

void main() {
  test('receiver reassembles a two-packet frame and publishes on PUSH',
      () async {
    // Use a non-standard port so it doesn't clash with a running app on 4048.
    final receiver = DdpReceiver(port: 14048);
    await receiver.start();
    addTearDown(receiver.dispose);
    expect(receiver.error.value, isNull,
        reason: 'should bind cleanly: ${receiver.error.value}');

    final sender = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    addTearDown(sender.close);
    final dest = InternetAddress('127.0.0.1');

    // Wait for the frame notifier to fire.
    final completer = Completer<Uint8List>();
    void listener() {
      // Wait for the whole 12-byte frame (a partial wipe-in may publish first).
      if (!completer.isCompleted && receiver.frame.value.length >= 12) {
        completer.complete(receiver.frame.value);
      }
    }

    receiver.frame.addListener(listener);
    addTearDown(() => receiver.frame.removeListener(listener));

    // Frame = 4 pixels (12 bytes). Send as two packets; only the 2nd has PUSH.
    sender.send(_packet(0, [10, 20, 30, 40, 50, 60], push: false, seq: 5),
        dest, 14048);
    sender.send(_packet(6, [70, 80, 90, 100, 110, 120], push: true, seq: 5),
        dest, 14048);

    final frame = await completer.future.timeout(const Duration(seconds: 3));

    expect(frame.length, 12, reason: '4 pixels * 3 bytes');
    expect(frame.sublist(0, 6), [10, 20, 30, 40, 50, 60]);
    expect(frame.sublist(6, 12), [70, 80, 90, 100, 110, 120]);
  });
}
