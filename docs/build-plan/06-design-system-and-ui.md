Status: current  
Last verified: 2025-11-27

## 06 — Design System & UI Platform

### Why this exists

- Provide a **single design system** so every screen looks and behaves consistently.
- Encode best practices from Apple’s HIG and the deep research into **tokens + components** the codebase must use.

### Role in the system

- Specifies:
  - Color, typography, spacing, radii, shadows (tokens).
  - Reusable components and modifiers.
  - Accessibility and localization expectations for UI.
  - Preview and testing requirements for design system elements.

---

## 1. Token architecture

### 1.1 Colors

- Stored in `Assets.xcassets` as semantic color sets with Any/Dark (and optional high contrast) variants.
- Example tokens (prefixes optional but recommended):
  - Background:
    - `Background.Primary`
    - `Background.Secondary`
    - `Background.Elevated`
  - Text:
    - `Text.Primary`
    - `Text.Secondary`
    - `Text.Inverse`
  - Accent & feedback:
    - `Accent.Primary`
    - `Accent.Secondary`
    - `Accent.Warning`
    - `Accent.Success`
    - `Accent.Danger`

- App code only uses:
  - `Color("Background.Primary")`, or wrapper `Colors.backgroundPrimary`.
  - System semantic colors (`Color.primary`, `Color.secondary`) when appropriate.

### 1.2 Typography

- Defined in `UI/Theme/Typography.swift`:
  - Map to Dynamic Type text styles with semantic names:
    - `Typography.displayXL`
    - `Typography.heading`
    - `Typography.body`
    - `Typography.caption`
  - Use system fonts or custom fonts with `.relativeTo` for Dynamic Type support.

### 1.3 Spacing, radii, shadows

- Spacing (`UI/Theme/Spacing.swift`):
  - Based on a 4pt or 8pt grid (consistent across app).
  - Example: `Spacing.xs = 4`, `Spacing.sm = 8`, `Spacing.md = 16`, `Spacing.lg = 24`, `Spacing.xl = 32`.

- Corners (`UI/Theme/Corners.swift`):
  - `Corners.none`, `Corners.sm`, `Corners.md`, `Corners.lg`, `Corners.full`.

- Shadows (`UI/Theme/Shadows.swift`):
  - Encapsulate common drop shadows for cards and elevated surfaces.

---

## 2. Components & modifiers

### 2.1 Buttons

- `PrimaryButtonStyle`:
  - Full‑width by default.
  - Accent background, text color `Text.Inverse`.
  - States: normal, pressed (subtle scale/opacity), disabled.
  - Optional loading overlay (spinner).

- `SecondaryButtonStyle`:
  - Outlined style with accent stroke and transparent background.

- `DestructiveButtonStyle`:
  - Uses `Accent.Danger` with accessible contrast.

### 2.2 Cards & surfaces

- `BaseCard` or `.cardStyle()` modifier:
  - Uses `Background.Secondary` with rounded corners and shadow.
  - Applies appropriate padding and spacing between content.

- `CueCardView`:
  - Reusable for cue list and detail; composes:
    - Title, snippet of details, optional metadata badges (stage, language).
    - Optional indicators for recording state (future).

### 2.3 Inputs

- `IdentifierTextField`:
  - Styled with input background, border, and focused border tokens.
  - Supports email/phone content types and validation indicator.

- OTP input (future):
  - Multi‑digit one‑time code field with `textContentType = .oneTimeCode`.

### 2.4 Feedback components

- `BannerView`:
  - For inline success/warning/error notices with icon and title/message.

- `EmptyStateView`:
  - For empty lists or unavailable data; includes icon, title, description, and optional CTA.

- `ErrorView`:
  - For full‑screen error states; includes retry button where appropriate.

### 2.5 Skeletons

- `SkeletonRow` / `SkeletonList`:
  - Shimmering placeholders for lists (e.g., cues) while loading.
  - Based on `.shimmer()` modifier and card tokens.

---

## 3. Accessibility & localization for UI

### 3.1 Accessibility

- Every interactive element:
  - Has `accessibilityLabel` and, where needed, `accessibilityHint`.
  - Uses `.contentShape(Rectangle())` for cards so the whole surface is tappable.
  - Respects 44x44pt minimum touch target size.

- Dynamic Type:
  - Use text styles (`.font(.title)`, `.font(.body)`) or tokens built on top of them.
  - Test at large accessibility sizes; prefer multiline text over truncation.

- Motion:
  - Respect `reduceMotion`; animations should be subtle and non‑blocking.

### 3.2 Localization

- No hardcoded user‑visible strings in views:
  - Every label, button title, hint, and error message comes from `Strings`.
  - Multi‑language content (e.g., cues themselves) come from backend payloads.

- For dynamic messages (e.g., countdowns, counts):
  - Use `.stringsdict` and `String.localizedStringWithFormat` or dedicated helpers in `Strings`.

---

## 4. Previews & design verification

- Every reusable component ships with SwiftUI previews covering:
  - Light and dark mode.
  - Default and large Dynamic Type sizes.
  - At least one non‑English locale (or pseudolanguage) for layout testing.
  - All significant states (loading, error, empty).

- Preview data:
  - Lives in feature‑specific `PreviewContent.swift` files.
  - Contains no PII or secrets.

---

## 5. Integration rules

- All features:
  - Use tokens and components from `UI/Theme` and `UI/Components`.
  - Do **not** apply direct `Color`, `Font`, or arbitrary `padding` values in feature views.
  - Wrap any truly unique visual pattern into a reusable component or modifier and document it here.

- When backend provides display metadata:
  - Use backend text for titles/labels where appropriate (e.g., cue stage labels, CTA labels).
  - Only apply visual treatment and layout decisions in the client.

---

## 6. Action checklist

- [ ] Core token structs (`Colors`, `Typography`, `Spacing`, `Corners`, `Shadows`) are implemented in `UI/Theme`.
- [ ] Common components (buttons, cards, inputs, feedback, skeletons) exist in `UI/Components`.
- [ ] All views for Auth, Settings, and Cues use design system tokens exclusively.
- [ ] Previews are present for components and major screens, covering light/dark and Dynamic Type.
- [ ] Accessibility (labels, hints, touch targets, contrast) is honored across all design system elements.


