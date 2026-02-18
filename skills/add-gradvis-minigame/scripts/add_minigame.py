#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

SUBJECTS = ("reading", "math", "english", "science")

FACTORIES_RELATIVE_PATH = Path("lib/features/game/bootstrap/game_factories.dart")
MANIFEST_RELATIVE_PATH = Path("lib/features/game/bootstrap/game_manifest.dart")

FACTORIES_IMPORTS_START = "// [MINIGAME_IMPORTS_START]"
FACTORIES_IMPORTS_END = "// [MINIGAME_IMPORTS_END]"
FACTORIES_KEYS_START = "// [MINIGAME_FACTORY_KEYS_START]"
FACTORIES_KEYS_END = "// [MINIGAME_FACTORY_KEYS_END]"
FACTORIES_MAP_START = "// [MINIGAME_FACTORIES_START]"
FACTORIES_MAP_END = "// [MINIGAME_FACTORIES_END]"

MANIFEST_ENTRIES_START = "// [MINIGAME_MANIFEST_START]"
MANIFEST_ENTRIES_END = "// [MINIGAME_MANIFEST_END]"


@dataclass(frozen=True)
class ManifestEntry:
    game_id: str
    subject: str
    trinn: int
    level: int
    factory_key: str
    enabled: bool


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Scaffold and register a new minigame in gradvis_v2.",
    )
    parser.add_argument("--project-root", type=Path, default=None)
    parser.add_argument("--subject", required=True, choices=SUBJECTS)
    parser.add_argument("--trinn", required=True, type=int)
    parser.add_argument("--level", required=True, type=int)
    parser.add_argument("--slug", required=True)
    parser.add_argument("--class-name", default=None)
    parser.add_argument("--factory-key", default=None)
    parser.add_argument("--game-id", default=None)
    parser.add_argument("--disabled", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--force", action="store_true")
    return parser.parse_args()


def snake_to_pascal(value: str) -> str:
    return "".join(part.capitalize() for part in value.split("_") if part)


def snake_to_camel(value: str) -> str:
    pascal = snake_to_pascal(value)
    if not pascal:
        return ""
    return pascal[0].lower() + pascal[1:]


def detect_package_name(project_root: Path) -> str:
    pubspec_path = project_root / "pubspec.yaml"
    if not pubspec_path.exists():
        return "gradvis_v2"
    content = pubspec_path.read_text(encoding="utf-8")
    match = re.search(r"^name:\s*([a-zA-Z0-9_]+)\s*$", content, flags=re.MULTILINE)
    return match.group(1) if match else "gradvis_v2"


def marker_index(lines: list[str], marker: str, file_path: Path) -> int:
    for index, line in enumerate(lines):
        if line.strip() == marker:
            return index
    raise ValueError(f'Marker "{marker}" not found in {file_path}')


def insert_line_between_markers(
    lines: list[str],
    start_marker: str,
    end_marker: str,
    line_to_insert: str,
    file_path: Path,
) -> bool:
    start = marker_index(lines, start_marker, file_path)
    end = marker_index(lines, end_marker, file_path)
    if start >= end:
        raise ValueError(
            f"Invalid marker order in {file_path}: {start_marker} must be before {end_marker}",
        )
    block = lines[start + 1 : end]
    if line_to_insert in block:
        return False
    lines.insert(end, line_to_insert)
    return True


def insert_block_between_markers(
    lines: list[str],
    start_marker: str,
    end_marker: str,
    block_to_insert: list[str],
    identity_line: str,
    file_path: Path,
) -> bool:
    start = marker_index(lines, start_marker, file_path)
    end = marker_index(lines, end_marker, file_path)
    if start >= end:
        raise ValueError(
            f"Invalid marker order in {file_path}: {start_marker} must be before {end_marker}",
        )
    block = lines[start + 1 : end]
    if any(line.strip() == identity_line.strip() for line in block):
        return False
    lines[end:end] = block_to_insert
    return True


def parse_manifest_entries(lines: list[str]) -> list[ManifestEntry]:
    entries: list[ManifestEntry] = []
    current: dict[str, object] | None = None

    for raw_line in lines:
        line = raw_line.strip()
        if "GameManifestEntry(" in line:
            current = {}
            continue
        if current is None:
            continue

        id_match = re.search(r"id:\s*'([^']+)'", line)
        if id_match:
            current["game_id"] = id_match.group(1)

        slot_match = re.search(
            r"Subject\.(\w+),\s*trinn:\s*(\d+),\s*level:\s*(\d+)",
            line,
        )
        if slot_match:
            current["subject"] = slot_match.group(1)
            current["trinn"] = int(slot_match.group(2))
            current["level"] = int(slot_match.group(3))

        factory_match = re.search(r"factoryKey:\s*'([^']+)'", line)
        if factory_match:
            current["factory_key"] = factory_match.group(1)

        enabled_match = re.search(r"enabled:\s*(true|false)", line)
        if enabled_match:
            current["enabled"] = enabled_match.group(1) == "true"

        if line == "),":
            required = {"game_id", "subject", "trinn", "level", "factory_key"}
            if required.issubset(current.keys()):
                entries.append(
                    ManifestEntry(
                        game_id=str(current["game_id"]),
                        subject=str(current["subject"]),
                        trinn=int(current["trinn"]),
                        level=int(current["level"]),
                        factory_key=str(current["factory_key"]),
                        enabled=bool(current.get("enabled", True)),
                    ),
                )
            current = None

    return entries


def parse_factory_constants(lines: list[str]) -> tuple[dict[str, str], dict[str, str]]:
    by_name: dict[str, str] = {}
    by_value: dict[str, str] = {}
    pattern = re.compile(r"^\s*const\s+([A-Za-z0-9_]+)\s*=\s*'([^']+)';\s*$")
    for line in lines:
        match = pattern.match(line)
        if not match:
            continue
        name = match.group(1)
        value = match.group(2)
        by_name[name] = value
        by_value[value] = name
    return by_name, by_value


def update_factories(
    content: str,
    factories_path: Path,
    subject: str,
    trinn: int,
    slug: str,
    class_name: str,
    factory_key: str,
) -> str:
    lines = content.splitlines()
    by_name, by_value = parse_factory_constants(lines)

    existing_const_name = by_value.get(factory_key)
    if existing_const_name is None:
        generated_name = f"{snake_to_camel(factory_key)}FactoryKey"
        if not generated_name or generated_name[0].isdigit():
            raise ValueError(f'Cannot generate factory const name from "{factory_key}"')
        current_value = by_name.get(generated_name)
        if current_value is not None and current_value != factory_key:
            raise ValueError(
                f'Factory const "{generated_name}" already exists with key "{current_value}"',
            )
        const_name = generated_name
        const_line_to_insert = f"const {const_name} = '{factory_key}';"
    else:
        const_name = existing_const_name
        const_line_to_insert = None

    import_line = (
        f"import '../games/{subject}/trinn{trinn}/{slug}/presentation/{slug}_game.dart';"
    )
    insert_line_between_markers(
        lines,
        FACTORIES_IMPORTS_START,
        FACTORIES_IMPORTS_END,
        import_line,
        factories_path,
    )

    if const_line_to_insert is not None:
        insert_line_between_markers(
            lines,
            FACTORIES_KEYS_START,
            FACTORIES_KEYS_END,
            const_line_to_insert,
            factories_path,
        )

    start = marker_index(lines, FACTORIES_MAP_START, factories_path)
    end = marker_index(lines, FACTORIES_MAP_END, factories_path)
    if start >= end:
        raise ValueError(
            f"Invalid marker order in {factories_path}: "
            f"{FACTORIES_MAP_START} must be before {FACTORIES_MAP_END}",
        )
    existing_index = None
    for index in range(start + 1, end):
        if lines[index].strip().startswith(f"{const_name}:"):
            existing_index = index
            break
    if existing_index is not None:
        next_line = lines[existing_index + 1].strip() if existing_index + 1 < len(lines) else ""
        if class_name not in next_line:
            raise ValueError(
                f'Factory map entry for "{const_name}" exists but does not target "{class_name}"',
            )
    else:
        map_entry = [
            f"  {const_name}: ({{required onComplete}}) =>",
            f"      {class_name}(onComplete: onComplete),",
        ]
        insert_block_between_markers(
            lines,
            FACTORIES_MAP_START,
            FACTORIES_MAP_END,
            map_entry,
            identity_line=f"{const_name}:",
            file_path=factories_path,
        )

    return "\n".join(lines) + "\n"


def update_manifest(
    content: str,
    manifest_path: Path,
    subject: str,
    trinn: int,
    level: int,
    game_id: str,
    factory_key: str,
    enabled: bool,
) -> str:
    lines = content.splitlines()
    entries = parse_manifest_entries(lines)

    existing_by_id = next((entry for entry in entries if entry.game_id == game_id), None)
    if existing_by_id is not None:
        same = (
            existing_by_id.subject == subject
            and existing_by_id.trinn == trinn
            and existing_by_id.level == level
            and existing_by_id.factory_key == factory_key
            and existing_by_id.enabled == enabled
        )
        if not same:
            raise ValueError(f'Existing manifest id "{game_id}" conflicts with requested values')
        return "\n".join(lines) + "\n"

    if enabled:
        for entry in entries:
            if entry.enabled and (
                entry.subject == subject
                and entry.trinn == trinn
                and entry.level == level
            ):
                raise ValueError(
                    "Enabled slot already registered for "
                    f"{subject}/trinn{trinn}/level{level} by id {entry.game_id}",
                )

    manifest_entry = [
        "  GameManifestEntry(",
        f"    id: '{game_id}',",
        f"    slot: GameSlot(subject: Subject.{subject}, trinn: {trinn}, level: {level}),",
        f"    factoryKey: '{factory_key}',",
        f"    enabled: {'true' if enabled else 'false'},",
        "  ),",
    ]
    insert_block_between_markers(
        lines,
        MANIFEST_ENTRIES_START,
        MANIFEST_ENTRIES_END,
        manifest_entry,
        identity_line=f"id: '{game_id}',",
        file_path=manifest_path,
    )
    return "\n".join(lines) + "\n"


def build_presentation_template(class_name: str, subject: str) -> str:
    if subject != "math":
        return f"""import 'package:flutter/material.dart';

import '../../../../../domain/game_interface.dart';

class {class_name} extends StatelessWidget implements GameWidget {{
  @override
  final ValueChanged<GameResult> onComplete;

  const {class_name}({{super.key, required this.onComplete}});

  @override
  Widget build(BuildContext context) {{
    return Center(
      child: FilledButton(
        onPressed: () => onComplete(const GameResult(stars: 1, pointsEarned: 5)),
        child: const Text('TODO: Implement {class_name}'),
      ),
    );
  }}
}}
"""

    return f"""import 'package:flutter/material.dart';

import '../../../../../domain/game_interface.dart';
import '../../../../../math_help/application/math_help_controller.dart';
import '../../../../../math_help/application/math_help_scope.dart';
import '../../../../../math_help/domain/math_help_context.dart';
import '../../../../../math_help/domain/math_topic_family.dart';

class {class_name} extends StatefulWidget implements GameWidget {{
  @override
  final ValueChanged<GameResult> onComplete;

  const {class_name}({{super.key, required this.onComplete}});

  @override
  State<{class_name}> createState() => _{class_name}State();
}}

class _{class_name}State extends State<{class_name}> {{
  MathHelpController? _mathHelpController;
  bool _helpContextPublished = false;

  @override
  void didChangeDependencies() {{
    super.didChangeDependencies();
    _mathHelpController ??= MathHelpScope.maybeOf(context);
    if (_helpContextPublished) return;
    _helpContextPublished = true;
    _publishMathHelpContext();
  }}

  @override
  void dispose() {{
    _mathHelpController?.clearContext();
    super.dispose();
  }}

  @override
  Widget build(BuildContext context) {{
    return Center(
      child: FilledButton(
        onPressed: _completeGame,
        child: const Text('TODO: Implement {class_name}'),
      ),
    );
  }}

  void _publishMathHelpContext() {{
    _mathHelpController?.setContext(
      MathHelpContext(
        topicFamily: MathTopicFamily.arithmetic,
        operation: 'addition',
        operands: const [1, 2],
        correctAnswer: 3,
        label: 'TODO: Sett hjelpetekst for oppgaven',
      ),
    );
  }}

  void _completeGame() {{
    _mathHelpController?.clearContext();
    widget.onComplete(const GameResult(stars: 1, pointsEarned: 5));
  }}
}}
"""


def build_domain_template(engine_class_name: str) -> str:
    return f"""class {engine_class_name} {{
  const {engine_class_name}();
}}
"""


def build_application_template(controller_class_name: str) -> str:
    return f"""class {controller_class_name} {{
  const {controller_class_name}();
}}
"""


def build_test_template(
    package_name: str,
    subject: str,
    trinn: int,
    slug: str,
    class_name: str,
) -> str:
    if subject == "math":
        return f"""import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{package_name}/features/game/domain/game_interface.dart';
import 'package:{package_name}/features/game/games/{subject}/trinn{trinn}/{slug}/presentation/{slug}_game.dart';
import 'package:{package_name}/features/game/math_help/application/math_help_controller.dart';
import 'package:{package_name}/features/game/math_help/application/math_help_scope.dart';

void main() {{
  testWidgets('{class_name} emits completion result and clears math help', (tester) async {{
    final helpController = MathHelpController();
    GameResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: MathHelpScope(
          controller: helpController,
          child: Scaffold(
            body: {class_name}(onComplete: (value) => result = value),
          ),
        ),
      ),
    );

    expect(helpController.context, isNotNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(result, isNotNull);
    expect(result!.stars, 1);
    expect(result!.pointsEarned, 5);
    expect(helpController.context, isNull);
  }});
}}
"""

    return f"""import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{package_name}/features/game/domain/game_interface.dart';
import 'package:{package_name}/features/game/games/{subject}/trinn{trinn}/{slug}/presentation/{slug}_game.dart';

void main() {{
  testWidgets('{class_name} emits completion result', (tester) async {{
    GameResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: {class_name}(onComplete: (value) => result = value),
        ),
      ),
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(result, isNotNull);
    expect(result!.stars, 1);
    expect(result!.pointsEarned, 5);
  }});
}}
"""


def relative_to_root(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def queue_existing_file_update(
    writes: dict[Path, str],
    path: Path,
    new_content: str,
) -> None:
    old_content = path.read_text(encoding="utf-8")
    if old_content != new_content:
        writes[path] = new_content


def queue_new_file(
    writes: dict[Path, str],
    path: Path,
    content: str,
    force: bool,
) -> None:
    if path.exists():
        old_content = path.read_text(encoding="utf-8")
        if old_content == content:
            return
        if not force:
            raise ValueError(f"File exists, use --force to overwrite: {path}")
    writes[path] = content


def validate_slug(slug: str) -> None:
    if not re.fullmatch(r"[a-z][a-z0-9_]*", slug):
        raise ValueError(f'Invalid slug "{slug}". Use snake_case and start with a letter.')


def resolve_project_root(arg: Path | None) -> Path:
    if arg is not None:
        return arg.resolve()
    return Path(__file__).resolve().parents[3]


def main() -> int:
    args = parse_args()

    try:
        if args.trinn < 1:
            raise ValueError("--trinn must be >= 1")
        if args.level < 0:
            raise ValueError("--level must be >= 0")
        validate_slug(args.slug)

        project_root = resolve_project_root(args.project_root)
        factories_path = project_root / FACTORIES_RELATIVE_PATH
        manifest_path = project_root / MANIFEST_RELATIVE_PATH
        if not factories_path.exists():
            raise ValueError(f"Missing file: {factories_path}")
        if not manifest_path.exists():
            raise ValueError(f"Missing file: {manifest_path}")

        subject = args.subject
        trinn = args.trinn
        level = args.level
        slug = args.slug
        class_name = args.class_name or f"{snake_to_pascal(slug)}Game"
        factory_key = args.factory_key or slug
        game_id = args.game_id or f"{subject}_trinn{trinn}_level{level}_{slug}"
        enabled = not args.disabled

        factory_key_pattern = r"[a-z][a-z0-9_]*"
        if not re.fullmatch(factory_key_pattern, factory_key):
            raise ValueError(
                f'Invalid factory key "{factory_key}". Use snake_case and start with a letter.',
            )
        if not re.fullmatch(r"[a-z0-9_]+", game_id):
            raise ValueError(
                f'Invalid game id "{game_id}". Use lowercase letters, digits, and underscores.',
            )
        if not re.fullmatch(r"[A-Z][A-Za-z0-9]*", class_name):
            raise ValueError(
                f'Invalid class name "{class_name}". Use PascalCase and start with uppercase.',
            )

        package_name = detect_package_name(project_root)

        factories_content = factories_path.read_text(encoding="utf-8")
        manifest_content = manifest_path.read_text(encoding="utf-8")

        updated_factories = update_factories(
            factories_content,
            factories_path,
            subject,
            trinn,
            slug,
            class_name,
            factory_key,
        )
        updated_manifest = update_manifest(
            manifest_content,
            manifest_path,
            subject,
            trinn,
            level,
            game_id,
            factory_key,
            enabled,
        )

        base_name = class_name[:-4] if class_name.endswith("Game") else class_name
        engine_class_name = f"{base_name}Engine"
        controller_class_name = f"{base_name}SessionController"

        game_root = (
            project_root / "lib" / "features" / "game" / "games" / subject / f"trinn{trinn}" / slug
        )
        presentation_path = game_root / "presentation" / f"{slug}_game.dart"
        domain_path = game_root / "domain" / f"{slug}_engine.dart"
        application_path = game_root / "application" / f"{slug}_session_controller.dart"
        test_path = (
            project_root
            / "test"
            / "features"
            / "game"
            / "games"
            / subject
            / f"trinn{trinn}"
            / slug
            / "presentation"
            / f"{slug}_game_test.dart"
        )

        writes: dict[Path, str] = {}
        queue_existing_file_update(writes, factories_path, updated_factories)
        queue_existing_file_update(writes, manifest_path, updated_manifest)
        queue_new_file(
            writes,
            presentation_path,
            build_presentation_template(class_name, subject),
            args.force,
        )
        queue_new_file(
            writes,
            domain_path,
            build_domain_template(engine_class_name),
            args.force,
        )
        queue_new_file(
            writes,
            application_path,
            build_application_template(controller_class_name),
            args.force,
        )
        queue_new_file(
            writes,
            test_path,
            build_test_template(package_name, subject, trinn, slug, class_name),
            args.force,
        )

        if not writes:
            print("No changes required.")
            return 0

        ordered_paths = sorted(writes.keys(), key=lambda path: relative_to_root(path, project_root))
        if args.dry_run:
            for path in ordered_paths:
                print(f"[dry-run] would write {relative_to_root(path, project_root)}")
            return 0

        for path in ordered_paths:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(writes[path], encoding="utf-8", newline="\n")
            print(f"updated {relative_to_root(path, project_root)}")

        return 0
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
