import 'custom_grid.dart';

/// A layout the [PixelCanvas] paints against. Decouples the rendering from
/// where the layout came from (a generated matrix or an imported `.xmodel`).
///
/// Coordinates: [gridWidth] x [gridHeight] cells, each [GridCell] holds the
/// xLights 1-based [node] number at a 0-based (row, col). Node N reads its
/// color from DDP channel `offset + (N-1)*3`.
class DisplayLayout {
  final String name;
  final int gridWidth;
  final int gridHeight;
  final List<GridCell> cells;

  const DisplayLayout({
    required this.name,
    required this.gridWidth,
    required this.gridHeight,
    required this.cells,
  });

  /// Total pixels addressed by this layout (highest node number).
  int get pixelCount {
    var maxNode = 0;
    for (final c in cells) {
      if (c.node > maxNode) maxNode = c.node;
    }
    return maxNode;
  }

  /// A dense row-major matrix: node `row*width + col + 1`, left-to-right then
  /// top-to-bottom. This matches how a plain matrix is wired and how senders
  /// like xLights lay channels out for a simple grid.
  factory DisplayLayout.matrix(int width, int height) {
    final w = width < 1 ? 1 : width;
    final h = height < 1 ? 1 : height;
    final cells = <GridCell>[];
    for (var row = 0; row < h; row++) {
      for (var col = 0; col < w; col++) {
        cells.add(GridCell(node: row * w + col + 1, col: col, row: row));
      }
    }
    return DisplayLayout(
      name: '${w}x$h matrix',
      gridWidth: w,
      gridHeight: h,
      cells: cells,
    );
  }

  /// Wraps an imported xLights Custom model.
  factory DisplayLayout.fromGrid(CustomGrid grid, {required String name}) {
    return DisplayLayout(
      name: name,
      gridWidth: grid.width < 1 ? 1 : grid.width,
      gridHeight: grid.height < 1 ? 1 : grid.height,
      cells: grid.cells,
    );
  }
}
