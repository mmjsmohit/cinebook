---
name: CineBook
description: AI-Powered Movie Booking Platform
colors:
  primary: "#ff2e51"
  secondary: "#ff9f0a"
  success: "#30d158"
  neutral-bg: "#0b0c0e"
  neutral-surface: "#16181c"
  neutral-ink: "#f5f6f8"
  neutral-muted: "#8e939e"
  border: "#2c2e35"
typography:
  display:
    fontFamily: "Inter, sans-serif"
    fontSize: "clamp(2rem, 5vw, 3.5rem)"
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: "-0.02em"
  body:
    fontFamily: "Inter, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "normal"
rounded:
  sm: "4px"
  md: "8px"
  lg: "16px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.neutral-ink}"
    rounded: "{rounded.md}"
    padding: "16px 24px"
  button-primary-hover:
    backgroundColor: "#e01b3c"
  card:
    backgroundColor: "{colors.neutral-surface}"
    rounded: "{rounded.lg}"
    padding: "16px"
---

# Design System: CineBook

## 1. Overview

**Creative North Star: "Immersive Theatre Marquee"**

CineBook's visual system evokes the dark, focused environment of a movie theater. By wrapping the interface in a deep charcoal canvas, user attention is immediately drawn to the vibrant, high-contrast visual elements like movie poster art, trailer previews, and glowing active statuses.

The aesthetic rejects flat, bland SaaS layout templates and cluttered ticketing site patterns. Instead, it relies on content-first layouts, crisp typography, and micro-interactions. Key components use solid background colors and strategic glows to signify interactive surfaces.

**Key Characteristics:**
- Dark-mode-first immersive atmosphere.
- Saturated red and warm amber glows as primary interactive accents.
- Highly legible typography with generous line height and clean letter-spacing.
- Clean poster grids and structural borders instead of decorative lines.

## 2. Colors

The color palette draws directly from the movie theatre experience—combining a near-black room with neon red marquee highlights and glowing amber warnings.

### Primary
- **Neon Red** (#ff2e51 / oklch(62% 0.25 15)): Used exclusively for primary call-to-actions, brand accents, and active focus highlights.

### Secondary
- **Warm Amber** (#ff9f0a / oklch(76% 0.20 70)): Used for seating categories (e.g. premium, recliners), promotional alerts, and highlight states.

### Neutral
- **Deep Charcoal Background** (#0b0c0e / oklch(12% 0.01 250)): The base room background, ensuring maximum poster visibility and low eye strain.
- **Ink Charcoal Surface** (#16181c / oklch(18% 0.02 250)): Elevated surfaces, cards, and input fields.
- **Crisp Off-white Ink** (#f5f6f8 / oklch(96% 0.005 250)): Main text color, providing excellent contrast against charcoal backgrounds.
- **Steel Gray Ink** (#8e939e / oklch(64% 0.01 250)): Secondary labels, descriptive text, and deactivated statuses.
- **Structural Border** (#2c2e35 / oklch(25% 0.01 250)): Used for subtle dividers and containers.

### Named Rules
**The Marquee Accent Rule.** The primary neon red accent color must be used on less than 10% of any given screen. Its impact comes from its scarcity and brightness against the dark background.
**The High Contrast Text Rule.** All body text must maintain a contrast ratio of at least 4.5:1 against its background. Never use muted light-gray text on gray cards.

## 3. Typography

**Display Font:** Inter, sans-serif
**Body Font:** Inter, sans-serif

The font stack relies on the clean, highly legible humanist sans-serif family, Inter. The typography creates contrast through dramatic weight variations and tracking rather than mixing multiple typefaces.

### Hierarchy
- **Display** (800, clamp(2rem, 5vw, 3.5rem), 1.1): Used for large hero titles and movie titles in detail views. Uses negative letter-spacing (-0.02em) to look compact and designed.
- **Headline** (700, 24px, 1.2): Section headers and screen titles.
- **Title** (600, 18px, 1.3): Movie cards, seat category titles, and important summaries.
- **Body** (400, 16px, 1.5): Standard prose, movie descriptions, and user inputs. Line length capped at 70ch.
- **Label** (500, 12px, 0.05em, uppercase): Tiny metadata tags, eyebrows, table headers, and status flags.

### Named Rules
**The Balanced Headline Rule.** All h1 to h3 headings must use `text-wrap: balance` to prevent awkward line breaks and single-word orphans.

## 4. Elevation

The design system uses subtle light layering rather than heavy drop shadows. Elevated surfaces stand out by shifting lightness slightly or displaying thin container borders.

### Shadow Vocabulary
- **Neon Glow** (`0 0 12px rgba(255, 46, 81, 0.4)`): Used for hovered/selected primary states (such as selected seats or primary buttons) to simulate projection light.

### Named Rules
**The Flat-by-Default Rule.** Surfaces are flat at rest, using `#16181c` to denote cards. Shadows and glowing outlines appear only as a response to interactive states (hover, focus).

## 5. Components

### Buttons
- **Shape:** Medium curved corners (8px radius)
- **Primary:** Neon Red (#ff2e51) background with crisp white text. Generous internal padding (16px vertical, 24px horizontal).
- **Hover / Focus:** Transitions smoothly to a deeper red (#e01b3c) with a subtle neon glow outline.
- **Secondary:** Transparent background with a 1px structural border (#2c2e35) and off-white text.

### Chips
- **Style:** Ink Charcoal background (#16181c), 1px border (#2c2e35), steel gray text.
- **State:** When selected, shifts to a primary Neon Red background or success green background with white text.

### Cards / Containers
- **Corner Style:** Large rounded corners (16px radius)
- **Background:** Ink Charcoal (#16181c)
- **Border:** Thin 1px border (#2c2e35) to define bounds against the near-black background.
- **Internal Padding:** Scaled from 16px to 24px based on screen size.

### Inputs / Fields
- **Style:** Flat dark background (#16181c) with a subtle bottom border or 1px surrounding border (#2c2e35).
- **Focus:** Border transitions to Neon Red (#ff2e51) with a soft red glow.

### Navigation
- **Style:** Sticky top navigation or bottom app bar. Translucent dark background (#0b0c0e at 85% opacity) with a backdrop blur filter (8px) to let posters slide behind smoothly.

## 6. Do's and Don'ts

### Do:
- **Do** maintain a strict dark theme using high-contrast text to keep details readable.
- **Do** use movie posters as the primary visual drivers, keeping the surrounding layout clean and minimal.
- **Do** use smooth, exponential easing for all interactive transitions and hover effects.

### Don't:
- **Don't** use generic white or light-gray SaaS dashboards (e.g. gray outline boxes).
- **Don't** add colored side-stripe accent borders to cards or alert banners.
- **Don't** use gradient text or over-designed glassmorphism as a default decoration.
- **Don't** animate movie posters or images on hover; restrict hover effects to backgrounds, borders, and button elements.
