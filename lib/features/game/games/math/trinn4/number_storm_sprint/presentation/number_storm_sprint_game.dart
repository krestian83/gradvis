import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../../domain/game_interface.dart';
import '../../../../../math_help/application/math_help_controller.dart';
import '../../../../../math_help/application/math_help_scope.dart';
import '../../../../../math_help/domain/math_help_context.dart';
import '../../../../../math_help/domain/math_topic_family.dart';
import '../application/number_storm_sprint_session_controller.dart';
import '../domain/number_storm_sprint_engine.dart';

@immutable
class NumberStormSprintConfig {
  final double baseSpeed;
  final double spawnMinSeconds;
  final double spawnMaxSeconds;
  final double obstacleStartOffset;
  final Duration decelerationDuration;
  final Duration throwDuration;
  final Duration confettiDuration;
  final Duration collisionDuration;
  final Duration accelerationDuration;

  const NumberStormSprintConfig({
    this.baseSpeed = 190,
    this.spawnMinSeconds = 6,
    this.spawnMaxSeconds = 9,
    this.obstacleStartOffset = 90,
    this.decelerationDuration = const Duration(milliseconds: 550),
    this.throwDuration = const Duration(milliseconds: 400),
    this.confettiDuration = const Duration(milliseconds: 600),
    this.collisionDuration = const Duration(milliseconds: 450),
    this.accelerationDuration = const Duration(milliseconds: 400),
  }) : assert(spawnMinSeconds >= 0),
       assert(spawnMaxSeconds >= spawnMinSeconds),
       assert(baseSpeed > 0);
}

class NumberStormSprintGame extends StatefulWidget implements GameWidget {
  @override
  final ValueChanged<GameResult> onComplete;
  final NumberStormSprintSessionController? sessionController;
  final NumberStormSprintConfig config;
  final Random? random;

  const NumberStormSprintGame({
    super.key,
    required this.onComplete,
    this.sessionController,
    this.config = const NumberStormSprintConfig(),
    this.random,
  });

  @override
  State<NumberStormSprintGame> createState() => _NumberStormSprintGameState();
}

enum _RunnerState {
  running,
  decelerating,
  quiz,
  throwNumber,
  confetti,
  collision,
  accelerating,
  completed,
}

class _NumberStormSprintGameState extends State<NumberStormSprintGame>
    with SingleTickerProviderStateMixin {
  static const _runnerSize = Size(82, 88);
  static const _obstacleSize = Size(74, 84);
  static const _runnerLeft = 64.0;
  static const _trackBottom = 56.0;

  late final NumberStormSprintSessionController _session;
  late final Random _random;
  late final Ticker _ticker;
  MathHelpController? _mathHelpController;
  Duration? _lastElapsed;

  Size _viewportSize = Size.zero;
  _RunnerState _runnerState = _RunnerState.running;
  double _worldDistance = 0;
  double _activeSpeed = 0;
  double _stateElapsed = 0;
  double _timeUntilSpawn = 0;
  double _decelerationStartSpeed = 0;
  double _accelerationTargetSpeed = 0;
  double? _obstacleX;
  int? _projectileValue;
  double _projectileProgress = 0;
  GameResult? _result;
  bool _hasEmittedComplete = false;

  double get _obstacleCenterX => (_obstacleX ?? 0) + (_obstacleSize.width / 2);

  @override
  void initState() {
    super.initState();
    _session = widget.sessionController ?? NumberStormSprintSessionController();
    _random = widget.random ?? Random();
    _activeSpeed = widget.config.baseSpeed * _session.speedMultiplier;
    _accelerationTargetSpeed = _activeSpeed;
    _timeUntilSpawn = _nextSpawnDelaySeconds();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _mathHelpController?.clearContext();
    _ticker.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mathHelpController ??= MathHelpScope.maybeOf(context);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = constraints.biggest;
        final question = _session.isComplete ? null : _session.currentQuestion;

        return Stack(
          children: [
            Positioned.fill(child: _buildScene()),
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: _HudCard(
                questionText:
                    'Sporsmal ${_displayQuestionNumber()}/${_session.totalQuestions}',
                livesText: 'Liv ${_session.livesRemaining}/3',
                speedText:
                    'Tempo ${_session.speedMultiplier.toStringAsFixed(2)}x',
              ),
            ),
            if (_runnerState == _RunnerState.quiz && question != null)
              Positioned.fill(
                child: _QuestionOverlay(
                  question: question,
                  onAnswer: _submitAnswer,
                ),
              ),
            if (_runnerState == _RunnerState.completed && _result != null)
              Positioned.fill(
                child: _EndOverlay(
                  title: _session.isVictory ? 'Seier!' : 'Game over',
                  subtitle: _session.isVictory
                      ? 'Du fullforte 20 hinder.'
                      : 'Du mistet alle liv.',
                  correctAnswers: _session.correctAnswers,
                  wrongAnswers: _session.wrongAnswers,
                  stars: _result!.stars,
                  pointsEarned: _result!.pointsEarned,
                  onContinue: _emitCompletion,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildScene() {
    final projectilePosition = _projectilePosition();
    final confettiProgress = _confettiProgress();
    final collisionProgress = _collisionProgress();

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _RunnerBackgroundPainter(
              worldDistance: _worldDistance,
              viewportHeight: _viewportSize.height,
            ),
          ),
        ),
        Positioned(
          left: _runnerLeft,
          bottom: _trackBottom + _runnerBounce(),
          child: _buildRunnerVisual(collisionProgress),
        ),
        if (_obstacleX != null)
          Positioned(
            left: _obstacleX!,
            bottom: _trackBottom,
            child: _buildObstacleVisual(confettiProgress),
          ),
        if (projectilePosition != null && _projectileValue != null)
          Positioned(
            left: projectilePosition.dx - 18,
            top: projectilePosition.dy - 18,
            child: _ProjectileBubble(value: _projectileValue!),
          ),
        if (_runnerState == _RunnerState.confetti && _obstacleX != null)
          Positioned(
            left: _obstacleX! - 20,
            bottom: _trackBottom + 10,
            child: _ConfettiBurst(progress: confettiProgress),
          ),
      ],
    );
  }

  Widget _buildRunnerVisual(double collisionProgress) {
    return _RunnerSprite(
      size: _runnerSize,
      collisionProgress: collisionProgress,
      isRunning:
          _runnerState == _RunnerState.running ||
          _runnerState == _RunnerState.accelerating,
    );
  }

  Widget _buildObstacleVisual(double confettiProgress) {
    return Opacity(
      opacity: _runnerState == _RunnerState.confetti ? 1 - confettiProgress : 1,
      child: _ObstacleSprite(size: _obstacleSize),
    );
  }

  void _onTick(Duration elapsed) {
    if (!mounted) {
      return;
    }
    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    if (previous == null) {
      return;
    }
    final dt =
        (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    if (dt <= 0) {
      return;
    }
    if (_viewportSize.width <= 0 || _viewportSize.height <= 0) {
      return;
    }
    setState(() {
      _advance(dt.clamp(0, 0.05).toDouble());
    });
  }

  void _advance(double dt) {
    switch (_runnerState) {
      case _RunnerState.running:
        _advanceRunning(dt);
        break;
      case _RunnerState.decelerating:
        _advanceDecelerating(dt);
        break;
      case _RunnerState.throwNumber:
        _advanceThrow(dt);
        break;
      case _RunnerState.confetti:
        _advanceConfetti(dt);
        break;
      case _RunnerState.collision:
        _advanceCollision(dt);
        break;
      case _RunnerState.accelerating:
        _advanceAccelerating(dt);
        break;
      case _RunnerState.quiz:
      case _RunnerState.completed:
        return;
    }
  }

  void _advanceRunning(double dt) {
    _activeSpeed = widget.config.baseSpeed * _session.speedMultiplier;
    _moveWorld(_activeSpeed * dt);
    if (_obstacleX == null) {
      _timeUntilSpawn -= dt;
      if (_timeUntilSpawn <= 0) {
        _spawnObstacle();
      }
      return;
    }

    final triggerX = _pauseTriggerX();
    if (_obstacleCenterX <= triggerX) {
      _runnerState = _RunnerState.decelerating;
      _stateElapsed = 0;
      _decelerationStartSpeed = _activeSpeed;
    }
  }

  void _advanceDecelerating(double dt) {
    _stateElapsed += dt;
    final duration = _seconds(widget.config.decelerationDuration);
    final progress = (_stateElapsed / duration).clamp(0.0, 1.0).toDouble();
    final curve = Curves.easeOutCubic.transform(progress);
    _activeSpeed = _decelerationStartSpeed * (1 - curve);
    _moveWorld(_activeSpeed * dt);
    if (progress < 1) {
      return;
    }

    _activeSpeed = 0;
    if (_obstacleX != null) {
      _obstacleX = (_viewportSize.width * 0.5) - (_obstacleSize.width * 0.5);
    }
    _runnerState = _RunnerState.quiz;
    _stateElapsed = 0;
    _publishMathHelpContext();
  }

  void _advanceThrow(double dt) {
    _stateElapsed += dt;
    final duration = _seconds(widget.config.throwDuration);
    _projectileProgress = (_stateElapsed / duration).clamp(0.0, 1.0).toDouble();
    if (_projectileProgress < 1) {
      return;
    }
    _runnerState = _RunnerState.confetti;
    _stateElapsed = 0;
  }

  void _advanceConfetti(double dt) {
    _stateElapsed += dt;
    if (_stateElapsed < _seconds(widget.config.confettiDuration)) {
      return;
    }
    _finishEncounter();
  }

  void _advanceCollision(double dt) {
    _stateElapsed += dt;
    if (_stateElapsed < _seconds(widget.config.collisionDuration)) {
      return;
    }
    _finishEncounter();
  }

  void _advanceAccelerating(double dt) {
    _stateElapsed += dt;
    final duration = _seconds(widget.config.accelerationDuration);
    final progress = (_stateElapsed / duration).clamp(0.0, 1.0).toDouble();
    final curve = Curves.easeOutCubic.transform(progress);
    _activeSpeed = _accelerationTargetSpeed * curve;
    _moveWorld(_activeSpeed * dt);
    if (progress < 1) {
      return;
    }
    _activeSpeed = _accelerationTargetSpeed;
    _runnerState = _RunnerState.running;
    _stateElapsed = 0;
  }

  void _finishEncounter() {
    _obstacleX = null;
    _projectileValue = null;
    _projectileProgress = 0;
    _stateElapsed = 0;

    if (_session.isComplete) {
      _enterCompletedState();
      return;
    }

    _runnerState = _RunnerState.accelerating;
    _accelerationTargetSpeed =
        widget.config.baseSpeed * _session.speedMultiplier;
    _timeUntilSpawn = _nextSpawnDelaySeconds();
  }

  void _moveWorld(double delta) {
    if (delta <= 0) {
      return;
    }
    _worldDistance += delta;
    if (_obstacleX != null) {
      _obstacleX = _obstacleX! - delta;
    }
  }

  void _spawnObstacle() {
    if (_obstacleX != null || _session.isComplete) {
      return;
    }
    _obstacleX = _viewportSize.width + widget.config.obstacleStartOffset;
  }

  void _submitAnswer(int selectedAnswer) {
    if (_runnerState != _RunnerState.quiz || _session.isComplete) {
      return;
    }
    final question = _session.currentQuestion;
    final outcome = _session.submitAnswer(selectedAnswer);
    _mathHelpController?.clearContext();
    _stateElapsed = 0;

    if (outcome.isCorrect) {
      _runnerState = _RunnerState.throwNumber;
      _projectileValue = question.answer;
      _projectileProgress = 0;
      return;
    }

    _runnerState = _RunnerState.collision;
  }

  void _enterCompletedState() {
    _runnerState = _RunnerState.completed;
    _result = _session.buildResult();
    _mathHelpController?.clearContext();
    _ticker.stop();
  }

  void _publishMathHelpContext() {
    if (_session.isComplete) {
      return;
    }
    final question = _session.currentQuestion;
    _mathHelpController?.setContext(
      MathHelpContext(
        topicFamily: MathTopicFamily.arithmetic,
        operation: question.mathHelpOperation,
        operands: [question.leftOperand, question.rightOperand],
        correctAnswer: question.answer,
        label: question.expression,
      ),
    );
  }

  void _emitCompletion() {
    if (_hasEmittedComplete || _result == null) {
      return;
    }
    _hasEmittedComplete = true;
    widget.onComplete(_result!);
  }

  int _displayQuestionNumber() {
    if (_session.isComplete) {
      return _session.totalQuestions;
    }
    return (_session.answeredCount + 1)
        .clamp(1, _session.totalQuestions)
        .toInt();
  }

  double _nextSpawnDelaySeconds() {
    if (widget.config.spawnMinSeconds == widget.config.spawnMaxSeconds) {
      return widget.config.spawnMinSeconds;
    }
    return widget.config.spawnMinSeconds +
        (_random.nextDouble() *
            (widget.config.spawnMaxSeconds - widget.config.spawnMinSeconds));
  }

  double _pauseTriggerX() {
    final duration = _seconds(widget.config.decelerationDuration);
    final stopDistance = _activeSpeed * duration * 0.5;
    return (_viewportSize.width * 0.5) + stopDistance;
  }

  double _seconds(Duration duration) {
    final value = duration.inMicroseconds / Duration.microsecondsPerSecond;
    if (value <= 0) {
      return 0.001;
    }
    return value;
  }

  double _collisionProgress() {
    if (_runnerState != _RunnerState.collision) {
      return 0;
    }
    final duration = _seconds(widget.config.collisionDuration);
    return (_stateElapsed / duration).clamp(0.0, 1.0).toDouble();
  }

  double _confettiProgress() {
    if (_runnerState != _RunnerState.confetti) {
      return 0;
    }
    final duration = _seconds(widget.config.confettiDuration);
    return (_stateElapsed / duration).clamp(0.0, 1.0).toDouble();
  }

  double _runnerBounce() {
    if (_runnerState == _RunnerState.collision) {
      final time = _stateElapsed * 40;
      return sin(time) * 4;
    }
    if (_runnerState == _RunnerState.running ||
        _runnerState == _RunnerState.accelerating) {
      return sin(_worldDistance / 24) * 3;
    }
    return 0;
  }

  Offset? _projectilePosition() {
    if (_projectileValue == null || _obstacleX == null) {
      return null;
    }
    final t = Curves.easeInOut.transform(
      _projectileProgress.clamp(0.0, 1.0).toDouble(),
    );
    final startX = _runnerLeft + (_runnerSize.width * 0.82);
    final endX = _obstacleX! + (_obstacleSize.width * 0.5);
    final startY =
        _viewportSize.height - (_trackBottom + (_runnerSize.height * 0.7));
    final endY =
        _viewportSize.height - (_trackBottom + (_obstacleSize.height * 0.66));
    final x = startX + ((endX - startX) * t);
    final y = startY + ((endY - startY) * t) - (sin(pi * t) * 76);
    return Offset(x, y);
  }
}

class _HudCard extends StatelessWidget {
  final String questionText;
  final String livesText;
  final String speedText;

  const _HudCard({
    required this.questionText,
    required this.livesText,
    required this.speedText,
  });

  @override
  Widget build(BuildContext context) {
    final hearts = livesText == 'Liv 3/3'
        ? '❤ ❤ ❤'
        : livesText == 'Liv 2/3'
        ? '❤ ❤ ♡'
        : livesText == 'Liv 1/3'
        ? '❤ ♡ ♡'
        : '♡ ♡ ♡';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                questionText,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: Colors.white),
              ),
            ),
            Text(
              livesText,
              key: const Key('lives-text'),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              hearts,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFFFF7676),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              speedText,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionOverlay extends StatelessWidget {
  final NumberStormSprintQuestion question;
  final ValueChanged<int> onAnswer;

  const _QuestionOverlay({required this.question, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Løs hinderet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.expression,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final option in question.options)
                        SizedBox(
                          width: 170,
                          child: FilledButton(
                            key: Key('answer-$option'),
                            onPressed: () => onAnswer(option),
                            child: Text('$option'),
                          ),
                        ),
                    ],
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

class _EndOverlay extends StatelessWidget {
  final String title;
  final String subtitle;
  final int correctAnswers;
  final int wrongAnswers;
  final int stars;
  final int pointsEarned;
  final VoidCallback onContinue;

  const _EndOverlay({
    required this.title,
    required this.subtitle,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.stars,
    required this.pointsEarned,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Riktig: $correctAnswers  Feil: $wrongAnswers',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Stjerner: $stars/3  Poeng: $pointsEarned',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  key: const Key('continue-button'),
                  onPressed: onContinue,
                  child: const Text('Fortsett'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RunnerSprite extends StatelessWidget {
  final Size size;
  final bool isRunning;
  final double collisionProgress;

  const _RunnerSprite({
    required this.size,
    required this.isRunning,
    required this.collisionProgress,
  });

  @override
  Widget build(BuildContext context) {
    final pulse =
        1.0 + (isRunning ? (sin(collisionProgress * pi) * 0.02) : 0.0);
    final color = collisionProgress > 0.01
        ? Color.lerp(
            const Color(0xFFFF7A66),
            const Color(0xFFFFCB5A),
            collisionProgress,
          )
        : const Color(0xFFFFCB5A);

    return Transform.scale(
      scale: pulse,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color ?? const Color(0xFFFFCB5A), const Color(0xFFFF9451)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x50000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text('🏃', style: TextStyle(fontSize: 40)),
      ),
    );
  }
}

class _ObstacleSprite extends StatelessWidget {
  final Size size;

  const _ObstacleSprite({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A445B), Color(0xFF1F2737)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF96A4C4), width: 2),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.block, color: Color(0xFFE1E7F8), size: 34),
    );
  }
}

class _ProjectileBubble extends StatelessWidget {
  final int value;

  const _ProjectileBubble({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFE4FA62),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xAA000000), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        '$value',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF172039),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ConfettiBurst extends StatelessWidget {
  final double progress;

  const _ConfettiBurst({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: CustomPaint(painter: _ConfettiPainter(progress: progress)),
    );
  }
}

class _RunnerBackgroundPainter extends CustomPainter {
  final double worldDistance;
  final double viewportHeight;

  const _RunnerBackgroundPainter({
    required this.worldDistance,
    required this.viewportHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF87CEEB), Color(0xFFE6F8FF)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    _drawLayer(
      canvas,
      size,
      speedFactor: 0.25,
      y: size.height * 0.33,
      color: const Color(0x8065A981),
      width: 86,
      height: 50,
      spacing: 124,
      radius: 28,
    );
    _drawLayer(
      canvas,
      size,
      speedFactor: 0.5,
      y: size.height * 0.50,
      color: const Color(0x995E95B7),
      width: 72,
      height: 42,
      spacing: 104,
      radius: 18,
    );
    _drawLayer(
      canvas,
      size,
      speedFactor: 0.8,
      y: size.height * 0.66,
      color: const Color(0xB04A7E5F),
      width: 58,
      height: 34,
      spacing: 86,
      radius: 10,
    );

    final groundTop = viewportHeight - 40;
    final groundPaint = Paint()..color = const Color(0xFF425B3E);
    canvas.drawRect(
      Rect.fromLTWH(0, groundTop, size.width, size.height - groundTop),
      groundPaint,
    );

    final linePaint = Paint()..color = const Color(0x99CDE8C5);
    final shift = (worldDistance * 0.8) % 36;
    for (var x = -36.0 - shift; x < size.width + 36; x += 36) {
      canvas.drawRect(Rect.fromLTWH(x, groundTop + 8, 18, 3), linePaint);
    }
  }

  void _drawLayer(
    Canvas canvas,
    Size size, {
    required double speedFactor,
    required double y,
    required Color color,
    required double width,
    required double height,
    required double spacing,
    required double radius,
  }) {
    final paint = Paint()..color = color;
    final shift = (worldDistance * speedFactor) % spacing;
    for (var x = -spacing - shift; x < size.width + spacing; x += spacing) {
      final rect = Rect.fromLTWH(x, y, width, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RunnerBackgroundPainter oldDelegate) {
    return oldDelegate.worldDistance != worldDistance ||
        oldDelegate.viewportHeight != viewportHeight;
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;

  const _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const colors = <Color>[
      Color(0xFFFFC857),
      Color(0xFFFF6B6B),
      Color(0xFF50C9CE),
      Color(0xFFA6E22E),
      Color(0xFF8E7CFF),
    ];
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final spread =
        44 * Curves.easeOut.transform(progress.clamp(0.0, 1.0).toDouble());

    for (var i = 0; i < 20; i += 1) {
      final angle = (i / 20) * pi * 2;
      final radius = spread + ((i % 4) * 4);
      final offset = Offset(
        center.dx + (cos(angle) * radius),
        center.dy + (sin(angle) * radius),
      );
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 1 - progress);
      canvas.drawCircle(offset, 3.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
