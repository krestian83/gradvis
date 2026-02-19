import 'dart:math';

import 'package:flame/components.dart';

/// Camera jitter effect on wrong answers.
class ScreenShakeEffect extends Component {
  ScreenShakeEffect({
    required this.camera,
    this.intensity = 4.0,
    this.duration = 0.35,
  });

  final CameraComponent camera;
  final double intensity;
  final double duration;

  double _elapsed = 0;
  final _random = Random();

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      camera.viewfinder.position = Vector2.zero();
      removeFromParent();
      return;
    }
    final progress = 1.0 - (_elapsed / duration);
    final dx = (_random.nextDouble() - 0.5) * 2 * intensity * progress;
    final dy = (_random.nextDouble() - 0.5) * 2 * intensity * progress;
    camera.viewfinder.position = Vector2(dx, dy);
  }
}
