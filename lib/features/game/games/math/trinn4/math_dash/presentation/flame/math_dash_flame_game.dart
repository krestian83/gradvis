import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';

import '../../domain/environment_theme.dart';
import 'components/ground_component.dart';
import 'components/hud_component.dart';
import 'components/obstacle_component.dart';
import 'components/parallax_background.dart';
import 'components/runner_character.dart';
import 'components/thrown_number.dart';
import 'effects/confetti_effect.dart';
import 'effects/heart_shatter_effect.dart';
import 'effects/obstacle_burst_effect.dart';
import 'effects/popup_text_effect.dart';
import 'effects/screen_flash_effect.dart';
import 'effects/screen_shake_effect.dart';

/// Game states for the Math Dash runner.
enum MathDashState {
  starting,
  running,
  approaching,
  paused,
  throwing,
  colliding,
  victory,
  gameOver,
}

/// Flame game orchestrator for Math Dash.
class MathDashFlameGame extends FlameGame {
  MathDashFlameGame({
    required this.onObstacleReached,
    required this.onGameOver,
    required this.onVictory,
    this.onFootstep,
    this.onCollision,
  });

  final void Function(int questionIndex) onObstacleReached;
  final VoidCallback onGameOver;
  final VoidCallback onVictory;
  final VoidCallback? onFootstep;
  final VoidCallback? onCollision;

  static const _gameWidth = 400.0;
  static const _gameHeight = 300.0;
  static const _runnerX = 80.0;
  static const _groundY = _gameHeight - 50;

  /// Seconds of clear running before the obstacle appears.
  static const _runInterval = 3.5;

  /// X where the obstacle pauses and the question triggers.
  static const _obstacleStopX = 300.0;

  late RunnerCharacter _runner;
  late ParallaxBackground _parallax;
  late GroundComponent _ground;
  late HudComponent _hud;
  ObstacleComponent? _obstacle;

  MathDashState _state = MathDashState.starting;
  double _runSpeed = 0;
  double _targetSpeed = 120;
  double _stateTimer = 0;
  double _obstacleX = 0;
  int _questionIndex = 0;
  int _themeIndex = 0;

  int _pendingLives = 3;

  @override
  Future<void> onLoad() async {
    final gameSize = Vector2(_gameWidth, _gameHeight);
    camera.viewfinder.visibleGameSize = gameSize;
    camera.viewfinder.anchor = Anchor.topLeft;

    _parallax = ParallaxBackground(gameSize: gameSize);
    _ground = GroundComponent(gameSize: gameSize);
    _runner = RunnerCharacter(onFootstep: onFootstep)
      ..position = Vector2(_runnerX, _groundY);
    _hud = HudComponent(gameSize: gameSize);

    world.addAll([_parallax, _ground, _runner, _hud]);

    _state = MathDashState.starting;
    _stateTimer = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    switch (_state) {
      case MathDashState.starting:
        _stateTimer += dt;
        _runSpeed = Curves.easeOut.transform(
          (_stateTimer / 1.0).clamp(0, 1),
        ) * _targetSpeed;
        _scroll(dt);
        if (_stateTimer >= 1.0) {
          _runSpeed = _targetSpeed;
          _state = MathDashState.running;
          _stateTimer = 0;
        }

      case MathDashState.running:
        // Clear running — no obstacle on screen.
        _runSpeed = _targetSpeed;
        _scroll(dt);
        _stateTimer += dt;
        if (_stateTimer >= _runInterval) {
          _spawnObstacle();
          _state = MathDashState.approaching;
        }

      case MathDashState.approaching:
        // Obstacle scrolling in from the right.
        _runSpeed = _targetSpeed;
        _scroll(dt);
        _obstacleX -= _runSpeed * dt;
        _obstacle?.position.x = _obstacleX;
        if (_obstacleX <= _obstacleStopX) {
          _obstacleX = _obstacleStopX;
          _obstacle?.position.x = _obstacleX;
          _state = MathDashState.paused;
          pauseEngine();
          onObstacleReached(_questionIndex);
        }

      case MathDashState.paused:
        break;

      case MathDashState.throwing:
        // Correct answer — background keeps scrolling while number
        // flies to obstacle. Landing handled by ThrownNumber callback.
        _runSpeed = _targetSpeed;
        _scroll(dt);
        _stateTimer += dt;
        if (_stateTimer >= 2.0) _finishThrow();

      case MathDashState.colliding:
        // Wrong answer — obstacle charges into the runner.
        _runSpeed = _targetSpeed;
        _scroll(dt);
        _stateTimer += dt;
        if (_obstacle != null) {
          _obstacleX -= 350 * dt;
          _obstacle!.position.x = _obstacleX;
          if (_obstacleX <= _runnerX) {
            _onObstacleHitRunner();
          }
        } else if (_stateTimer >= 1.0) {
          _resumeAfterHit();
        }

      case MathDashState.victory:
      case MathDashState.gameOver:
        break;
    }
  }

  void _scroll(double dt) {
    final dx = _runSpeed * dt;
    _parallax.scroll(dx);
    _ground.scroll(dx);
    _runner.runSpeed = _runSpeed;
  }

  void _spawnObstacle() {
    _obstacle?.removeFromParent();
    final theme = EnvironmentTheme.values[_themeIndex.clamp(0, 3)];
    _obstacleX = _gameWidth + 60;
    _obstacle = ObstacleComponent(
      theme: theme,
      variant: _questionIndex,
      position: Vector2(_obstacleX, _groundY),
    );
    world.add(_obstacle!);
  }

  /// Called by the bridge widget after the player answers.
  void handleAnswerResult({
    required bool isCorrect,
    required double newSpeed,
    required int lives,
    required int streak,
    required int themeIndex,
    required int questionIndex,
    required String answerText,
  }) {
    _questionIndex = questionIndex;
    _targetSpeed = newSpeed;
    _pendingLives = lives;
    _hud
      ..lives = lives
      ..questionIndex = _questionIndex
      ..streak = streak;

    if (themeIndex != _themeIndex) {
      _themeIndex = themeIndex;
      final newTheme = EnvironmentTheme.values[_themeIndex.clamp(0, 3)];
      _parallax.theme = newTheme;
      _ground.theme = newTheme;
    }

    _stateTimer = 0;

    // Runner always throws the player's chosen number.
    _runner.playThrow();

    final obstacleCenter = _obstacle != null
        ? Vector2(_obstacle!.position.x, _groundY - 25)
        : Vector2(_obstacleStopX, _groundY - 25);

    if (isCorrect) {
      _state = MathDashState.throwing;
      world.add(ThrownNumber(
        text: answerText,
        start: _runner.position + Vector2(20, -40),
        target: obstacleCenter,
        isCorrect: true,
        onHit: _finishThrow,
      ));
    } else {
      _state = MathDashState.colliding;
      world.add(ThrownNumber(
        text: answerText,
        start: _runner.position + Vector2(20, -40),
        target: obstacleCenter,
        isCorrect: false,
        onHit: () {},
      ));
    }
  }

  /// Called when the thrown number reaches the obstacle (correct answer).
  void _finishThrow() {
    if (_state != MathDashState.throwing) return;

    final gameSize = Vector2(_gameWidth, _gameHeight);
    final pos = _obstacle?.position ?? Vector2(_obstacleStopX, _groundY);

    world.add(ObstacleBurstEffect(center: pos + Vector2(0, -20)));
    world.add(ScreenFlashEffect.correct(gameSize: gameSize));
    world.add(PopupTextEffect(
      text: '+1',
      startPosition: _runner.position + Vector2(0, -50),
    ));

    _removeObstacle();
    _advanceOrEnd();
  }

  /// Called when the obstacle reaches the runner (wrong answer).
  void _onObstacleHitRunner() {
    final gameSize = Vector2(_gameWidth, _gameHeight);
    final pos = _obstacle?.position ?? Vector2(_runnerX, _groundY);

    world.add(ObstacleBurstEffect(
      center: pos + Vector2(0, -20),
      isCorrect: false,
    ));
    world.add(ScreenFlashEffect.wrong(gameSize: gameSize));
    world.add(ScreenShakeEffect(camera: camera, intensity: 5));
    final heartX = 16.0 + _pendingLives * 28.0;
    world.add(HeartShatterEffect(heartPosition: Vector2(heartX, 16)));

    _runner.playHit();
    onCollision?.call();
    _removeObstacle();

    // Short delay before resuming so the hit registers visually.
    _stateTimer = 0.6;
  }

  void _resumeAfterHit() {
    _advanceOrEnd();
  }

  void _removeObstacle() {
    _obstacle?.removeFromParent();
    _obstacle = null;
  }

  void _advanceOrEnd() {
    final gameSize = Vector2(_gameWidth, _gameHeight);

    if (_pendingLives <= 0) {
      _state = MathDashState.gameOver;
      _runner.playDefeat();
      onGameOver();
      return;
    }

    if (_questionIndex >= 20) {
      _state = MathDashState.victory;
      _runner.playCelebration();
      world.add(ConfettiEffect(gameSize: gameSize));
      onVictory();
      return;
    }

    _state = MathDashState.running;
    _stateTimer = 0;
    _runner.state = RunnerState.running;
  }
}
