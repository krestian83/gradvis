import 'package:flutter/material.dart';

import '../../../domain/math_dash_question.dart';

/// Flutter overlay shown when the runner reaches an obstacle.
class QuestionOverlay extends StatefulWidget {
  final MathDashQuestion question;
  final int questionNumber;
  final int totalQuestions;
  final ValueChanged<int> onAnswer;

  const QuestionOverlay({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.onAnswer,
  });

  @override
  State<QuestionOverlay> createState() => _QuestionOverlayState();
}

class _QuestionOverlayState extends State<QuestionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Card(
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.95),
                    Colors.white.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sporsmal ${widget.questionNumber} av'
                    ' ${widget.totalQuestions}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.question.expression,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF00B4D8),
                      fontFamily: 'Fredoka One',
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AnswerGrid(
                    options: widget.question.options,
                    onAnswer: widget.onAnswer,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerGrid extends StatelessWidget {
  final List<int> options;
  final ValueChanged<int> onAnswer;

  const _AnswerGrid({required this.options, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        for (final option in options)
          FilledButton(
            key: Key('answer-$option'),
            onPressed: () => onAnswer(option),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00B4D8),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text('$option'),
          ),
      ],
    );
  }
}
