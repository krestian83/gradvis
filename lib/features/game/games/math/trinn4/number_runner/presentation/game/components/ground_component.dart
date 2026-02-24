import 'package:flame/components.dart';

/// Invisible run-plane marker used for player/obstacle baseline.
///
/// Visual ground now comes from parallax image layers.
class GroundComponent extends PositionComponent {
  static const double groundHeight = 96;

  GroundComponent();

  void scroll(double dx) {}
}
