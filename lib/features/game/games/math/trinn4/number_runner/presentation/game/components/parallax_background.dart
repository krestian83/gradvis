import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/painting.dart';

/// Image-based parallax with six layers at different scroll speeds.
class ParallaxBackground extends PositionComponent {
  static const _layerDefs = [
    _LayerDef('number_runner/layers/1_sky.png', 0.0),
    _LayerDef('number_runner/layers/2_clouds.png', 0.05),
    _LayerDef('number_runner/layers/3_clouds.png', 0.1),
    _LayerDef('number_runner/layers/4_rocks.png', 0.3),
    _LayerDef('number_runner/layers/5_clouds.png', 0.5),
    _LayerDef('number_runner/layers/6_rocks.png', 0.8),
  ];

  final List<_LoadedLayer> _layers = [];
  double _scroll = 0;

  @override
  Future<void> onLoad() async {
    for (final def in _layerDefs) {
      final image = await Flame.images.load(def.path);
      _layers.add(_LoadedLayer(image, def.speedFactor));
    }
  }

  @override
  void render(Canvas canvas) {
    if (_layers.isEmpty) return;

    final w = size.x;
    final h = size.y;

    for (final layer in _layers) {
      final img = layer.image;
      final scale = h / img.height;
      final scaledW = img.width * scale;
      final src = Rect.fromLTWH(
        0,
        0,
        img.width.toDouble(),
        img.height.toDouble(),
      );

      final offset = (_scroll * layer.speedFactor) % scaledW;

      for (var x = -offset; x < w; x += scaledW) {
        canvas.drawImageRect(
          img,
          src,
          Rect.fromLTWH(x, 0, scaledW, h),
          Paint(),
        );
      }
    }
  }

  void scroll(double dx) => _scroll += dx;
}

class _LayerDef {
  final String path;
  final double speedFactor;

  const _LayerDef(this.path, this.speedFactor);
}

class _LoadedLayer {
  final ui.Image image;
  final double speedFactor;

  const _LoadedLayer(this.image, this.speedFactor);
}
