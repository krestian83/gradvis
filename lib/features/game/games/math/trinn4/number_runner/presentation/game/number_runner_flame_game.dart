import 'package:flame/components.dart';
import 'package:flame/game.dart';

import 'components/confetti_effect.dart';
import 'components/ground_component.dart';
import 'components/obstacle_component.dart';
import 'components/obstacle_pool.dart';
import 'components/parallax_background.dart';
import 'components/player_component.dart';
import 'components/projectile_component.dart';

/// Runner game states.
enum RunnerState {
  running,
  decelerating,
  questionPaused,
  projectileFlying,
  hit,
  resuming,
  victory,
  gameOver,
}

/// Flame-based auto-runner with obstacle spawns and question pauses.
class NumberRunnerFlameGame extends FlameGame with HasCollisionDetection {
  static const double _designWidth = 800;
  static const double _designHeight = 450;
  static const double _baseSpeed = 120;
  static const double _speedIncrement = 8;
  static const double _spawnInterval = 6.0;
  static const double _decelRate = 200;
  static const double _resumeRate = 180;
  static const double _hitPauseDuration = 0.6;

  // Callbacks for the host widget.
  final void Function()? onQuestionNeeded;
  final void Function()? onGameOver;
  final void Function()? onVictory;

  RunnerState _state = RunnerState.running;
  double _worldSpeed = _baseSpeed;
  double _spawnTimer = 0;
  double _hitTimer = 0;
  int _questionsSpawned = 0;
  int _totalQuestions = 20;

  late final PlayerComponent _player;
  late final GroundComponent _ground;
  late final ParallaxBackground _parallax;
  late final ObstaclePool _obstaclePool;
  late final ProjectileComponent _projectile;
  ObstacleComponent? _activeObstacle;

  RunnerState get state => _state;

  NumberRunnerFlameGame({
    this.onQuestionNeeded,
    this.onGameOver,
    this.onVictory,
  });

  /// Called by host to set total question count.
  set totalQuestions(int value) => _totalQuestions = value;

  @override
  Future<void> onLoad() async {
    final resolution = Vector2(_designWidth, _designHeight);
    camera = CameraComponent.withFixedResolution(
      width: resolution.x,
      height: resolution.y,
    );

    _parallax = ParallaxBackground()
      ..size = resolution
      ..position = Vector2.zero();
    camera.viewport.add(_parallax);

    final groundY = _designHeight - GroundComponent.groundHeight;

    _ground = GroundComponent()
      ..size = Vector2(_designWidth, GroundComponent.groundHeight)
      ..position = Vector2(0, groundY);
    world.add(_ground);

    _player = PlayerComponent()
      ..position = Vector2(80, groundY - 60);
    world.add(_player);

    _obstaclePool = ObstaclePool();
    for (final ob in _obstaclePool.all) {
      ob.position = Vector2(-100, -100);
      world.add(ob);
    }

    _projectile = ProjectileComponent()
      ..position = Vector2(-100, -100);
    world.add(_projectile);
  }

  @override
  void update(double dt) {
    super.update(dt);
    switch (_state) {
      case RunnerState.running:
        _updateRunning(dt);
      case RunnerState.decelerating:
        _updateDecelerating(dt);
      case RunnerState.questionPaused:
        break; // Waiting for answer.
      case RunnerState.projectileFlying:
        _updateProjectileFlying(dt);
      case RunnerState.hit:
        _updateHit(dt);
      case RunnerState.resuming:
        _updateResuming(dt);
      case RunnerState.victory:
      case RunnerState.gameOver:
        break;
    }
  }

  // --- Running ---

  void _updateRunning(double dt) {
    _scrollWorld(dt);
    _spawnTimer += dt;

    // Move active obstacle toward player.
    if (_activeObstacle != null && _activeObstacle!.active) {
      _activeObstacle!.position.x -= _worldSpeed * dt;

      // When obstacle reaches ~50% screen, begin deceleration.
      if (_activeObstacle!.position.x <= _designWidth * 0.5) {
        _state = RunnerState.decelerating;
      }
    } else if (_spawnTimer >= _spawnInterval &&
        _questionsSpawned < _totalQuestions) {
      _spawnObstacle();
      _spawnTimer = 0;
    }
  }

  void _spawnObstacle() {
    final ob = _obstaclePool.acquire();
    if (ob == null) return;
    final groundY = _designHeight - GroundComponent.groundHeight;
    ob.position = Vector2(_designWidth + 60, groundY - 50);
    _activeObstacle = ob;
    _questionsSpawned += 1;
  }

  // --- Decelerating ---

  void _updateDecelerating(double dt) {
    _worldSpeed -= _decelRate * dt;
    if (_worldSpeed <= 0) {
      _worldSpeed = 0;
      _player.bobbing = false;
      _state = RunnerState.questionPaused;
      onQuestionNeeded?.call();
    }
    _scrollWorld(dt);
    if (_activeObstacle != null && _activeObstacle!.active) {
      _activeObstacle!.position.x -= _worldSpeed * dt;
    }
  }

  // --- Projectile Flying (correct answer) ---

  void _updateProjectileFlying(double dt) {
    // ProjectileComponent updates itself via its own update().
    if (!_projectile.active) {
      // Projectile reached target — spawn confetti and resume.
      if (_activeObstacle != null) {
        world.add(ConfettiEffect(
          origin: _activeObstacle!.position + _activeObstacle!.size / 2,
        ));
        _obstaclePool.release(_activeObstacle!);
        _activeObstacle!.position = Vector2(-100, -100);
        _activeObstacle = null;
      }
      _beginResume();
    }
  }

  // --- Hit (wrong answer) ---

  void _updateHit(double dt) {
    _hitTimer += dt;
    if (_hitTimer >= _hitPauseDuration) {
      if (_activeObstacle != null) {
        _obstaclePool.release(_activeObstacle!);
        _activeObstacle!.position = Vector2(-100, -100);
        _activeObstacle = null;
      }
      _hitTimer = 0;
      _beginResume();
    }
  }

  // --- Resuming ---

  void _updateResuming(double dt) {
    final targetSpeed =
        _baseSpeed + _speedIncrement * _questionsSpawned;
    _worldSpeed += _resumeRate * dt;
    if (_worldSpeed >= targetSpeed) {
      _worldSpeed = targetSpeed;
      _player.bobbing = true;
      _state = RunnerState.running;
    }
    _scrollWorld(dt);
  }

  // --- Host-called methods ---

  void handleCorrectAnswer() {
    if (_state != RunnerState.questionPaused) return;

    _projectile.active = true;
    _projectile.position =
        _player.position + Vector2(_player.size.x, _player.size.y / 2);
    if (_activeObstacle != null) {
      _projectile.target = ObstacleTarget(
        position: _activeObstacle!.position + _activeObstacle!.size / 2,
        onHit: () => _projectile.active = false,
      );
    }
    _state = RunnerState.projectileFlying;
  }

  void handleWrongAnswer() {
    if (_state != RunnerState.questionPaused) return;
    _state = RunnerState.hit;
    _hitTimer = 0;
  }

  void triggerGameOver() {
    _state = RunnerState.gameOver;
    _worldSpeed = 0;
    _player.bobbing = false;
    overlays.add('gameOver');
    onGameOver?.call();
  }

  void triggerVictory() {
    _state = RunnerState.victory;
    _worldSpeed = 0;
    _player.bobbing = false;
    overlays.add('victory');
    onVictory?.call();
  }

  // --- Helpers ---

  void _scrollWorld(double dt) {
    final dx = _worldSpeed * dt;
    _parallax.scroll(dx);
    _ground.scroll(dx);
  }

  void _beginResume() {
    _worldSpeed = 0;
    _state = RunnerState.resuming;
    _player.bobbing = true;
  }
}
