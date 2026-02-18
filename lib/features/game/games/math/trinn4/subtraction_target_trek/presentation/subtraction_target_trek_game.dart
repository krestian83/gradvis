import 'package:flutter/material.dart';

import '../../../../../domain/game_interface.dart';
import '../../../../../math_help/application/math_help_controller.dart';
import '../../../../../math_help/application/math_help_scope.dart';
import '../../../../../math_help/domain/math_help_context.dart';
import '../../../../../math_help/domain/math_topic_family.dart';
import '../application/subtraction_target_trek_session_controller.dart';
import '../domain/subtraction_target_trek_engine.dart';

class SubtractionTargetTrekGame extends StatefulWidget implements GameWidget {
  @override
  final ValueChanged<GameResult> onComplete;

  const SubtractionTargetTrekGame({super.key, required this.onComplete});

  @override
  State<SubtractionTargetTrekGame> createState() =>
      _SubtractionTargetTrekGameState();
}

class _SubtractionTargetTrekGameState extends State<SubtractionTargetTrekGame> {
  final SubtractionTargetTrekSessionController _session =
      SubtractionTargetTrekSessionController();
  MathHelpController? _mathHelpController;
  String _feedback = 'Treff differansen i hodet.';
  GameResult? _result;
  bool _completed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mathHelpController ??= MathHelpScope.maybeOf(context);
    _scheduleMathHelpPublish();
  }

  @override
  void dispose() {
    _mathHelpController?.clearContext();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_session.isFinished) {
      final result = _result ?? _session.buildResult();
      return _CompletedSummary(
        title: 'Runden er fullfort',
        subtitle: 'Stjerner: ${result.stars}/3  Poeng: ${result.pointsEarned}',
      );
    }

    final question = _session.currentQuestion;
    final progress = _session.currentRound / _session.totalRounds;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Subtraksjonstreff',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Store tall med laaning i hodet.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Runde',
                  value: '${_session.currentRound}/${_session.totalRounds}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: 'Treff',
                  value: '${_session.correctAnswers}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: 'Streak',
                  value: '${_session.bestStreak}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _EquationCard(expression: question.expression),
          const SizedBox(height: 12),
          _FeedbackBanner(message: _feedback),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              for (final option in question.options)
                FilledButton(
                  key: Key('answer-$option'),
                  onPressed: () => _submitAnswer(question, option),
                  child: Text('$option'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _publishMathHelpContext() {
    if (_session.isFinished || _completed) {
      return;
    }
    final question = _session.currentQuestion;
    _mathHelpController?.setContext(
      MathHelpContext(
        topicFamily: MathTopicFamily.arithmetic,
        operation: 'subtraction',
        operands: [question.minuend, question.subtrahend],
        correctAnswer: question.answer,
        label: question.expression,
      ),
    );
  }

  void _scheduleMathHelpPublish() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _publishMathHelpContext();
    });
  }

  void _submitAnswer(SubtractionTargetTrekQuestion question, int answer) {
    if (_session.isFinished || _completed) {
      return;
    }
    final isCorrect = _session.submitAnswer(answer);
    setState(() {
      _feedback = isCorrect
          ? 'Riktig! Hold fokus.'
          : 'Nesten. ${question.expression} = ${question.answer}.';
    });

    if (_session.isFinished) {
      _completeGame();
      return;
    }
    _publishMathHelpContext();
  }

  void _completeGame() {
    if (_completed) {
      return;
    }
    _completed = true;
    _result = _session.buildResult();
    _mathHelpController?.clearContext();
    widget.onComplete(_result!);
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 2),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _EquationCard extends StatelessWidget {
  final String expression;

  const _EquationCard({required this.expression});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            Text(
              'Hva blir differansen?',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(expression, style: Theme.of(context).textTheme.displaySmall),
          ],
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final String message;

  const _FeedbackBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _CompletedSummary extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CompletedSummary({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
