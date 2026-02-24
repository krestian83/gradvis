import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/game/math_help/domain/math_help_context.dart';
import 'features/game/math_help/domain/math_topic_family.dart';
import 'features/game/math_help/presentation/math_help_overlay.dart';
import 'features/game/math_help/visualizers/register_builtin_math_visualizers.dart';
import 'features/game/math_help/visualizers/visualizer_registry.dart';

void main() {
  registerBuiltInMathVisualizers();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _SandboxHome(),
  ));
}

/// Groups operations by topic family for the menu.
const _operationsByTopic = <MathTopicFamily, List<_OperationPreset>>{
  MathTopicFamily.arithmetic: [
    _OperationPreset('addition', 'Addition', [4, 3], 7),
    _OperationPreset('subtraction', 'Subtraction', [342, 145], 197),
    _OperationPreset('multiplication', 'Multiplication', [3, 4], 12),
    _OperationPreset('division', 'Division', [12, 3], 4),
  ],
  MathTopicFamily.geometry: [
    _OperationPreset('triangleSides', 'Triangle sides', [3], 3),
    _OperationPreset('squareSides', 'Square sides', [4], 4),
    _OperationPreset('rectangleSides', 'Rectangle sides', [4], 4),
    _OperationPreset('pentagonSides', 'Pentagon sides', [5], 5),
    _OperationPreset('hexagonSides', 'Hexagon sides', [6], 6),
    _OperationPreset('cubeFaces', 'Cube faces', [6], 6),
    _OperationPreset('cubeEdges', 'Cube edges', [12], 12),
    _OperationPreset('cylinderFaces', 'Cylinder faces', [3], 3),
    _OperationPreset('pyramidFaces', 'Pyramid faces', [5], 5),
    _OperationPreset('pyramidEdges', 'Pyramid edges', [8], 8),
    _OperationPreset('coneFaces', 'Cone faces', [2], 2),
  ],
  MathTopicFamily.measurement: [
    _OperationPreset('areaUnits', 'Area units', [100], 100),
    _OperationPreset('volumeUnits', 'Volume units', [1000], 1000),
    _OperationPreset('unitChoice', 'Unit choice', [1], 1),
  ],
  MathTopicFamily.algorithmicThinking: [
    _OperationPreset('stepSequence', 'Step sequence', [5, 3], 15),
    _OperationPreset('logicFlow', 'Logic flow', [1, 0], 1),
  ],
};

class _OperationPreset {
  final String operation;
  final String label;
  final List<num> defaultOperands;
  final num defaultAnswer;

  const _OperationPreset(
    this.operation,
    this.label,
    this.defaultOperands,
    this.defaultAnswer,
  );
}

String _topicLabel(MathTopicFamily topic) => switch (topic) {
  MathTopicFamily.arithmetic => 'Arithmetic',
  MathTopicFamily.geometry => 'Geometry',
  MathTopicFamily.measurement => 'Measurement',
  MathTopicFamily.algorithmicThinking => 'Algorithmic thinking',
};

class _SandboxHome extends StatefulWidget {
  const _SandboxHome();

  @override
  State<_SandboxHome> createState() => _SandboxHomeState();
}

class _SandboxHomeState extends State<_SandboxHome> {
  var _topic = MathTopicFamily.arithmetic;
  late _OperationPreset _preset = _operationsByTopic[_topic]!.first;

  final _operandControllers = <TextEditingController>[];
  final _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _applyPreset(_preset);
  }

  void _applyPreset(_OperationPreset preset) {
    _preset = preset;
    for (final c in _operandControllers) {
      c.dispose();
    }
    _operandControllers
      ..clear()
      ..addAll(
        preset.defaultOperands
            .map((v) => TextEditingController(text: v.toString())),
      );
    _answerController.text = preset.defaultAnswer.toString();
  }

  @override
  void dispose() {
    for (final c in _operandControllers) {
      c.dispose();
    }
    _answerController.dispose();
    super.dispose();
  }

  List<num> get _operands => _operandControllers
      .map((c) => num.tryParse(c.text) ?? 0)
      .toList();

  num get _answer => num.tryParse(_answerController.text) ?? 0;

  void _launch() {
    final helpContext = MathHelpContext(
      topicFamily: _topic,
      operation: _preset.operation,
      operands: _operands,
      correctAnswer: _answer,
    );
    final visualizer = mathVisualizerRegistry.create(helpContext);
    if (visualizer == null) return;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: MathHelpOverlay(
          helpContext: helpContext,
          visualizer: visualizer,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final operations = _operationsByTopic[_topic]!;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Math Help Sandbox'),
        backgroundColor: const Color(0xFF0A2463),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _label('Topic'),
              const SizedBox(height: 6),
              _dropdown<MathTopicFamily>(
                value: _topic,
                items: MathTopicFamily.values,
                labelOf: _topicLabel,
                onChanged: (t) => setState(() {
                  _topic = t;
                  _applyPreset(_operationsByTopic[t]!.first);
                }),
              ),
              const SizedBox(height: 20),
              _label('Operation'),
              const SizedBox(height: 6),
              _dropdown<_OperationPreset>(
                value: _preset,
                items: operations,
                labelOf: (p) => p.label,
                onChanged: (p) => setState(() => _applyPreset(p)),
              ),
              const SizedBox(height: 20),
              _label('Operands'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _operandControllers.length; i++)
                    SizedBox(
                      width: 100,
                      child: _numberField(
                        controller: _operandControllers[i],
                        hint: 'Op ${i + 1}',
                      ),
                    ),
                  _iconButton(Icons.add, () {
                    setState(() => _operandControllers.add(
                        TextEditingController(text: '0')));
                  }),
                  if (_operandControllers.length > 1)
                    _iconButton(Icons.remove, () {
                      setState(() => _operandControllers.removeLast()
                          .dispose());
                    }),
                ],
              ),
              const SizedBox(height: 20),
              _label('Correct answer'),
              const SizedBox(height: 6),
              SizedBox(
                width: 100,
                child: _numberField(
                  controller: _answerController,
                  hint: 'Answer',
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _launch,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Launch visualizer'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3E92CC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white70,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: const Color(0xFF162447),
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: _inputDecoration(),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(labelOf(item))),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[-\d.]')),
      ],
      decoration: _inputDecoration(hint: hint),
    );
  }

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white30),
    filled: true,
    fillColor: const Color(0xFF162447),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 12,
    ),
  );

  Widget _iconButton(IconData icon, VoidCallback onPressed) {
    return IconButton.filled(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFF162447),
        foregroundColor: Colors.white70,
      ),
    );
  }
}
