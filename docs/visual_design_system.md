# Visual Design System

This file is the canonical visual source of truth for this project.

## Fonts

- `Fredoka` (Google Fonts): headings/titles, weight 700.
- `Nunito` (Google Fonts): body/labels, weight 600-800.
- Always use `Theme.of(context).textTheme`. Never hardcode fonts.

## Colors

Always use `AppColors` from `lib/core/theme/app_colors.dart`.

- Background: warm peach gradient (`bgTop` -> `bgBottom`).
- Primary accent: orange `#FF6B35`, orange dark `#E85D26`.
- Text:
  - Heading `#1A1B2E`
  - Body `#3D2B30`
  - Subtitle: 70% opacity
  - Muted: 50% opacity
- Glass surfaces:
  - `cardBg`: white at 45%
  - `glassBorder`: white at 40%
  - `inputBg`: white at 70%
- Subject colors: defined in `Subject` enum (`lib/core/constants/subject.dart`) via `.color`, `.colorB`, `.shadowColor`.
- Never hardcode colors or use default Material colors.

## Shared Widgets

Reuse these widgets. Do not reinvent them.

### GradientBackground

- File: `lib/core/widgets/gradient_background.dart`
- Use for: root wrapper for every screen (gradient + circles + `SafeArea`).

### GlassCard

- File: `lib/core/widgets/glass_card.dart`
- Use for: frosted glass panel (blur 10, white overlay, glass border).
- Params: `padding`, `borderRadius`, `opacity`.

### AppBackButton

- File: `lib/core/widgets/back_button.dart`
- Use for: 40x40 circular back button.

### ProgressBar

- File: `lib/core/widgets/progress_bar.dart`
- Use for: animated horizontal bar.

### StarDisplay

- File: `lib/core/widgets/star_display.dart`
- Use for: 0-3 star row.

### AvatarCircle

- File: `lib/core/widgets/avatar_circle.dart`
- Use for: emoji in gradient circle.

## Key Patterns

- Every screen: `GradientBackground` -> header row with `AppBackButton` + title -> scrollable content.
- Orange CTA button:
  - Full width
  - Gradient `orange` -> `orangeDark`
  - `borderRadius: 18`
  - Glow shadow (orange at 35%, blur 20, offset 0,6)
  - Text style: `textTheme.labelLarge`
- Glass card: use `GlassCard`, not plain `Card` or plain `Container`.
- Subject buttons:
  - Gradient `subject.color` -> `subject.colorB`
  - `borderRadius: 18`
  - Shadow from `subject.shadowColor`
- Selected state: orange at 15% background + orange border width 2.
- Animations:
  - `AnimatedContainer` 200ms for state changes
  - `AnimatedOpacity` 200ms for disabled states

## Spacing (Inline, No Constants File)

- Screen padding: horizontal 20
- Header: horizontal 16, vertical 8
- Card border radius: 18-20
- CTA radius: 18
- Badge radius: 14-16
- Section gaps: 12-16

## Rules

- Always wrap screens in `GradientBackground`. Never use plain `Scaffold` background.
- Use `GlassCard` for panels and `AppBackButton` for back navigation. Do not use Material defaults.
- Do not use raw `ElevatedButton`, `Card`, or `AppBar`. Use custom styled equivalents.
- All accent buttons/cards get a colored `BoxShadow` (~30% opacity, blur 16-20, offset 0,4-6).
- Make content scrollable (`SingleChildScrollView`) for small phones.
- Match the warm, playful, child-friendly tone of existing screens.
