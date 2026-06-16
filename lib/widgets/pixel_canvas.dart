import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/color_order.dart';
import '../models/display_layout.dart';

/// Renders a [DisplayLayout]'s pixels coloured from the latest DDP [frame].
///
/// Each cell's node N reads three bytes at `channelOffset + (N-1)*3`, reordered
/// per [colorOrder]. Missing/out-of-range channels render black. The grid is
/// scaled to fit and centred in the available space.
class PixelCanvas extends StatelessWidget {
  final DisplayLayout layout;
  final Uint8List frame;
  final int channelOffset;
  final ColorOrder colorOrder;

  const PixelCanvas({
    super.key,
    required this.layout,
    required this.frame,
    required this.channelOffset,
    required this.colorOrder,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PixelPainter(
        layout: layout,
        frame: frame,
        channelOffset: channelOffset,
        colorOrder: colorOrder,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _PixelPainter extends CustomPainter {
  final DisplayLayout layout;
  final Uint8List frame;
  final int channelOffset;
  final ColorOrder colorOrder;

  _PixelPainter({
    required this.layout,
    required this.frame,
    required this.channelOffset,
    required this.colorOrder,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dark backdrop.
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF101014));

    final w = layout.gridWidth;
    final h = layout.gridHeight;
    if (w < 1 || h < 1) return;

    // Fit the grid into the canvas, leaving a small margin.
    const margin = 8.0;
    final availW = size.width - margin * 2;
    final availH = size.height - margin * 2;
    final cell = (availW / w < availH / h ? availW / w : availH / h);
    if (cell <= 0) return;

    final gridW = cell * w;
    final gridH = cell * h;
    final originX = (size.width - gridW) / 2;
    final originY = (size.height - gridH) / 2;

    final pad = cell * 0.08; // gap between pixels
    final dotSize = cell - pad * 2;
    final radius = Radius.circular(dotSize * 0.18);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final c in layout.cells) {
      final color = _colorForNode(c.node);
      paint.color = color;
      final left = originX + c.col * cell + pad;
      final top = originY + c.row * cell + pad;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, dotSize, dotSize), radius),
        paint,
      );
    }
  }

  Color _colorForNode(int node) {
    final base = channelOffset + (node - 1) * 3;
    if (base < 0 || base + 2 >= frame.length) {
      return const Color(0xFF1C1C22); // unlit pixel
    }
    final r = frame[base + colorOrder.rIndex];
    final g = frame[base + colorOrder.gIndex];
    final b = frame[base + colorOrder.bIndex];
    return Color.fromARGB(255, r, g, b);
  }

  @override
  bool shouldRepaint(_PixelPainter old) =>
      old.frame != frame ||
      old.layout != layout ||
      old.channelOffset != channelOffset ||
      old.colorOrder != colorOrder;
}
