import 'package:flame/game.dart' as flame;
import 'package:flutter/material.dart';

import '../../../../../domain/game_interface.dart';
import '../../../../../math_help/application/math_help_controller.dart';
import '../../../../../math_help/application/math_help_scope.dart';
import '../../../../../math_help/domain/math_help_context.dart';
import '../../../../../math_help/domain/math_topic_family.dart';
import '../application/number_runner_session_controller.dart';
import 'game/number_runner_flame_game.dart';
import 'overlays/game_over_overlay.dart';
import 'overlays/hud_overlay.dart';
import 'overlays/question_overlay.dart';
import 'overlays/victory_overlay.dart';

/// Host widget that bridges NumberRunnerFlameGame with Flutter overlays.
class NumberRunnerGame extends StatefulWidget implements GameWidget {
  @override
  final ValueChanged<GameResult> onComplete;

  const NumberRunnerGame({super.key, required this.onComplete});

  @override
  State<NumberRunnerGame> createState() => _NumberRunnerGameState();
}

class _NumberRunnerGameState extends State<NumberRunnerGame> {
  late final NumberRunnerSessionController _session;
  late final NumberRunnerFlameGame _flameGame;
  MathHelpController? _mathHelpController;
  bool _completed = false;
  GameResult? _result;

  @override
  void initState() {
    super.initState();
    _session = NumberRunnerSessionController();

    _flameGame = NumberRunnerFlameGame(
      onQuestionNeeded: _onQuestionNeeded,
      onGameOver: () {},
      onVictory: () {},
    )..totalQuestions = _session.totalQuestions;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mathHelpController ??= MathHelpScope.maybeOf(context);
    _publishMathHelpContext();
  }

  @override
  void dispose() {
    _mathHelpController?.clearContext();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return flame.GameWidget<NumberRunnerFlameGame>(
      game: _flameGame,
      overlayBuilderMap: {
        'hud': (context, game) => HudOverlay(session: _session),
        'question': (context, game) {
          if (_session.isFinished || _session.isGameOver) {
            return const SizedBox.shrink();
          }
          return QuestionOverlay(
            question: _session.currentQuestion,
            onAnswer: _handleAnswer,
          );
        },
        'gameOver': (context, game) => GameOverOverlay(
              session: _session,
              onClose: _completeGame,
            ),
        'victory': (context, game) {
          final result = _result ?? _session.buildResult();
          return VictoryOverlay(
            session: _session,
            result: result,
            onClose: _completeGame,
          );
        },
      },
      initialActiveOverlays: const ['hud'],
    );
  }

  void _onQuestionNeeded() {
    if (_session.isFinished || _session.isGameOver) return;

    _publishMathHelpContext();

    _flameGame.overlays.add('question');
  }

  void _handleAnswer(int answer) {
    if (_session.isFinished || _session.isGameOver) return;

    final isCorrect = _session.submitAnswer(answer);

    _flameGame.overlays.remove('question');

    if (isCorrect) {
      _flameGame.handleCorrectAnswer();
    } else {
      _flameGame.handleWrongAnswer();
    }

    // Check end conditions.
    if (_session.isGameOver) {
      _flameGame.triggerGameOver();
      _completeGame();
      return;
    }
    if (_session.isFinished) {
      _result = _session.buildResult();
      _flameGame.triggerVictory();
      _completeGame();
      return;
    }

    _publishMathHelpContext();
  }

  void _publishMathHelpContext() {
    if (_completed || _session.isFinished || _session.isGameOver) return;
    final question = _session.currentQuestion;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _completed) return;
      _mathHelpController?.setContext(
        MathHelpContext(
          topicFamily: MathTopicFamily.arithmetic,
          operation: question.operationKey,
          operands: [question.operandA, question.operandB],
          correctAnswer: question.answer,
          label: question.expression,
        ),
      );
    });
  }

  void _completeGame() {
    if (_completed) return;
    _completed = true;
    _result ??= _session.buildResult();
    _mathHelpController?.clearContext();
    widget.onComplete(_result!);
  }
}
