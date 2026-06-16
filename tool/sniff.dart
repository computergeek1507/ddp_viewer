// Diagnostic: bind UDP 4048 and print any datagram that arrives (source, size,
// first header bytes). Runs ~10s then exits. Uses reuseAddress so it can listen
// alongside the app.
import 'dart:async';
import 'dart:io';

Future<void> main() async {
  final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4, 4048,
      reuseAddress: true);
  final ifs = await NetworkInterface.list(
      type: InternetAddressType.IPv4, includeLoopback: false);
  for (final i in ifs) {
    for (final a in i.addresses) {
      stdout.writeln('  local: ${i.name} -> ${a.address}');
    }
  }
  stdout.writeln('Sniffing UDP 4048 for 20s on 0.0.0.0 ...');
  var count = 0;
  socket.listen((event) {
    if (event != RawSocketEvent.read) return;
    final dg = socket.receive();
    if (dg == null) return;
    count++;
    if (count <= 12) {
      final h = dg.data
          .take(10)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(' ');
      stdout.writeln(
          'pkt #$count from ${dg.address.address}  ${dg.data.length} bytes  hdr[$h]');
    }
  });
  await Future.delayed(const Duration(seconds: 20));
  stdout.writeln('Done. Total packets: $count');
  socket.close();
}
