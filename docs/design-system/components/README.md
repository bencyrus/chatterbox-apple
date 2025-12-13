# Component Library

## Overview

The Chatterbox component library provides reusable, standardized UI components that ensure consistency across the application. All components follow the design system tokens and are built with SwiftUI.

## Available Components

### Core Components
- **[Card](./card.md)** - Container component for grouping content
- **[Badge](./badge.md)** - Small labels for displaying metadata or status
- **[EmptyState](./empty-state.md)** - Placeholder views for empty content states
- **[FormTextField](./form-fields.md)** - Standardized text input fields

## Design Principles

1. **Composable** - Components can be nested and combined
2. **Customizable** - Support reasonable customization through parameters
3. **Accessible** - All components support VoiceOver and Dynamic Type
4. **Consistent** - Use design system tokens (AppColors, Typography, Spacing)

## Usage Guidelines

### Importing Components

Components are part of the main app target and don't require special imports:

```swift
import SwiftUI
// Components are available automatically
```

### Component Hierarchy

```
UI/
├── Components/
│   ├── Card.swift
│   ├── Badge.swift
│   ├── EmptyState.swift
│   └── FormTextField.swift
├── DesignSystem.swift
└── Theme/
    ├── Spacing.swift
    └── Typography.swift
```

## Creating New Components

When creating new components:

1. **Extract patterns** - If a UI pattern appears 3+ times, consider componentizing
2. **Use design tokens** - Always use AppColors, Typography, Spacing
3. **Document thoroughly** - Add doc comments and usage examples
4. **Test thoroughly** - Include in UI tests and manual testing
5. **Update this guide** - Add entry to component list above

### Component Template

```swift
import SwiftUI

/// Brief description of component.
///
/// Usage:
/// ```swift
/// MyComponent(text: "Hello")
/// ```
struct MyComponent: View {
    let text: String
    var backgroundColor: Color = AppColors.cardBackground
    
    var body: some View {
        Text(text)
            .padding(Spacing.md)
            .background(backgroundColor)
            .cornerRadius(12)
    }
}
```

## Component Categories

### Containers
- Card - Groups related content

### Input
- FormTextField - Text input

### Feedback
- EmptyState - No content state
- Badge - Status indicator

### Navigation
- (To be added) Button components with navigation

## Best Practices

### DO ✅
- Use components consistently across the app
- Customize through parameters, not by copying code
- Report missing features or needed customizations
- Keep components focused on single responsibility
- Use semantic color names (e.g., `cardBackground` not `darkBeige`)

### DON'T ❌
- Copy component code instead of importing
- Modify component internals for one-off cases
- Add non-generic features to shared components
- Ignore design system tokens
- Create components for one-time use

## Performance Considerations

- All components are lightweight SwiftUI views
- No heavy computation in body
- Prefer value types (struct) over reference types
- Components support lazy loading in lists

## Accessibility

All components include:
- Proper semantic structure
- VoiceOver support
- Dynamic Type scaling
- Sufficient touch targets (44x44pt minimum)

## Related Documentation

- [Design System Overview](../README.md)
- [Color System](../colors.md)
- [Typography System](../typography.md)
- [iOS Dev Rulebook](../../ios-dev-rulebok.md)

## Support

For questions or requests:
1. Check existing component documentation
2. Review design system tokens
3. Discuss with team before creating new components
4. Update documentation when components change

