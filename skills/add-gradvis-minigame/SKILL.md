---
name: add-gradvis-minigame
description: Add and register new minigames in gradvis_v2 with a bounded-file workflow. Use when implementing a new minigame, wiring a minigame to a Subject/trinn/level slot, or creating the initial minigame test skeleton without scanning the full repository.
---

# Add Gradvis Minigame

Use a bounded read set and scripted updates.

## Read Order

1. Read `references/minigame_contract.md`.
2. Read only the files required by the selected task type.
3. Avoid repo-wide scans unless the contract is outdated.

## Workflow

1. Collect inputs:
`subject` (`reading|math|english|science`), `trinn` (int >= 1), `level` (int >= 0), `slug` (snake_case).
Optional: `class_name`, `factory_key`, `game_id`, `disabled`.

2. Run dry-run scaffold:

```powershell
python skills/add-gradvis-minigame/scripts/add_minigame.py --subject reading --trinn 1 --level 1 --slug syllable_match --dry-run
```

3. Apply scaffold:

```powershell
python skills/add-gradvis-minigame/scripts/add_minigame.py --subject reading --trinn 1 --level 1 --slug syllable_match
```

4. Implement game logic in generated files under:
`lib/features/game/games/<subject>/trinn<trinn>/<slug>/...` and
`test/features/game/games/<subject>/trinn<trinn>/<slug>/...`.

5. Run focused checks:

```powershell
flutter test test/features/game/bootstrap/game_manifest_test.dart
flutter test test/features/game/games/<subject>/trinn<trinn>/<slug>
```

6. Run broader checks before handoff:

```powershell
flutter analyze
flutter test
```

## Rules

- Keep edits bounded to generated files plus `lib/features/game/bootstrap/game_factories.dart` and `lib/features/game/bootstrap/game_manifest.dart`.
- Keep manifest `id` unique.
- Keep enabled manifest slots unique.
- Keep factory keys unique.
- Keep `GameWidget` contract intact and call `onComplete` once when the run is complete.

## Script Notes

- Depend on marker anchors in `game_factories.dart` and `game_manifest.dart`.
- Use `--force` only when intentionally replacing generated placeholder files.
