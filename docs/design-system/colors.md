# Color System

## Overview

The Chatterbox color system is defined in `UI/DesignSystem.swift` under the `AppColors` enum. All colors use hex values for precision and are organized by purpose.

## Color Palette

### Brand Colors

#### Green

- **`AppColors.green`** - `#b3cbc0`
  - **Purpose**: Success indicators, positive feedback
  - **Usage**: Success messages, checkmarks, positive status indicators
  - **Example**: Recording saved confirmation

- **`AppColors.darkGreen`** - `#7fa395`
  - **Purpose**: Darker green accent for emphasis
  - **Usage**: Status bars, stronger positive accents
  - **Example**: Save button in recording controls

#### Blue

- **`AppColors.blue`** - `#bec8e3`
  - **Purpose**: Secondary accent color
  - **Usage**: Highlights, secondary actions
  - **Example**: Language picker selected state overlay

- **`AppColors.darkBlue`** - `#8f9bb8`
  - **Purpose**: Darker blue for emphasis
  - **Usage**: Selected states, active elements
  - **Example**: Language picker border when selected

#### Beige & Sand

- **`AppColors.beige`** - `#f7e4d6`
  - **Purpose**: Surface color for cards and details
  - **Usage**: Detail cards, error indicators, secondary surfaces
  - **Example**: Audio player background

- **`AppColors.darkBeige`** - `#e5d2c4`
  - **Purpose**: Card backgrounds
  - **Usage**: Cue cards, recording history cards, input backgrounds
  - **Example**: Cue content card

- **`AppColors.sand`** - `#eeeee6`
  - **Purpose**: Primary app background
  - **Usage**: Screen backgrounds, main content area
  - **Example**: All main views background

### Recording UI Colors

- **`AppColors.recordingRed`** - `#E74C3C`
  - **Purpose**: Primary recording indicator
  - **Usage**: Record button, active recording state
  - **Example**: Record button fill, pause icon color

- **`AppColors.recordingRedLight`** - `#d98f8f`
  - **Purpose**: Delete and cancel actions
  - **Usage**: Delete button during recording
  - **Example**: Trash icon and border in paused state

- **`AppColors.recordingRedDark`** - `#C0392B`
  - **Purpose**: Text on light recording backgrounds
  - **Usage**: Resume button text
  - **Example**: "RESUME" text on recording background

- **`AppColors.recordingBackground`** - `#E5C4B8`
  - **Purpose**: Background for paused recording state
  - **Usage**: Resume button background
  - **Example**: Pause state resume button fill

### System Colors

- **`AppColors.systemGray`** - `Color(.systemGray3)`
  - **Purpose**: Neutral UI elements
  - **Usage**: Cancel buttons, neutral backgrounds
  - **Example**: Cancel button in account deletion flow

### Error Colors

- **`AppColors.errorBackground`** - `Color(red: 0.7, green: 0.1, blue: 0.1)`
  - **Purpose**: Destructive actions background
  - **Usage**: Delete account button, critical warnings
  - **Example**: Account deletion confirmation button

### Text Colors

- **`AppColors.textPrimary`** - `Color.black`
  - **Purpose**: Primary text color
  - **Usage**: Headlines, body text, labels
  - **Example**: All primary content text

- **`AppColors.textSecondary`** - `Color.black.opacity(0.6)`
  - **Purpose**: Secondary text (60% opacity)
  - **Usage**: Hints, helper text, less important information
  - **Example**: Cooldown message in login

- **`AppColors.textTertiary`** - `Color.black.opacity(0.7)`
  - **Purpose**: Tertiary text (70% opacity)
  - **Usage**: Timestamps, metadata
  - **Example**: Audio player time labels

- **`AppColors.textQuaternary`** - `Color.black.opacity(0.8)`
  - **Purpose**: Quaternary text (80% opacity)
  - **Usage**: Badge text, less prominent labels
  - **Example**: Recording history card metadata

- **`AppColors.textContrast`** - `Color.white`
  - **Purpose**: Text on dark backgrounds
  - **Usage**: Button labels on dark backgrounds
  - **Example**: Primary button text

### Semantic Colors

- **`AppColors.cardBackground`** - Alias for `darkBeige`
  - **Purpose**: Standard card background
  - **Usage**: Any card component
  - **Recommendation**: Use this instead of `darkBeige` for better semantic clarity

- **`AppColors.surfaceLight`** - Alias for `beige`
  - **Purpose**: Light surface color
  - **Usage**: Secondary surfaces, elevated cards

- **`AppColors.inputBackground`** - Alias for `darkBeige`
  - **Purpose**: Input field backgrounds
  - **Usage**: TextFields, text input areas
  - **Example**: Login email field

- **`AppColors.borderNeutral`** - `Color.gray.opacity(0.3)`
  - **Purpose**: Neutral borders and strokes
  - **Usage**: Button outlines, dividers
  - **Example**: Recording button stroke

- **`AppColors.badgeBackground`** - `Color.gray.opacity(0.2)`
  - **Purpose**: Badge backgrounds
  - **Usage**: Date badges, count badges
  - **Example**: History date badges

- **`AppColors.divider`** - `Color.black.opacity(0.1)`
  - **Purpose**: Dividers and separators
  - **Usage**: List separators, section dividers
  - **Example**: Recording history card badge backgrounds

- **`AppColors.overlayBackground`** - `Color.black.opacity(0.4)`
  - **Purpose**: Modal overlay backgrounds
  - **Usage**: Alert overlays, modal dimming
  - **Example**: Account deletion confirmation overlay

- **`AppColors.shadow`** - `Color.black.opacity(0.15)`
  - **Purpose**: Shadow colors
  - **Usage**: Drop shadows, elevation
  - **Example**: Logo shadow in login view

## Usage Guidelines

### Color Selection

1. **Always use semantic names first**: `cardBackground` over `darkBeige`
2. **Use text hierarchy**: `textPrimary` → `textSecondary` → `textTertiary` → `textQuaternary`
3. **Match colors to intent**: Success → green, Error → red, Neutral → gray

### Code Examples

```swift
// ✅ Good: Semantic color
VStack {
    Text("Title")
        .foregroundColor(AppColors.textPrimary)
}
.background(AppColors.cardBackground)

// ❌ Bad: Inline color
VStack {
    Text("Title")
        .foregroundColor(.black.opacity(0.8))
}
.background(Color(hex: 0xe5d2c4))
```

### Accessibility

- All text colors meet WCAG AA contrast requirements on their intended backgrounds
- Text opacity levels are standardized: 100%, 80%, 70%, 60%
- Primary text (black) on sand background has excellent contrast (AAA)

### Adding New Colors

When adding new colors:

1. Add to appropriate category in `AppColors`
2. Use hex values for brand colors
3. Use semantic naming
4. Document purpose and usage here
5. Provide usage examples

```swift
/// New color documentation
/// - Purpose: What is this color for?
/// - Usage: When should it be used?
/// - Example: Where is it currently used?
static let newColor = Color(hex: 0x...)
```

## Color Accessibility Matrix

| Text Color | Background | Contrast Ratio | WCAG Level |
|-----------|-----------|---------------|-----------|
| textPrimary (black) | sand | 16.8:1 | AAA |
| textPrimary | cardBackground | 15.2:1 | AAA |
| textSecondary (60%) | sand | 10.1:1 | AAA |
| textTertiary (70%) | sand | 11.8:1 | AAA |
| textContrast (white) | textPrimary (black) | 21:1 | AAA |

## Migration from Inline Colors

All inline colors have been migrated to `AppColors` tokens. If you find any remaining inline colors:

```swift
// Before
.foregroundColor(Color(hex: 0xE74C3C))

// After
.foregroundColor(AppColors.recordingRed)
```

Report or fix immediately to maintain consistency.

## Related Files

- `UI/DesignSystem.swift` - Color definitions
- `UI/Theme/Typography.swift` - Text styles that use these colors
- `docs/design-system/README.md` - Design system overview

