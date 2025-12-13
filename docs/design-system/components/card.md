# Card Component

## Overview

The Card component provides a standardized container for grouping related content with consistent padding, background color, and rounded corners.

## API Reference

### Card

```swift
struct Card<Content: View>: View {
    init(
        backgroundColor: Color = AppColors.cardBackground,
        padding: CGFloat = Spacing.md,
        cornerRadius: CGFloat = 12,
        @ViewBuilder content: () -> Content
    )
}
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `backgroundColor` | `Color` | `AppColors.cardBackground` | Background color of the card |
| `padding` | `CGFloat` | `Spacing.md` (16pt) | Internal padding |
| `cornerRadius` | `CGFloat` | `12` | Corner radius |
| `content` | `@ViewBuilder` | Required | Content to display inside card |

### View Extension

```swift
extension View {
    func cardStyle(
        backgroundColor: Color = AppColors.cardBackground,
        padding: CGFloat = Spacing.md,
        cornerRadius: CGFloat = 12
    ) -> some View
}
```

## Usage Examples

### Basic Usage

```swift
Card {
    Text("Hello, Card!")
}
```

### Custom Background

```swift
Card(backgroundColor: AppColors.surfaceLight) {
    VStack {
        Text("Title")
            .font(Typography.headingMedium)
        Text("Description")
            .font(Typography.body)
    }
}
```

### Using View Extension

```swift
VStack {
    Text("Title")
    Text("Description")
}
.cardStyle()
```

### Custom Padding

```swift
Text("Compact card")
    .cardStyle(padding: Spacing.sm)
```

## Real-World Examples

### Cue Card (HomeView)

```swift
Text(cue.content.title)
    .font(.headline)
    .foregroundColor(AppColors.textPrimary)
    .multilineTextAlignment(.leading)
    .lineLimit(3)
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(height: 22 * 3.5, alignment: .topLeading)
    .cardStyle()
```

### Recording Card (RecordingHistoryCardView)

```swift
VStack(alignment: .leading, spacing: Spacing.md) {
    Text(recording.cue.content.title)
        .font(Typography.body.weight(.medium))
    
    HStack {
        Badge(text: formattedDate, icon: "calendar")
        Spacer()
        Badge(text: formattedDuration, icon: "clock")
    }
}
.frame(maxWidth: .infinity, alignment: .leading)
.cardStyle()
```

### Audio Player (AudioPlayerView)

```swift
VStack(spacing: Spacing.md) {
    // Player controls
}
.cardStyle(backgroundColor: AppColors.surfaceLight)
```

## Design Guidelines

### When to Use

✅ **Use Card when:**
- Grouping related information
- Creating visual hierarchy
- Separating distinct content sections
- Making content tappable/interactive

❌ **Don't use Card when:**
- Content doesn't need visual separation
- Building navigation bars or toolbars
- Creating badges or labels
- Content is already in a container

### Visual Hierarchy

Cards create elevation through:
1. Background color distinct from page background
2. Rounded corners for softness
3. Padding for breathing room

### Spacing

- Cards should have external margin from edges: `Spacing.md` (16pt)
- Multiple cards should be separated by: `Spacing.md` (16pt)
- Card internal padding defaults to: `Spacing.md` (16pt)

## Accessibility

- Cards automatically inherit accessibility traits from content
- Ensure content has proper labels and hints
- Use semantic grouping for related content
- Support Dynamic Type - text inside cards scales automatically

## Color Variants

### Standard Card
```swift
.cardStyle() // Uses AppColors.cardBackground (darkBeige)
```

### Light Card
```swift
.cardStyle(backgroundColor: AppColors.surfaceLight) // beige
```

### Custom Card
```swift
.cardStyle(backgroundColor: AppColors.blue.opacity(0.25))
```

## Common Patterns

### Card with Header and Body

```swift
Card {
    VStack(alignment: .leading, spacing: Spacing.md) {
        // Header
        Text("Title")
            .font(Typography.headingMedium)
        
        // Divider
        Divider()
        
        // Body
        Text("Content goes here")
            .font(Typography.body)
    }
}
```

### Interactive Card

```swift
Button(action: { /* navigate */ }) {
    Card {
        HStack {
            Text("Tap me")
            Spacer()
            Image(systemName: "chevron.right")
        }
    }
}
.buttonStyle(.plain) // Prevents default button styling
```

### Card List

```swift
ScrollView {
    LazyVStack(spacing: Spacing.md) {
        ForEach(items) { item in
            Card {
                Text(item.title)
            }
        }
    }
    .padding(.horizontal, Spacing.md)
}
```

## Do's and Don'ts

### ✅ DO

- Use default values when possible
- Apply consistent spacing between cards
- Keep card content focused
- Use semantic background colors

### ❌ DON'T

- Nest cards inside cards (creates too much elevation)
- Override corner radius without good reason
- Use cards for single-line text
- Apply shadows manually (not part of design system)

## Related Components

- **Badge** - Use inside cards for metadata
- **EmptyState** - Use instead of empty cards
- **FormTextField** - Can be used inside cards for forms

## Migration Notes

### Before (Inline Styling)

```swift
VStack {
    Text("Content")
}
.padding()
.background(AppColors.darkBeige)
.cornerRadius(12)
```

### After (Card Component)

```swift
Card {
    Text("Content")
}
```

## File Location

`UI/Components/Card.swift`

## Version History

- **v1.0** - Initial implementation with basic card and `.cardStyle()` modifier

