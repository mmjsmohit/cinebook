# CineBook Theme Design System & Overhaul Plan

This document specifies the architecture, tokens, and systematic plan for overhauling the CineBook app-wide design from generic vanilla Material UI to the custom, premium "Immersive Cinema" aesthetic.

---

## 1. Context & Strategy

### Problem Statement
The current Flutter application uses standard vanilla Material UI defaults (e.g. standard dark theme with generic purple/pink overrides). This lacks distinct brand character, feels generic, and has poor visual contrast in crucial layout elements (such as white bottom sheets/cards on a dark background).

### Solution Strategy
We will centralize styling definitions inside the shared `cinebook_core` package so that all sub-applications (`cinebook_user_app`, `cinebook_hall_app`) resolve colors, shapes, typography, and custom properties from a single source of truth.

---

## 2. Design Tokens & theme configurations

### Brand Palette (`CinemaColors`)
*   **Neon Red** (`0xFFFF2E51`): Main action triggers, active highlights.
*   **Neon Red Deep** (`0xFFE01B3C`): Button hover and focus states.
*   **Warm Amber** (`0xFFFF9F0A`): Seating premium classes, warning states.
*   **Success Green** (`0xFF30D158`): Available seats.
*   **Deep Charcoal** (`0xFF0B0C0E`): Base application scaffold background.
*   **Ink Charcoal** (`0xFF16181C`): Elevated surfaces (cards, inputs, dialogues).
*   **Steel Gray** (`0xFF8E939E`): Muted text, secondary status tags.
*   **Structural Border** (`0xFF2C2E35`): Outer borders for cards and dividers.
*   **Off-White** (`0xFFF5F6F8`): High-contrast primary body text.

### Custom theme Extensions (`CinemaThemeExtension`)
Flutter's standard `ThemeData` does not support specific elements like seat statuses or neon glow shadows. We expose a custom `CinemaThemeExtension` containing:
*   `neonGlow` (`List<BoxShadow>`): Glowing outline shadows mimicking screen project effects.
*   `seatAvailable` (`Color`): Color mapping for unreserved seats.
*   `seatSelected` (`Color`): Color mapping for user's selected seats.
*   `seatSold` (`Color`): Color mapping for booked/disabled seats.
*   `structuralBorder` (`Color`): Color mapping for containers.

---

## 3. Implementation Plan

We will overhaul the codebase systematically in five discrete steps:

### Phase 1: Shared Theme Setup (Foundational)
1.  Add `google_fonts` package to `cinebook_core`'s `pubspec.yaml` dependencies.
2.  Create the custom theme files under `cinebook_core/lib/src/theme/`:
    *   `cinema_colors.dart`
    *   `cinema_theme_extension.dart`
    *   `cinema_theme.dart`
3.  Export the theme files in `cinebook_core/lib/cinebook_core.dart` to make them public to consumer apps.
4.  Configure the root `MaterialApp` in `cinebook_user_app` and `cinebook_hall_app` to use `CinemaTheme.darkTheme`.

### Phase 2: Login and Navigation Overhaul
1.  Apply `Theme.of(context)` properties to `login_screen.dart`.
2.  Refactor forms, text fields, and verification buttons to use the default custom input/button themes.
3.  Overhaul the navigation bar/bottom nav in `main_screen.dart` to use translucent dark styles (`#0B0C0E` with background blur) instead of hard colors.

### Phase 3: Seat Map Screen Overhaul (Visual Core)
1.  Revamp `seat_map_screen.dart` to fully adopt the theme.
2.  Replace standard colors in the seat map grid with `Theme.of(context).extension<CinemaThemeExtension>()` variables.
3.  Replace the white bottom action sheet (which violates the dark theme) with a dark `Card` using `CinemaColors.inkCharcoal` and thin border outlines.

### Phase 4: Agent Chat Screen Overhaul
1.  Update `agent_screen.dart` to use premium dark-mode bubbles.
2.  Refactor chatbot typing indications, loading shimmers, and generated A2UI widget cards to align with the typography and color specifications.

### Phase 5: Hall Manager Screen Overhaul
1.  Align screen lists and calendaring layouts in `cinebook_hall_app` to use the dark theme cards and typography sizes.
