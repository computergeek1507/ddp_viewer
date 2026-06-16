import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'models/color_order.dart';
import 'models/display_layout.dart';
import 'services/ddp_receiver.dart';
import 'services/xmodel_importer.dart';
import 'widgets/pixel_canvas.dart';

void main() {
  runApp(const DdpViewerApp());
}

class DdpViewerApp extends StatelessWidget {
  const DdpViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DDP Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF18181D),
      ),
      home: const ViewerScreen(),
    );
  }
}

enum LayoutMode { matrix, xmodel }

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  final DdpReceiver _receiver = DdpReceiver();

  LayoutMode _mode = LayoutMode.matrix;
  int _width = 32;
  int _height = 16;
  int _channelOffset = 0;
  ColorOrder _colorOrder = ColorOrder.rgb;

  DisplayLayout _layout = DisplayLayout.matrix(32, 16);
  String? _modelName;

  // Built-in test pattern: when on, an internal animated rainbow drives the
  // canvas instead of incoming DDP — useful to confirm the layout renders
  // without any sender on the network.
  bool _testPattern = false;
  final ValueNotifier<Uint8List> _testFrame = ValueNotifier(Uint8List(0));
  Timer? _testTimer;
  double _testPhase = 0;

  final _widthCtrl = TextEditingController(text: '32');
  final _heightCtrl = TextEditingController(text: '16');
  final _offsetCtrl = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _receiver.start();
  }

  @override
  void dispose() {
    _receiver.dispose();
    _testTimer?.cancel();
    _testFrame.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _offsetCtrl.dispose();
    super.dispose();
  }

  void _setTestPattern(bool on) {
    setState(() => _testPattern = on);
    _testTimer?.cancel();
    if (!on) return;
    _testTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      final count = _layout.pixelCount;
      final buf = Uint8List(count * 3);
      for (var i = 0; i < count; i++) {
        final hue = (i / (count == 0 ? 1 : count) + _testPhase) % 1.0;
        final rgb = _hsv(hue);
        buf[i * 3] = rgb[0];
        buf[i * 3 + 1] = rgb[1];
        buf[i * 3 + 2] = rgb[2];
      }
      _testPhase = (_testPhase + 0.01) % 1.0;
      _testFrame.value = buf;
    });
  }

  /// HSV (full saturation/value) to RGB bytes for the test pattern.
  static List<int> _hsv(double h) {
    final i = (h * 6).floor();
    final f = h * 6 - i;
    final q = (255 * (1 - f)).round();
    final t = (255 * f).round();
    switch (i % 6) {
      case 0:
        return [255, t, 0];
      case 1:
        return [q, 255, 0];
      case 2:
        return [0, 255, t];
      case 3:
        return [0, q, 255];
      case 4:
        return [t, 0, 255];
      default:
        return [255, 0, q];
    }
  }

  void _rebuildMatrix() {
    setState(() {
      _layout = DisplayLayout.matrix(_width, _height);
      _mode = LayoutMode.matrix;
    });
  }

  Future<void> _loadXModel() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Open an xLights .xmodel file',
      type: FileType.custom,
      allowedExtensions: const ['xmodel'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    try {
      final xml = await File(path).readAsString();
      final grid = importXModel(xml);
      final name = path.split(Platform.pathSeparator).last;
      setState(() {
        _layout = DisplayLayout.fromGrid(grid, name: name);
        _modelName = name;
        _mode = LayoutMode.xmodel;
      });
    } on XModelImportException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('Could not read file: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildControlBar(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _testPattern ? _testFrame : _receiver.frame,
              builder: (context, frame, _) {
                return PixelCanvas(
                  layout: _layout,
                  frame: frame,
                  channelOffset: _testPattern ? 0 : _channelOffset,
                  colorOrder: _testPattern ? ColorOrder.rgb : _colorOrder,
                );
              },
            ),
          ),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Material(
      color: const Color(0xFF22222A),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Mode toggle.
            SegmentedButton<LayoutMode>(
              segments: const [
                ButtonSegment(value: LayoutMode.matrix, label: Text('Matrix')),
                ButtonSegment(value: LayoutMode.xmodel, label: Text('xModel')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) {
                final mode = s.first;
                if (mode == LayoutMode.matrix) {
                  _rebuildMatrix();
                } else {
                  _loadXModel();
                }
              },
            ),
            if (_mode == LayoutMode.matrix) ...[
              _numberField('Width', _widthCtrl, (v) {
                _width = v.clamp(1, 4096);
                _rebuildMatrix();
              }),
              _numberField('Height', _heightCtrl, (v) {
                _height = v.clamp(1, 4096);
                _rebuildMatrix();
              }),
            ] else
              TextButton.icon(
                onPressed: _loadXModel,
                icon: const Icon(Icons.folder_open, size: 18),
                label: Text(_modelName ?? 'Load .xmodel…'),
              ),
            const SizedBox(width: 1, height: 28, child: VerticalDivider()),
            _numberField('Offset', _offsetCtrl, (v) {
              setState(() => _channelOffset = v.clamp(0, 1 << 24));
            }),
            _colorOrderDropdown(),
            const SizedBox(width: 1, height: 28, child: VerticalDivider()),
            // Built-in test pattern toggle.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gradient, size: 18, color: Colors.white54),
                const SizedBox(width: 4),
                const Text('Test pattern'),
                Switch(value: _testPattern, onChanged: _setTestPattern),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(
      String label, TextEditingController ctrl, ValueChanged<int> onChanged) {
    return SizedBox(
      width: 96,
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (s) {
          final v = int.tryParse(s.trim());
          if (v != null) onChanged(v);
        },
        onChanged: (s) {
          final v = int.tryParse(s.trim());
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  Widget _colorOrderDropdown() {
    return DropdownButton<ColorOrder>(
      value: _colorOrder,
      onChanged: (v) {
        if (v != null) setState(() => _colorOrder = v);
      },
      items: [
        for (final o in ColorOrder.values)
          DropdownMenuItem(value: o, child: Text(o.label)),
      ],
    );
  }

  Widget _buildStatusBar() {
    return Material(
      color: const Color(0xFF22222A),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ValueListenableBuilder(
          valueListenable: _receiver.error,
          builder: (context, error, _) {
            if (error != null) {
              return Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(error,
                        style: const TextStyle(color: Colors.redAccent))),
              ]);
            }
            return ValueListenableBuilder(
              valueListenable: _receiver.stats,
              builder: (context, stats, _) {
                final dot = stats.receiving ? Colors.greenAccent : Colors.grey;
                return DefaultTextStyle(
                  style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                      fontSize: 13,
                      color: Colors.white70),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: dot),
                      const SizedBox(width: 6),
                      Text(stats.receiving
                          ? 'Receiving on :${_receiver.port}'
                          : 'Listening on :${_receiver.port} — no data'),
                      const SizedBox(width: 16),
                      ValueListenableBuilder(
                        valueListenable: _receiver.localAddresses,
                        builder: (context, addrs, _) {
                          final ips = addrs.isEmpty ? '—' : addrs.join(', ');
                          return Row(children: [
                            const Icon(Icons.computer,
                                size: 14, color: Colors.white38),
                            const SizedBox(width: 4),
                            SelectableText('This PC: $ips',
                                style: const TextStyle(color: Colors.white70)),
                          ]);
                        },
                      ),
                      const Spacer(),
                      _stat('FPS', stats.fps.toStringAsFixed(0)),
                      _stat('Pkts/s', stats.packetsPerSecond.toStringAsFixed(0)),
                      _stat('Seq', '${stats.lastSequence}'),
                      _stat('Px', '${stats.pixelCount}'),
                      _stat('Src', stats.sourceIp.isEmpty ? '—' : stats.sourceIp),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: Text.rich(TextSpan(children: [
        TextSpan(
            text: '$label ', style: const TextStyle(color: Colors.white38)),
        TextSpan(
            text: value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ])),
    );
  }
}
