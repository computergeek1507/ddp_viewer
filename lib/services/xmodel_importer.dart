import 'package:xml/xml.dart';

import '../models/custom_grid.dart';

/// Thrown when a `.xmodel` file isn't a Custom (pixel-grid) model we can render.
class XModelImportException implements Exception {
  final String message;
  XModelImportException(this.message);
  @override
  String toString() => message;
}

/// Parses an xLights single-model file (`.xmodel`) into a [CustomGrid].
///
/// Inverse of pixel_mapper's `XModelExporter`: prefers the modern
/// `CustomModelCompressed` attribute, falling back to the legacy `CustomModel`
/// grid. Only `custommodel` roots are supported — DMX fixtures (`dmxmodel`) and
/// other model types have no pixel grid and are rejected with a clear message.
CustomGrid importXModel(String xml) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xml);
  } on XmlException catch (e) {
    throw XModelImportException('Not a valid XML file: ${e.message}');
  }

  final root = doc.rootElement;
  final tag = root.name.local.toLowerCase();
  if (tag != 'custommodel') {
    if (tag == 'dmxmodel') {
      throw XModelImportException(
          'This is a DMX fixture model, not a pixel grid — nothing to render.');
    }
    throw XModelImportException(
        "Unsupported model type '<${root.name.local}>'. Only Custom pixel "
        'models (<custommodel>) are supported.');
  }

  final width = int.tryParse(root.getAttribute('CustomWidth') ?? '') ?? 0;
  final height = int.tryParse(root.getAttribute('CustomHeight') ?? '') ?? 0;

  final compressed = root.getAttribute('CustomModelCompressed');
  if (compressed != null && compressed.trim().isNotEmpty) {
    final grid =
        CustomGrid.fromCompressed(compressed, width: width, height: height);
    if (grid.cells.isNotEmpty) return grid;
  }

  final legacy = root.getAttribute('CustomModel');
  if (legacy != null && legacy.trim().isNotEmpty) {
    final grid = CustomGrid.fromLegacyGrid(legacy);
    if (grid.cells.isNotEmpty) return grid;
  }

  throw XModelImportException(
      'No pixel data found (empty CustomModel / CustomModelCompressed).');
}
