import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/bootstrap/game_factories.dart';
import 'package:gradvis_v2/features/game/bootstrap/game_manifest.dart';

void main() {
  group('builtInGameManifest', () {
    test('has unique game ids', () {
      final ids = builtInGameManifest.map((entry) => entry.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('has unique enabled slots', () {
      final enabled = builtInGameManifest
          .where((entry) => entry.enabled)
          .toList();
      final slots = enabled.map((entry) => entry.slot).toList();
      expect(slots.toSet().length, slots.length);
    });

    test('resolves factory keys for all enabled entries', () {
      for (final entry in builtInGameManifest.where((entry) => entry.enabled)) {
        expect(lookupBuiltInGameFactory(entry.factoryKey), isNotNull);
      }
    });
  });
}
