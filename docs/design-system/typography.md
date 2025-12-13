# Typography System

## Overview

The Chatterbox typography system is defined in `UI/Theme/Typography.swift` under the `Typography` enum. All text styles are based on Apple's Dynamic Type system, ensuring proper scaling and accessibility.

## Type Scale

### Display Styles

Large, prominent text for branding and major sections.

#### `Typography.displayLarge`
- **Definition**: `Font.system(.largeTitle, weight: .bold)`
- **Purpose**: App branding, major section titles
- **Size**: 34pt (default)
- **Weight**: Bold
- **Usage**: Large titles, splash screens
- **Example**: Not currently used (reserved for future)

#### `Typography.displayMedium`
- **Definition**: `Font.system(.title, weight: .bold)`
- **Purpose**: Section titles
- **Size**: 28pt (default)
- **Weight**: Bold
- **Usage**: Modal headers, major sections
- **Example**: Not currently used (consider for major sections)

### Heading Styles

Hierarchical headings for content structure.

#### `Typography.headingLarge`
- **Definition**: `Font.system(.title2, weight: .bold)`
- **Purpose**: Primary content headings
- **Size**: 22pt (default)
- **Weight**: Bold
- **Usage**: Page headers, card titles, primary headings
- **Example**: Cue titles, section headers, PageHeader component

#### `Typography.headingMedium`
- **Definition**: `Font.system(.title3, weight: .semibold)`
- **Purpose**: Subsection headings
- **Size**: 20pt (default)
- **Weight**: Semibold
- **Usage**: Card subsections, grouped content headers
- **Example**: "Recording History" section title

#### `Typography.headingSmall`
- **Definition**: `Font.system(.headline, weight: .semibold)`
- **Purpose**: Card titles and small headings
- **Size**: 17pt (default, same as body but semibold)
- **Weight**: Semibold
- **Usage**: List item titles, small cards
- **Example**: Network log section titles

### Body Styles

Standard text for content and descriptions.

#### `Typography.body`
- **Definition**: `Font.body`
- **Purpose**: Standard text content
- **Size**: 17pt (default)
- **Weight**: Regular
- **Usage**: Paragraphs, descriptions, button labels
- **Example**: Cue details, settings text, most UI text

#### `Typography.bodyMedium`
- **Definition**: `Font.system(.callout, weight: .regular)`
- **Purpose**: Slightly smaller body text
- **Size**: 16pt (default)
- **Weight**: Regular
- **Usage**: Secondary content, smaller paragraphs
- **Example**: Not currently used (available for future)

### Label Styles

Short pieces of text for UI labels and metadata.

#### `Typography.labelLarge`
- **Definition**: `Font.system(.subheadline, weight: .medium)`
- **Purpose**: Prominent labels
- **Size**: 15pt (default)
- **Weight**: Medium
- **Usage**: Form labels, prominent metadata
- **Example**: Not currently used (available for future)

#### `Typography.labelMedium`
- **Definition**: `Font.system(.caption, weight: .medium)`
- **Purpose**: Standard labels and badges
- **Size**: 12pt (default)
- **Weight**: Medium
- **Usage**: Badges, small labels, metadata
- **Example**: Date badges, count badges

#### `Typography.labelSmall`
- **Definition**: `Font.system(.caption2, weight: .medium)`
- **Purpose**: Minimal labels
- **Size**: 11pt (default)
- **Weight**: Medium
- **Usage**: Very small labels, icon labels
- **Example**: Calendar icon labels in badges

### Supporting Text

Supplementary information and fine print.

#### `Typography.caption`
- **Definition**: `Font.caption`
- **Purpose**: Secondary information
- **Size**: 12pt (default)
- **Weight**: Regular
- **Usage**: Timestamps, helper text, secondary info
- **Example**: Audio player timestamps, recording times, hints

#### `Typography.footnote`
- **Definition**: `Font.footnote`
- **Purpose**: Fine print
- **Size**: 13pt (default)
- **Weight**: Regular
- **Usage**: Legal text, detailed disclaimers
- **Example**: Login cooldown message

### Specialty Styles

Special-purpose typography for specific UI needs.

#### `Typography.monospacedTimer`
- **Definition**: `Font.system(size: 36, weight: .medium, design: .monospaced)`
- **Purpose**: Recording timer display
- **Size**: 36pt (fixed)
- **Weight**: Medium
- **Design**: Monospaced
- **Usage**: Recording duration timers
- **Example**: RecordingControlView timer

#### `Typography.monospacedCode`
- **Definition**: `Font.system(.body, design: .monospaced)`
- **Purpose**: Code and technical content
- **Size**: 17pt (default)
- **Weight**: Regular
- **Design**: Monospaced
- **Usage**: Debug logs, JSON, technical info
- **Example**: Network log detail view

## Deprecated Styles

These styles are maintained for backward compatibility but should be migrated:

- **`Typography.title`** → Use `Typography.displayMedium` or `Typography.headingLarge`
- **`Typography.heading`** → Use `Typography.headingLarge`

## Type Hierarchy

```
displayLarge (34pt, bold)
└── displayMedium (28pt, bold)
    └── headingLarge (22pt, bold)
        └── headingMedium (20pt, semibold)
            └── headingSmall (17pt, semibold)
                └── body (17pt, regular)
                    └── bodyMedium (16pt, regular)
                        └── labelLarge (15pt, medium)
                            └── footnote (13pt, regular)
                                └── caption (12pt, regular)
                                    └── labelMedium (12pt, medium)
                                        └── labelSmall (11pt, medium)
```

## Usage Guidelines

### Choosing the Right Type Style

1. **Start with semantics**: Choose based on meaning, not appearance
2. **Follow hierarchy**: Maintain proper heading levels (h1 → h2 → h3)
3. **Use body for content**: Default to `Typography.body` for readable text
4. **Use labels for UI**: Short text and metadata should use label styles
5. **Avoid custom sizes**: Use predefined styles for consistency

### Code Examples

```swift
// ✅ Good: Semantic typography
VStack(alignment: .leading) {
    Text("Section Title")
        .font(Typography.headingLarge)
    
    Text("Description text goes here")
        .font(Typography.body)
    
    Text("Last updated: 2 hours ago")
        .font(Typography.caption)
        .foregroundColor(AppColors.textSecondary)
}

// ❌ Bad: Inline font definition
VStack(alignment: .leading) {
    Text("Section Title")
        .font(.system(.title2, weight: .bold))
    
    Text("Description text")
        .font(.system(size: 17))
}
```

### Font Weights

Available weights in order:
- `.ultraLight` - Very thin
- `.thin` - Thin
- `.light` - Light
- `.regular` - Default
- `.medium` - Medium (labels)
- `.semibold` - Semibold (headings)
- `.bold` - Bold (display)
- `.heavy` - Heavy
- `.black` - Black (ultra bold)

**Our system uses**: regular, medium, semibold, bold

### Dynamic Type

All typography styles automatically support Dynamic Type, which means:

- Text scales based on user's accessibility settings
- Minimum and maximum sizes are handled by the system
- No custom scaling logic needed

To test Dynamic Type:
1. Open Settings → Accessibility → Display & Text Size → Larger Text
2. Adjust the slider
3. Return to the app to see changes

## Accessibility

### Best Practices

✅ Use semantic styles for proper Dynamic Type support  
✅ Test with largest text size  
✅ Use `.minimumScaleFactor()` only when absolutely necessary  
✅ Prefer truncation over shrinking  
✅ Allow text to wrap when possible  

❌ Don't use fixed font sizes except for specialty UI  
❌ Don't disable Dynamic Type  
❌ Don't rely on font size for information hierarchy  
❌ Don't use too many different text styles in one view  

### Line Spacing

SwiftUI handles line spacing automatically. For custom line spacing:

```swift
Text("Multi-line text")
    .font(Typography.body)
    .lineSpacing(4) // Add 4pt between lines
```

### Combining with Color

Always pair text styles with appropriate colors:

```swift
// Primary content
Text("Main title")
    .font(Typography.headingLarge)
    .foregroundColor(AppColors.textPrimary)

// Secondary info
Text("Additional details")
    .font(Typography.caption)
    .foregroundColor(AppColors.textSecondary)
```

## Common Patterns

### Card Title + Body

```swift
VStack(alignment: .leading, spacing: Spacing.sm) {
    Text("Card Title")
        .font(Typography.headingMedium)
        .foregroundColor(AppColors.textPrimary)
    
    Text("Card description text")
        .font(Typography.body)
        .foregroundColor(AppColors.textPrimary)
}
```

### Metadata Badge

```swift
HStack(spacing: 4) {
    Image(systemName: "calendar")
        .font(.caption2)
    Text("Today")
        .font(Typography.labelMedium)
}
.foregroundColor(AppColors.textPrimary)
```

### Button Label

```swift
Button("Primary Action") { }
    .buttonStyle(PrimaryButtonStyle())
// PrimaryButtonStyle uses Typography.body with .medium weight
```

## Migration from Inline Fonts

If you find inline font definitions:

```swift
// Before
.font(.system(.title2, weight: .bold))
.font(.system(size: 36, weight: .medium, design: .monospaced))
.font(.caption.weight(.medium))

// After
.font(Typography.headingLarge)
.font(Typography.monospacedTimer)
.font(Typography.labelMedium)
```

## Adding New Type Styles

When adding a new type style:

1. Add to appropriate category in `Typography`
2. Use semantic naming based on purpose
3. Document purpose, size, weight, and usage
4. Provide code examples
5. Update this document

```swift
/// New style documentation
/// - Purpose: What is this style for?
/// - Size: What is the default size?
/// - Weight: What weight is used?
/// - Usage: When should it be used?
static let newStyle = Font.system(...)
```

## Related Files

- `UI/Theme/Typography.swift` - Type style definitions
- `UI/DesignSystem.swift` - Button styles that use typography
- `UI/Theme/Spacing.swift` - Spacing values for layout
- `docs/design-system/colors.md` - Color system for text colors

