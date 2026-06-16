/// Byte order of an RGB pixel in the incoming channel data. WS2812 strips are
/// usually GRB; many other devices are RGB. The three bytes at a pixel's base
/// channel are reordered into true (R, G, B) for display.
enum ColorOrder {
  rgb('RGB', 0, 1, 2),
  grb('GRB', 1, 0, 2),
  bgr('BGR', 2, 1, 0),
  rbg('RBG', 0, 2, 1),
  gbr('GBR', 2, 0, 1),
  brg('BRG', 1, 2, 0);

  /// Index within the 3-byte group that holds the red / green / blue value.
  final String label;
  final int rIndex;
  final int gIndex;
  final int bIndex;

  const ColorOrder(this.label, this.rIndex, this.gIndex, this.bIndex);
}
