# Chatterbox iOS Design System

## Overview

The Chatterbox iOS Design System provides a comprehensive, standardized set of design tokens, components, and patterns to ensure consistency across the application. This system follows iOS Human Interface Guidelines while maintaining our brand identity.

## Core Principles

1. **Consistency**: All UI elements should use design system tokens
2. **Accessibility**: Support Dynamic Type and VoiceOver
3. **Modularity**: Components should be reusable and composable
4. **Light Mode Only**: Currently, the app supports only light mode

## Design System Structure

```
chatterbox-apple/
├── UI/
│   ├── DesignSystem.swift        # Colors and button styles
│   ├── Theme/
│   │   ├── Spacing.swift         # Spacing tokens
│   │   └── Typography.swift      # Typography tokens
│   └── Components/               # (To be created) Reusable components
└── docs/
    └── design-system/
        ├── README.md             # This file
        ├── colors.md             # Color system documentation
        └── typography.md         # Typography system documentation
```

## Quick Reference

### Colors

All colors are defined in `UI/DesignSystem.swift` under the `AppColors` enum. Use semantic color names whenever possible.

```swift
// Brand colors
AppColors.green, .darkGreen
AppColors.blue, .darkBlue
AppColors.beige, .darkBeige, .sand

// Semantic colors
AppColors.cardBackground
AppColors.surfaceLight
AppColors.inputBackground

// Text colors
AppColors.textPrimary
AppColors.textSecondary
AppColors.textTertiary
AppColors.textContrast
```

See [colors.md](./colors.md) for complete documentation.

### Typography

All typography is defined in `UI/Theme/Typography.swift` under the `Typography` enum. Use semantic type styles.

```swift
// Headings
Typography.displayLarge
Typography.headingLarge
Typography.headingMedium

// Body
Typography.body
Typography.bodyMedium

// Labels
Typography.labelMedium
Typography.labelSmall

// Supporting
Typography.caption
Typography.footnote
```

See [typography.md](./typography.md) for complete documentation.

### Spacing

All spacing values are defined in `UI/Theme/Spacing.swift`.

```swift
Spacing.xs    // 4pt
Spacing.sm    // 8pt
Spacing.md    // 16pt
Spacing.lg    // 24pt
Spacing.xl    // 32pt
Spacing.xxl   // 48pt
```

## Button Styles

Three standard button styles are available in `UI/DesignSystem.swift`:

- **PrimaryButtonStyle**: Black background with white text, full width
- **PillButtonStyle**: Rounded capsule shape for prominent CTAs
- **DestructiveButtonStyle**: Red border for dangerous actions

```swift
Button("Save") { }
    .buttonStyle(PrimaryButtonStyle())
```

## Usage Guidelines

### DO

✅ Always use `AppColors` tokens for colors  
✅ Always use `Typography` tokens for text styles  
✅ Use semantic color names (`cardBackground` vs `darkBeige`)  
✅ Use `Spacing` tokens for consistent layouts  
✅ Create reusable components for repeated patterns  

### DON'T

❌ Don't use inline colors (`Color(hex: 0x...)`)  
❌ Don't use inline font definitions (`Font.system(...)`)  
❌ Don't use magic numbers for spacing  
❌ Don't duplicate UI patterns - extract to components  
❌ Don't use custom opacity values - use semantic text colors  

## Adding New Design Tokens

### Adding a New Color

1. Add to `AppColors` enum in `UI/DesignSystem.swift`
2. Use semantic naming (describe purpose, not appearance)
3. Document in `docs/design-system/colors.md`
4. Add usage examples

```swift
// Good
static let successBackground = Color(hex: 0x...)

// Bad
static let lightGreen = Color(hex: 0x...)
```

### Adding a New Typography Style

1. Add to `Typography` enum in `UI/Theme/Typography.swift`
2. Use semantic naming based on hierarchy/purpose
3. Document in `docs/design-system/typography.md`
4. Specify when to use

```swift
// Good
static let errorLabel = Font.system(.caption, weight: .semibold)

// Bad
static let smallBoldRed = Font.system(.caption, weight: .semibold)
```

## Future Enhancements

- [ ] SwiftUI Previews for all components
- [ ] Component library with reusable UI elements

## Related Documentation

- [Colors](./colors.md) - Complete color system reference
- [Typography](./typography.md) - Complete typography reference
- [iOS Dev Rulebook](../ios-dev-rulebok.md) - Architecture and coding standards

## Questions?

For questions about the design system or to propose changes, please discuss with the team lead or create an issue.

