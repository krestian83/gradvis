import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/math_help/domain/math_help_context.dart';
import 'package:gradvis_v2/features/game/math_help/domain/math_topic_family.dart';
import 'package:gradvis_v2/features/game/math_help/presentation/math_visualizer.dart';
import 'package:gradvis_v2/features/game/math_help/visualizers/addition_visualizer.dart';
import 'package:gradvis_v2/features/game/math_help/visualizers/division_visualizer.dart';
import 'package:gradvis_v2/features/game/math_help/visualizers/multiplication_visualizer.dart';
import 'package:gradvis_v2/features/game/math_help/visualizers/subtraction_visualizer.dart';

Future<T> _loadVisualizer<T extends MathVisualizer>(T visualizer) async {
  visualizer.onGameResize(Vector2(320, 220));
  await visualizer.onLoad();
  return visualizer;
}

TextComponent _topEquationLabel(Iterable<TextComponent> labels, String text) {
  final matches = labels.where((component) => component.text == text).toList()
    ..sort((left, right) => left.position.y.compareTo(right.position.y));
  return matches.first;
}

Iterable<TextComponent> _textDescendants(Component root) sync* {
  if (root is TextComponent) {
    yield root;
  }
  for (final child in root.children) {
    yield* _textDescendants(child);
  }
}

void main() {
  test('AdditionVisualizer builds merged dot scene', () async {
    final visualizer = await _loadVisualizer(
      AdditionVisualizer(
        context: MathHelpContext(
          topicFamily: MathTopicFamily.arithmetic,
          operation: 'addition',
          operands: const [4, 3],
          correctAnswer: 7,
        ),
      ),
    );
    addTearDown(visualizer.onRemove);

    expect(visualizer.children.whereType<CircleComponent>().length, 7);
    expect(visualizer.children.whereType<RectangleComponent>(), isNotEmpty);
    final texts = visualizer.children.whereType<TextComponent>().toList();
    expect(texts.any((component) => component.text == '+'), isTrue);
    expect(texts.any((component) => component.text == '='), isTrue);
  });

  test('AdditionVisualizer normalizes negative and large operands', () async {
    final visualizer = await _loadVisualizer(
      AdditionVisualizer(
        context: MathHelpContext(
          topicFamily: MathTopicFamily.arithmetic,
          operation: 'addition',
          operands: const [25, -2],
          correctAnswer: 23,
        ),
      ),
    );
    addTearDown(visualizer.onRemove);

    expect(visualizer.children.whereType<CircleComponent>().length, 20);
    final texts = visualizer.children.whereType<TextComponent>().toList();
    expect(texts.any((component) => component.text == '20'), isTrue);
    expect(texts.any((component) => component.text == '0'), isTrue);
  });

  test(
    'AdditionVisualizer keeps operands and symbols in equation row',
    () async {
      final visualizer = await _loadVisualizer(
        AdditionVisualizer(
          context: MathHelpContext(
            topicFamily: MathTopicFamily.arithmetic,
            operation: 'addition',
            operands: const [8, 8],
            correctAnswer: 16,
          ),
        ),
      );
      addTearDown(visualizer.onRemove);

      final operandLabels = visualizer.children
          .whereType<TextComponent>()
          .where((component) => component.text == '8')
          .toList();

      expect(operandLabels.length, 2);
      final sortedOperands = operandLabels.toList()
        ..sort((left, right) => left.position.x.compareTo(right.position.x));
      final firstAddendLabel = sortedOperands.first;
      final secondAddendLabel = sortedOperands.last;
      final plusLabel = visualizer.children
          .whereType<TextComponent>()
          .firstWhere((component) => component.text == '+');
      final equalsLabel = visualizer.children
          .whereType<TextComponent>()
          .firstWhere((component) => component.text == '=');

      expect(
        (secondAddendLabel.position - firstAddendLabel.position).length,
        greaterThan(20),
      );
      expect(
        (firstAddendLabel.position.y - plusLabel.position.y).abs(),
        lessThan(0.01),
      );
      expect(
        (secondAddendLabel.position.y - plusLabel.position.y).abs(),
        lessThan(0.01),
      );
      expect(
        (equalsLabel.position.y - plusLabel.position.y).abs(),
        lessThan(0.01),
      );
      expect(
        firstAddendLabel.position.x,
        lessThan(secondAddendLabel.position.x),
      );
    },
  );

  test('SubtractionVisualizer builds subtraction dot-grid scene', () async {
    final visualizer = await _loadVisualizer(
      SubtractionVisualizer(
        context: MathHelpContext(
          topicFamily: MathTopicFamily.arithmetic,
          operation: 'subtraction',
          operands: const [9, 3],
          correctAnswer: 6,
        ),
      ),
    );
    addTearDown(visualizer.onRemove);

    expect(visualizer.children.whereType<CircleComponent>().length, 9);
    expect(visualizer.children.whereType<RectangleComponent>(), isNotEmpty);
    final texts = visualizer.children.whereType<TextComponent>().toList();
    expect(texts.any((component) => component.text == '-'), isTrue);
    expect(texts.any((component) => component.text == '='), isTrue);
  });

  test(
    'SubtractionVisualizer switches to base-10 dots for larger operands',
    () async {
      final visualizer = await _loadVisualizer(
        SubtractionVisualizer(
          context: MathHelpContext(
            topicFamily: MathTopicFamily.arithmetic,
            operation: 'subtraction',
            operands: const [14, 6],
            correctAnswer: 8,
          ),
        ),
      );
      addTearDown(visualizer.onRemove);

      expect(
        visualizer.children.whereType<CircleComponent>().length,
        greaterThan(1),
      );
    },
  );

  test(
    'SubtractionVisualizer uses 100, 10 and 1 labels in base-10 mode',
    () async {
      final visualizer = await _loadVisualizer(
        SubtractionVisualizer(
          context: MathHelpContext(
            topicFamily: MathTopicFamily.arithmetic,
            operation: 'subtraction',
            operands: const [342, 145],
            correctAnswer: 197,
          ),
        ),
      );
      addTearDown(visualizer.onRemove);

      expect(
        visualizer.children.whereType<CircleComponent>().length,
        greaterThan(1),
      );
      final texts = _textDescendants(visualizer).toList();
      expect(texts.any((component) => component.text == '100'), isTrue);
      expect(texts.any((component) => component.text == '10'), isTrue);
      expect(texts.any((component) => component.text == '1'), isTrue);
    },
  );

  test(
    'SubtractionVisualizer sizes base-10 dots with exact 2x steps',
    () async {
      final visualizer = await _loadVisualizer(
        SubtractionVisualizer(
          context: MathHelpContext(
            topicFamily: MathTopicFamily.arithmetic,
            operation: 'subtraction',
            operands: const [111, 0],
            correctAnswer: 111,
          ),
        ),
      );
      addTearDown(visualizer.onRemove);

      final radii =
          visualizer.children
              .whereType<CircleComponent>()
              .map((dot) => dot.radius)
              .toList()
            ..sort((left, right) => right.compareTo(left));

      expect(radii.length, 3);
      expect(radii[0], closeTo(radii[1] * 2, 0.0001));
      expect(radii[1], closeTo(radii[2] * 2, 0.0001));
    },
  );

  test(
    'SubtractionVisualizer keeps ones visible with looser base-10 spacing',
    () async {
      final visualizer = await _loadVisualizer(
        SubtractionVisualizer(
          context: MathHelpContext(
            topicFamily: MathTopicFamily.arithmetic,
            operation: 'subtraction',
            operands: const [363, 90],
            correctAnswer: 273,
          ),
        ),
      );
      addTearDown(visualizer.onRemove);

      final circles = visualizer.children.whereType<CircleComponent>().toList();
      final radii = circles.map((dot) => dot.radius).toSet().toList()
        ..sort((left, right) => right.compareTo(left));
      expect(radii.length, 3);

      final tensRadius = radii[1];
      final onesRadius = radii[2];
      final tensDots = circles
          .where((dot) => (dot.radius - tensRadius).abs() < 0.0001)
          .toList();

      var minCenterDistance = double.infinity;
      for (var i = 0; i < tensDots.length; i++) {
        for (var j = i + 1; j < tensDots.length; j++) {
          final distance = tensDots[i].position.distanceTo(
            tensDots[j].position,
          );
          if (distance < minCenterDistance) {
            minCenterDistance = distance;
          }
        }
      }

      expect(onesRadius, greaterThanOrEqualTo(3.0));
      expect(minCenterDistance - (tensRadius * 2), greaterThan(2.0));
    },
  );

  test('SubtractionVisualizer clamps operands for base-10 mode', () async {
    final visualizer = await _loadVisualizer(
      SubtractionVisualizer(
        context: MathHelpContext(
          topicFamily: MathTopicFamily.arithmetic,
          operation: 'subtraction',
          operands: const [700, -2],
          correctAnswer: 100,
        ),
      ),
    );
    addTearDown(visualizer.onRemove);

    expect(visualizer.children.whereType<CircleComponent>(), isNotEmpty);
    final texts = visualizer.children.whereType<TextComponent>().toList();
    expect(texts.any((component) => component.text == '500'), isTrue);
    expect(texts.any((component) => component.text == '0'), isTrue);
  });

  test(
    'SubtractionVisualizer keeps operands and symbols in equation row',
    () async {
      final visualizer = await _loadVisualizer(
        SubtractionVisualizer(
          context: MathHelpContext(
            topicFamily: MathTopicFamily.arithmetic,
            operation: 'subtraction',
            operands: const [8, 8],
            correctAnswer: 0,
          ),
        ),
      );
      addTearDown(visualizer.onRemove);

      final operandLabels = visualizer.children
          .whereType<TextComponent>()
          .where((component) => component.text == '8')
          .toList();

      expect(operandLabels.length, 2);
      final sortedOperands = operandLabels.toList()
        ..sort((left, right) => left.position.x.compareTo(right.position.x));
      final minuendLabel = sortedOperands.first;
      final subtrahendLabel = sortedOperands.last;
      final minusLabel = visualizer.children
          .whereType<TextComponent>()
          .firstWhere((component) => component.text == '-');
      final equalsLabel = visualizer.children
          .whereType<TextComponent>()
          .firstWhere((component) => component.text == '=');

      expect(
        (subtrahendLabel.position - minuendLabel.position).length,
        greaterThan(20),
      );
      expect(
        (minuendLabel.position.y - minusLabel.position.y).abs(),
        lessThan(0.01),
      );
      expect(
        (subtrahendLabel.position.y - minusLabel.position.y).abs(),
        lessThan(0.01),
      );
      expect(
        (equalsLabel.position.y - minusLabel.position.y).abs(),
        lessThan(0.01),
      );
      expect(minuendLabel.position.x, lessThan(subtrahendLabel.position.x));
    },
  );

  test(
    'SubtractionVisualizer centers minus between operand text bounds',
    () async {
      final visualizer = await _loadVisualizer(
        SubtractionVisualizer(
          context: MathHelpContext(
            topicFamily: MathTopicFamily.arithmetic,
            operation: 'subtraction',
            operands: const [363, 90],
            correctAnswer: 273,
          ),
        ),
      );
      addTearDown(visualizer.onRemove);

      final labels = visualizer.children.whereType<TextComponent>();
      final minuendLabel = _topEquationLabel(labels, '363');
      final subtrahendLabel = _topEquationLabel(labels, '90');
      final minusLabel = _topEquationLabel(labels, '-');

      final minuendRight =
          minuendLabel.position.x + (minuendLabel.size.x * 0.5);
      final subtrahendLeft =
          subtrahendLabel.position.x - (subtrahendLabel.size.x * 0.5);
      final midpoint = (minuendRight + subtrahendLeft) * 0.5;

      expect(minusLabel.position.x, greaterThan(minuendRight));
      expect(minusLabel.position.x, lessThan(subtrahendLeft));
      expect((minusLabel.position.x - midpoint).abs(), lessThan(0.6));
    },
  );

  test(
    'MultiplicationVisualizer starts with first operand and equation row',
    () async {
      final visualizer = await _loadVisualizer(
        MultiplicationVisualizer(
          context: MathHelpContext(
            topicFamily: MathTopicFamily.arithmetic,
            operation: 'multiplication',
            operands: const [3, 4],
            correctAnswer: 12,
          ),
        ),
      );
      addTearDown(visualizer.onRemove);

      expect(visualizer.children.whereType<CircleComponent>().length, 3);
      final textLabels = visualizer.children.whereType<TextComponent>();
      final firstOperandLabel = _topEquationLabel(textLabels, '3');
      final multiplicationLabel = _topEquationLabel(textLabels, 'x');
      final secondOperandLabel = _topEquationLabel(textLabels, '4');
      final equalsLabel = _topEquationLabel(textLabels, '=');
      final resultLabel = _topEquationLabel(textLabels, '12');

      expect(
        (firstOperandLabel.position.y - multiplicationLabel.position.y).abs(),
        lessThan(0.01),
      );
      expect(
        (secondOperandLabel.position.y - multiplicationLabel.position.y).abs(),
        lessThan(0.01),
      );
      expect(
        (equalsLabel.position.y - multiplicationLabel.position.y).abs(),
        lessThan(0.01),
      );
      expect(
        (resultLabel.position.y - multiplicationLabel.position.y).abs(),
        lessThan(0.01),
      );
      expect(
        firstOperandLabel.position.x,
        lessThan(multiplicationLabel.position.x),
      );
      expect(
        multiplicationLabel.position.x,
        lessThan(secondOperandLabel.position.x),
      );
      expect(secondOperandLabel.position.x, lessThan(equalsLabel.position.x));
      expect(equalsLabel.position.x, lessThan(resultLabel.position.x));
    },
  );

  test('DivisionVisualizer builds total dots and group labels', () async {
    final visualizer = await _loadVisualizer(
      DivisionVisualizer(
        context: MathHelpContext(
          topicFamily: MathTopicFamily.arithmetic,
          operation: 'division',
          operands: const [12, 3],
          correctAnswer: 4,
        ),
      ),
    );
    addTearDown(visualizer.onRemove);

    expect(visualizer.children.whereType<CircleComponent>().length, 12);
    expect(
      visualizer.children
          .whereType<TextComponent>()
          .where((component) => component.text == '4')
          .length,
      3,
    );
  });
}
