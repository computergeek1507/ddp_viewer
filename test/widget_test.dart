import 'package:flutter_test/flutter_test.dart';

import 'package:ddp_viewer/models/custom_grid.dart';
import 'package:ddp_viewer/models/display_layout.dart';
import 'package:ddp_viewer/services/xmodel_importer.dart';

void main() {
  test('matrix layout numbers nodes row-major', () {
    final layout = DisplayLayout.matrix(3, 2);
    expect(layout.gridWidth, 3);
    expect(layout.gridHeight, 2);
    expect(layout.cells.length, 6);
    expect(layout.pixelCount, 6);
    final topLeft = layout.cells.firstWhere((c) => c.row == 0 && c.col == 0);
    expect(topLeft.node, 1);
    final next = layout.cells.firstWhere((c) => c.row == 0 && c.col == 1);
    expect(next.node, 2);
    final secondRow = layout.cells.firstWhere((c) => c.row == 1 && c.col == 0);
    expect(secondRow.node, 4);
  });

  test('fromCompressed parses node,row,col triples', () {
    final grid =
        CustomGrid.fromCompressed('1,0,0;2,0,1;3,1,0', width: 2, height: 2);
    expect(grid.width, 2);
    expect(grid.height, 2);
    expect(grid.cells.length, 3);
    final n2 = grid.cells.firstWhere((c) => c.node == 2);
    expect(n2.row, 0);
    expect(n2.col, 1);
  });

  test('fromLegacyGrid infers shape and skips blanks', () {
    final grid = CustomGrid.fromLegacyGrid('1,,3;4,5,6');
    expect(grid.width, 3);
    expect(grid.height, 2);
    expect(grid.cells.length, 5); // the blank cell is skipped
    final n3 = grid.cells.firstWhere((c) => c.node == 3);
    expect(n3.row, 0);
    expect(n3.col, 2);
  });

  test('importXModel reads a custommodel (compressed)', () {
    const xml = '<?xml version="1.0" encoding="UTF-8"?>'
        '<custommodel name="t" CustomWidth="2" CustomHeight="1" '
        'CustomModelCompressed="1,0,0;2,0,1"/>';
    final grid = importXModel(xml);
    expect(grid.width, 2);
    expect(grid.cells.length, 2);
  });

  test('importXModel rejects dmxmodel', () {
    const xml = '<dmxmodel name="fixture" parm1="6"/>';
    expect(() => importXModel(xml), throwsA(isA<XModelImportException>()));
  });
}
