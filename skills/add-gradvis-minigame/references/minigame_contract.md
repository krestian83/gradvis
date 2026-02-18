# Gradvis Minigame Contract

Use this file as the stable map before adding or editing a minigame.

## Stable Interface Files

- `lib/features/game/domain/game_interface.dart`
- `lib/features/game/domain/game_registry.dart`
- `lib/features/game/bootstrap/game_manifest.dart`
- `lib/features/game/bootstrap/game_factories.dart`
- `lib/features/game/bootstrap/register_builtin_games.dart`
- `lib/features/game/presentation/game_screen.dart`
- `lib/features/game/math_help/application/math_help_scope.dart`
- `lib/features/game/math_help/domain/math_help_context.dart`
- `lib/features/game/math_help/domain/math_topic_family.dart`
- `lib/features/game/math_help/visualizers/register_builtin_math_visualizers.dart`
- `lib/core/constants/curriculum_data.dart`
- `lib/core/constants/subject.dart`

## Minimal Read Sets

- New minigame in an existing curriculum slot:
Read `lib/features/game/bootstrap/game_manifest.dart`, `lib/features/game/bootstrap/game_factories.dart`, `lib/features/game/domain/game_interface.dart`, existing comparable game files in `lib/features/game/games/...`, and matching tests in `test/features/game/games/...`.

- New minigame and new curriculum slot:
Read the previous set plus `lib/core/constants/curriculum_data.dart`.

- Iterate on an existing minigame:
Read that minigame folder in `lib/features/game/games/...`, its matching tests in `test/features/game/games/...`, and `lib/features/game/domain/game_interface.dart`.

- Math minigame creation or iteration:
Read the previous relevant set plus
`lib/features/game/math_help/application/math_help_scope.dart`,
`lib/features/game/math_help/domain/math_help_context.dart`,
`lib/features/game/math_help/domain/math_topic_family.dart`,
and `lib/features/game/math_help/visualizers/register_builtin_math_visualizers.dart`.

## Registration Anchors

The scaffold script updates only marker sections:

- In `lib/features/game/bootstrap/game_factories.dart`:
`// [MINIGAME_IMPORTS_START]` ... `// [MINIGAME_IMPORTS_END]`,
`// [MINIGAME_FACTORY_KEYS_START]` ... `// [MINIGAME_FACTORY_KEYS_END]`,
`// [MINIGAME_FACTORIES_START]` ... `// [MINIGAME_FACTORIES_END]`.

- In `lib/features/game/bootstrap/game_manifest.dart`:
`// [MINIGAME_MANIFEST_START]` ... `// [MINIGAME_MANIFEST_END]`.

Do not remove or rename these markers without updating `scripts/add_minigame.py`.

## Naming And Slot Rules

- `slug` must be snake_case.
- `factory_key` must be unique.
- `game_id` must be unique.
- Enabled entries must not share the same `(subject, trinn, level)` slot.
- Default `game_id` pattern: `<subject>_trinn<trinn>_level<level>_<slug>`.

## Math Help Integration Rules

Apply these rules whenever `subject=math`:

- Resolve the help controller from `MathHelpScope.maybeOf(context)`.
- Publish a `MathHelpContext` for the current task/question.
- Keep `operation` aligned with registered visualizer keys.
- Update help context whenever task state changes.
- Call `clearContext()` in `dispose()` and on completion cleanup.

## Verification Commands

```powershell
flutter test test/features/game/bootstrap/game_manifest_test.dart
flutter test test/features/game/games/<subject>/trinn<trinn>/<slug>
flutter analyze
flutter test
```

For math minigames, also run:

```powershell
flutter test test/features/game/math_help/
```
