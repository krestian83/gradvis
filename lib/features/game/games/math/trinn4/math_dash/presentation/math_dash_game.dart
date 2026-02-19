import 'dart:math' as math;

import 'package:flame/game.dart' as flame;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:audioplayers/audioplayers.dart';

import '../../../../../domain/game_interface.dart';
import '../../../../../math_help/application/math_help_controller.dart';
import '../../../../../math_help/application/math_help_scope.dart';
import '../../../../../math_help/domain/math_help_context.dart';
import '../../../../../math_help/domain/math_topic_family.dart';
import '../application/math_dash_session_controller.dart';
import 'flame/math_dash_flame_game.dart';
import 'flame/overlays/game_over_overlay.dart';
import 'flame/overlays/question_overlay.dart';
import 'flame/overlays/victory_overlay.dart';

/// Bridge widget that wraps the Flame game and implements [GameWidget].
class MathDashGame extends StatefulWidget implements GameWidget {
  @override
  final ValueChanged<GameResult> onComplete;

  const MathDashGame({super.key, required this.onComplete});

  @override
  State<MathDashGame> createState() => _MathDashGameState();
}

class _MathDashGameState extends State<MathDashGame> {
  late final MathDashSessionController _session;
  late final MathDashFlameGame _flameGame;
  MathHelpController? _mathHelpController;
  bool _completed = false;
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _footstepPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();
  bool _sfxAvailable = true;
  bool _musicStarted = false;

  @override
  void initState() {
    super.initState();
    _session = MathDashSessionController();
    _flameGame = MathDashFlameGame(
      onObstacleReached: _onObstacleReached,
      onGameOver: _onGameOver,
      onVictory: _onVictory,
      onFootstep: _onFootstep,
      onCollision: _onCollision,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mathHelpController ??= MathHelpScope.maybeOf(context);
    _scheduleMathHelpPublish();
    if (!_musicStarted) {
      _musicStarted = true;
      _startMusic();
    }
  }

  @override
  void dispose() {
    final controller = _mathHelpController;
    if (controller != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.clearContext();
      });
    }
    _musicPlayer.stop();
    _sfxPlayer.dispose();
    _footstepPlayer.dispose();
    _musicPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return flame.GameWidget<MathDashFlameGame>(
      game: _flameGame,
      overlayBuilderMap: {
        'question': (context, game) => QuestionOverlay(
          question: _session.currentQuestion,
          questionNumber: _session.currentRound,
          totalQuestions: _session.totalRounds,
          onAnswer: _onAnswerSelected,
        ),
        'gameOver': (context, game) => GameOverOverlay(
          correctAnswers: _session.correctAnswers,
          totalQuestions: _session.totalRounds,
          bestStreak: _session.bestStreak,
          onDone: _completeGame,
        ),
        'victory': (context, game) {
          final result = _session.buildResult();
          return VictoryOverlay(
            stars: result.stars,
            correctAnswers: _session.correctAnswers,
            totalQuestions: _session.totalRounds,
            bestStreak: _session.bestStreak,
            points: result.pointsEarned,
            onDone: _completeGame,
          );
        },
      },
    );
  }

  void _onObstacleReached(int questionIndex) {
    _publishMathHelpContext();
    _flameGame.overlays.add('question');
  }

  void _onAnswerSelected(int answer) {
    if (_session.isFinished) return;

    final isCorrect = _session.submitAnswer(answer);

    _playSfx(isCorrect ? 'audio/sfx/success.mp3' : 'audio/sfx/wrong.mp3');

    _flameGame.overlays.remove('question');
    _flameGame.resumeEngine();

    _flameGame.handleAnswerResult(
      isCorrect: isCorrect,
      newSpeed: _session.speed,
      lives: _session.lives,
      streak: _session.currentStreak,
      themeIndex: _session.environmentThemeIndex,
      questionIndex: _session.questionIndex,
      answerText: '$answer',
    );

    _updateMusicRate();

    if (!_session.isFinished) {
      _publishMathHelpContext();
    }
  }

  void _onGameOver() {
    _musicPlayer.stop();
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _flameGame.overlays.add('gameOver');
      _completeGame();
    });
  }

  void _onVictory() {
    _musicPlayer.stop();
    _playSfx('audio/sfx/victory.mp3');
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _flameGame.overlays.add('victory');
    });
  }

  void _onFootstep() {
    _playSfx('audio/sfx/footstep.wav', player: _footstepPlayer);
  }

  void _onCollision() {
    _playSfx('audio/sfx/collision.mp3');
  }

  Future<void> _startMusic() async {
    if (!_sfxAvailable) return;
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.18);
      await _musicPlayer.play(
        AssetSource('audio/music/math_dash_loop.wav'),
      );
      await _musicPlayer.setPlaybackRate(0.5);
    } on MissingPluginException {
      _sfxAvailable = false;
    } on PlatformException {
      // Audio not supported on this platform.
    }
  }

  void _updateMusicRate() {
    // Scale playback rate logarithmically with game speed.
    // Starts at 0.5×, ramps toward 2.0× as speed increases.
    final ratio = _session.speed / 120.0;
    final rate = (0.5 + math.log(ratio) / math.ln2 * 0.25).clamp(0.5, 2.0);
    _musicPlayer.setPlaybackRate(rate);
  }

  void _publishMathHelpContext() {
    if (_session.isFinished || _completed) return;
    final question = _session.currentQuestion;
    _mathHelpController?.setContext(
      MathHelpContext(
        topicFamily: MathTopicFamily.arithmetic,
        operation: question.operationKey,
        operands: [question.left, question.right],
        correctAnswer: question.answer,
        label: question.expression,
      ),
    );
  }

  void _scheduleMathHelpPublish() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _publishMathHelpContext();
    });
  }

  void _completeGame() {
    if (_completed) return;
    _completed = true;
    _mathHelpController?.clearContext();
    widget.onComplete(_session.buildResult());
  }

  Future<void> _playSfx(
    String asset, {
    AudioPlayer? player,
  }) async {
    if (!_sfxAvailable) return;
    try {
      await (player ?? _sfxPlayer).play(AssetSource(asset));
    } on MissingPluginException {
      _sfxAvailable = false;
    } on PlatformException {
      _sfxAvailable = false;
    }
  }
}
