import 'package:flutter/material.dart';

import '../../../../../domain/game_interface.dart';
import '../../../../../math_help/application/math_help_controller.dart';
import '../../../../../math_help/application/math_help_scope.dart';
import '../application/subtraction_quiz_trinn4_session_controller.dart';

class SubtractionQuizTrinn4Game extends StatefulWidget implements GameWidget {
  @override
  final ValueChanged<GameResult> onComplete;

  final Duration feedbackDelay;
  final SubtractionQuizTrinn4SessionController? sessionController;

  const SubtractionQuizTrinn4Game({
    super.key,
    required this.onComplete,
    this.feedbackDelay = const Duration(milliseconds: 420),
    this.sessionController,
  });

  @override
  State<SubtractionQuizTrinn4Game> createState() =>
      _SubtractionQuizTrinn4GameState();
}

class _SubtractionQuizTrinn4GameState extends State<SubtractionQuizTrinn4Game> {
  late final SubtractionQuizTrinn4SessionController _session;
  MathHelpController? _mathHelpController;
  bool _isPublishingHelpContext = false;

  bool _isHandlingAnswer = false;
  bool _hasCompleted = false;
  int? _selectedAnswer;
  bool? _selectedWasCorrect;

  @override
  void initState() {
    super.initState();
    _session =
        widget.sessionController ?? SubtractionQuizTrinn4SessionController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mathHelpController ??= MathHelpScope.maybeOf(context);
    _queueMathHelpContextPublish();
  }

  @override
  void dispose() {
    _mathHelpController?.clearContext();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = _session.currentQuestion;
    final options = _session.currentOptions;
    final progress = _session.currentRoundNumber / _session.totalRounds;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 12),
          Text('Subtraksjon - Trinn 4', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Regn med store tall og veksling. Bruk hjelp ved behov.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Card(
            color: colors.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Runde ${_session.currentRoundNumber} / '
                    '${_session.totalRounds}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(question.prompt, style: theme.textTheme.headlineMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.1,
              children: options.map((option) {
                final background = _optionBackground(colors, option);
                return FilledButton(
                  key: ValueKey('subtraction-quiz-trinn4-option-$option'),
                  style: FilledButton.styleFrom(
                    backgroundColor: background,
                    disabledBackgroundColor: background,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    textStyle: theme.textTheme.headlineSmall,
                  ),
                  onPressed: _isHandlingAnswer
                      ? null
                      : () => _onOptionPressed(option),
                  child: Text('$option'),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Riktige svar: ${_session.correctCount}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  void _publishMathHelpContext() {
    if (_hasCompleted) {
      return;
    }
    _mathHelpController?.setContext(_session.helpContext);
  }

  void _queueMathHelpContextPublish() {
    if (_isPublishingHelpContext || _hasCompleted) {
      return;
    }
    _isPublishingHelpContext = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isPublishingHelpContext = false;
      if (!mounted) {
        return;
      }
      _publishMathHelpContext();
    });
  }

  Future<void> _onOptionPressed(int option) async {
    if (_isHandlingAnswer || _hasCompleted) {
      return;
    }
    final isCorrect = _session.submitAnswer(option);

    setState(() {
      _isHandlingAnswer = true;
      _selectedAnswer = option;
      _selectedWasCorrect = isCorrect;
    });

    await Future<void>.delayed(widget.feedbackDelay);
    if (!mounted) {
      return;
    }

    final completed = _session.advanceRound();
    if (completed) {
      _completeGame();
      return;
    }

    setState(() {
      _isHandlingAnswer = false;
      _selectedAnswer = null;
      _selectedWasCorrect = null;
    });
    _publishMathHelpContext();
  }

  Color _optionBackground(ColorScheme colors, int option) {
    if (_selectedAnswer != option) {
      return colors.primary;
    }
    if (_selectedWasCorrect == true) {
      return Colors.green;
    }
    if (_selectedWasCorrect == false) {
      return Colors.red;
    }
    return colors.primary;
  }

  void _completeGame() {
    if (_hasCompleted) {
      return;
    }
    _hasCompleted = true;
    _mathHelpController?.clearContext();
    final reward = _session.reward;
    widget.onComplete(
      GameResult(stars: reward.stars, pointsEarned: reward.points),
    );
  }
}
