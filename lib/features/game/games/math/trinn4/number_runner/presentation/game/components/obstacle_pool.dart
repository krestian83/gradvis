import 'obstacle_component.dart';

/// Pre-creates obstacles to avoid runtime allocation.
class ObstaclePool {
  final List<ObstacleComponent> _pool;

  ObstaclePool({int size = 5})
      : _pool = List.generate(size, (_) => ObstacleComponent());

  List<ObstacleComponent> get all => _pool;

  /// Returns an inactive obstacle, or `null` if all are busy.
  ObstacleComponent? acquire() {
    for (final ob in _pool) {
      if (!ob.active) {
        ob.active = true;
        return ob;
      }
    }
    return null;
  }

  void release(ObstacleComponent obstacle) {
    obstacle.active = false;
  }

  void releaseAll() {
    for (final ob in _pool) {
      ob.active = false;
    }
  }
}
