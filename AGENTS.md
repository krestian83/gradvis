## Skills
A skill is a set of local instructions to follow that is stored in a `SKILL.md` file.

### Available skills
- add-gradvis-minigame: Scaffold and register new minigames in this repo using bounded reads, marker-based bootstrap edits, and focused test flow. (file: ./skills/add-gradvis-minigame/SKILL.md)

# Flutter & Dart Development Guidelines

## Project Context
- Flutter application with standard project structure (`lib/main.dart` entry point)
- Target platforms: desktop, web, and mobile
- User is familiar with programming concepts but may be new to Dart

## Code Style & Conventions
- Follow Effective Dart guidelines (https://dart.dev/effective-dart)
- Apply SOLID principles throughout the codebase
- Write concise, declarative Dart code; prefer functional patterns
- Favor composition over inheritance
- Prefer immutable data structures; widgets (especially `StatelessWidget`) should be immutable
- Use `PascalCase` for classes, `camelCase` for members/variables/functions/enums, `snake_case` for files
- Line length: 80 characters or fewer
- Keep functions short and single-purpose (strive for <20 lines)
- Use arrow syntax for simple one-line functions
- Avoid abbreviations; use meaningful, descriptive names
- No trailing comments
- Write code that is as short as possible while remaining clear

## Dart Specifics
- Leverage null safety fully; avoid `!` unless the value is guaranteed non-null
- Use `async`/`await` for async operations; `Future` for single, `Stream` for sequences
- Use pattern matching and exhaustive `switch` statements/expressions where appropriate
- Use records to return multiple types when a full class is cumbersome
- Use `try-catch` with appropriate/custom exceptions for error handling
- When generating code, explain Dart-specific features (null safety, futures, streams) to the user

## Flutter Best Practices
- Compose smaller widgets; avoid deep widget nesting
- Use small, private `Widget` classes instead of helper methods returning `Widget`
- Break down large `build()` methods into smaller private Widget classes
- Use `const` constructors whenever possible to reduce rebuilds
- Never perform expensive operations (network calls, complex computations) in `build()` methods
- Use `ListView.builder` / `SliverList` for long lists (lazy loading)
- Use `compute()` for expensive calculations to avoid blocking the UI thread

## State Management
- Prefer Flutter's built-in state management; no third-party packages unless explicitly requested
- Use `ValueNotifier` + `ValueListenableBuilder` for simple, single-value local state
- Use `ChangeNotifier` + `ListenableBuilder` for complex or shared state
- Use `StreamBuilder` / `FutureBuilder` for async data
- Use MVVM pattern when a more robust solution is needed
- Use manual constructor dependency injection to keep dependencies explicit
- Separate ephemeral state from app state

## Architecture
- Separate concerns: UI logic separate from business logic
- Organize into logical layers: Presentation (widgets, screens), Domain (business logic), Data (models, API clients), Core (shared utilities)
- For larger features, organize by feature with own presentation/domain/data subfolders
- Abstract data sources using Repositories/Services for testability

## Navigation & Routing
- Use `go_router` for declarative navigation, deep linking, and web support
- Use built-in `Navigator` only for short-lived screens (dialogs, temporary views)
- Configure `go_router` `redirect` for authentication flows

## Package Management
- Add dependencies: `flutter pub add <package_name>`
- Add dev dependencies: `flutter pub add dev:<package_name>`
- Remove dependencies: `dart pub remove <package_name>`
- When suggesting new packages from pub.dev, explain their benefits

## Code Quality Tools
- Run `dart format` to ensure consistent formatting
- Run `dart fix` to auto-fix common errors
- Run `dart analyze` to lint the codebase (use Bash, NOT the MCP `analyze_files` tool — it stalls)
- Use `flutter_lints` in `analysis_options.yaml`
- Use `dart:developer` `log()` for structured logging instead of `print`

## Code Generation
- Use `build_runner` for code generation tasks (e.g., `json_serializable`)
- Run: `dart run build_runner build --delete-conflicting-outputs`

## Testing
- Run tests with `flutter test`
- Follow Arrange-Act-Assert (Given-When-Then) pattern
- Write unit tests for domain logic, data layer, and state management
- Write widget tests for UI components using `package:flutter_test`
- Use `integration_test` package (from Flutter SDK) for end-to-end user flows
- Prefer `package:checks` for more expressive assertions over default matchers
- Prefer fakes/stubs over mocks; use `mockito` or `mocktail` only when necessary
- Aim for high test coverage
- Write code with testing in mind; use injectable dependencies

## Data Handling
- Use `json_serializable` + `json_annotation` for JSON serialization
- Use `fieldRename: FieldRename.snake` to convert camelCase to snake_case JSON keys

## Visual Design & Theming
- Build beautiful, intuitive UIs following modern design guidelines
- Ensure mobile responsiveness across screen sizes (mobile and web)
- Define a centralized `ThemeData` for consistent app-wide styling
- Implement light and dark theme support (`ThemeMode.light`, `.dark`, `.system`)
- Use `ColorScheme.fromSeed()` for harmonious color palettes
- Customize component themes (`appBarTheme`, `elevatedButtonTheme`, etc.) within `ThemeData`
- Use `ThemeExtension` for custom design tokens not covered by standard `ThemeData`
- Use `google_fonts` for custom fonts; define a `TextTheme` for consistency
- Use `Theme.of(context).textTheme` for text styles

## Layout
- Use `Expanded` to fill remaining space; `Flexible` to shrink-to-fit
- Use `Wrap` when widgets would overflow a Row/Column
- Use `LayoutBuilder` / `MediaQuery` for responsive layouts
- Use `ListView.builder` / `GridView.builder` for long scrollable content
- Use `Stack` + `Positioned`/`Align` for layered layouts

## UI Polish
- Use multi-layered drop shadows for depth; cards should look "lifted"
- Use icons to enhance understanding and navigation
- Apply the 60-30-10 color rule (primary/secondary/accent)
- Stress font sizes for hierarchy: hero text, section headlines, list headlines
- Buttons and interactive elements should have shadow/glow effects

## Color & Typography
- Meet WCAG 2.1 contrast standards: 4.5:1 for normal text, 3:1 for large text
- Limit to 1-2 font families; prioritize legibility
- Set line height to 1.4x-1.6x font size; aim for 45-75 character line length
- Avoid all caps for long-form text

## Assets
- Declare all asset paths in `pubspec.yaml`
- Use `Image.asset` for local images
- Use `Image.network` with `loadingBuilder` and `errorBuilder` for network images
- Use `cached_network_image` for cached network images

## Documentation
- Use Context7 plugin for most recent documentation
- Write `///` doc comments for all public APIs
- Start with a single-sentence summary, then a blank line, then details
- Comment the "why", not the "what"; avoid restating the obvious
- Be brief; avoid jargon and unnecessary acronyms

## Accessibility
- Ensure 4.5:1 contrast ratio for text against background
- Test UI with dynamic text scaling (increased system font size)
- Use `Semantics` widget for descriptive labels on UI elements
- Test with TalkBack (Android) and VoiceOver (iOS)

## Interaction Notes
- When a request is ambiguous, ask for clarification on functionality and target platform
- When suggesting new dependencies, explain their benefits
- Provide explanations for Dart-specific features when generating code
