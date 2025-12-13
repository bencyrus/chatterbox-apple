# Badge Component

## Overview

The Badge component displays small pieces of information like dates, counts, or status indicators with optional icons.

## API Reference

### Badge

```swift
struct Badge: View {
    init(
        text: String,
        icon: String? = nil,
        backgroundColor: Color = AppColors.badgeBackground,
        foregroundColor: Color = AppColors.textPrimary
    )
}
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `text` | `String` | Required | Text to display in badge |
| `icon` | `String?` | `nil` | Optional SF Symbol name |
| `backgroundColor` | `Color` | `AppColors.badgeBackground` | Badge background color |
| `foregroundColor` | `Color` | `AppColors.textPrimary` | Text and icon color |

### View Extension

```swift
extension View {
    func badgeStyle(
        backgroundColor: Color = AppColors.badgeBackground,
        foregroundColor: Color = AppColors.textPrimary
    ) -> some View
}
```

## Usage Examples

### Basic Badge

```swift
Badge(text: "New")
```

### Badge with Icon

```swift
Badge(text: "Today", icon: "calendar")
```

### Colored Badge

```swift
Badge(
    text: "5",
    backgroundColor: AppColors.green
)
```

### Status Badge

```swift
Badge(
    text: "Error",
    icon: "exclamationmark.triangle",
    backgroundColor: AppColors.errorBackground,
    foregroundColor: AppColors.textContrast
)
```

## Real-World Examples

### Date Badge (HistoryView)

```swift
Badge(
    text: formatGroupDate(group.date),
    icon: "calendar"
)
```

### Count Badge

```swift
Badge(
    text: "\(group.recordings.count)",
    backgroundColor: AppColors.green
)
```

### Metadata Badges (RecordingHistoryCardView)

```swift
HStack(spacing: Spacing.md) {
    Badge(
        text: formattedDate,
        icon: "calendar",
        backgroundColor: AppColors.divider,
        foregroundColor: AppColors.textQuaternary
    )
    
    Spacer()
    
    Badge(
        text: formattedDuration,
        icon: "clock",
        backgroundColor: AppColors.divider,
        foregroundColor: AppColors.textQuaternary
    )
}
```

## Design Guidelines

### When to Use

✅ **Use Badge when:**
- Displaying metadata (dates, times, counts)
- Showing status or category
- Highlighting small pieces of information
- Grouping data with icons

❌ **Don't use Badge when:**
- Displaying primary content
- Text is more than a few words
- Information needs more context
- Building buttons (use Button instead)

### Size Guidelines

- Text should be short (1-10 characters ideal)
- Icons use `.caption2` font size
- Height is auto-calculated based on Typography.labelMedium
- Typical badge height: ~24-28pt

### Color Usage

Choose background colors based on purpose:

| Purpose | Background | Foreground |
|---------|------------|------------|
| Neutral | `badgeBackground` | `textPrimary` |
| Success | `green` | `textPrimary` |
| Metadata | `divider` | `textQuaternary` |
| Error | `errorBackground` | `textContrast` |

## Accessibility

- Badge text is automatically accessible to VoiceOver
- Icon names should be descriptive SF Symbols
- Ensure sufficient contrast (minimum 4.5:1 for small text)
- Don't rely on color alone to convey meaning

## Common Patterns

### Badge Group

```swift
HStack(spacing: Spacing.sm) {
    Badge(text: "Today", icon: "calendar")
    Badge(text: "5", backgroundColor: AppColors.green)
    Spacer()
}
```

### Badge in Card

```swift
Card {
    VStack(alignment: .leading, spacing: Spacing.sm) {
        Text("Title")
            .font(Typography.headingMedium)
        
        HStack {
            Badge(text: "New", backgroundColor: AppColors.blue)
            Badge(text: "3 mins", icon: "clock")
        }
    }
}
```

### Inline Badge

```swift
HStack {
    Text("Recording")
    Badge(text: "Live", backgroundColor: AppColors.recordingRed)
}
```

## Icon Guidelines

### Recommended SF Symbols

- **Time**: `clock`, `timer`, `hourglass`
- **Date**: `calendar`, `calendar.circle`
- **Count**: Numbers without icon
- **Status**: `checkmark.circle`, `xmark.circle`, `exclamationmark.triangle`
- **Category**: `tag`, `folder`, `star`

### Icon Best Practices

✅ **DO:**
- Use clear, recognizable icons
- Keep icon semantically related to text
- Use consistent icons across app

❌ **DON'T:**
- Use decorative-only icons
- Mix icon styles
- Use icons that need explanation

## Do's and Don'ts

### ✅ DO

- Keep text concise
- Use semantic colors
- Group related badges
- Maintain consistent spacing

### ❌ DON'T

- Use for long text (use Card instead)
- Make badges interactive (use Button instead)
- Override typography (uses labelMedium)
- Create custom badge variants (extend component)

## Color Combinations

### Light Background

```swift
// Neutral
Badge(text: "Info", backgroundColor: AppColors.badgeBackground)

// Positive
Badge(text: "Success", backgroundColor: AppColors.green)

// Informational
Badge(text: "Note", backgroundColor: AppColors.blue)
```

### Dark Background (for dark mode, future)

```swift
// Would need: backgroundColor: .white.opacity(0.2)
// Currently not needed (light mode only)
```

## Related Components

- **Card** - Badges often used inside cards
- **EmptyState** - Don't use badges in empty states
- **FormTextField** - Can use badges for hints/status

## Migration Notes

### Before (Inline Styling)

```swift
HStack(spacing: 4) {
    Image(systemName: "calendar")
        .font(.caption2)
    Text("Today")
        .font(.caption.weight(.medium))
}
.foregroundColor(AppColors.textPrimary)
.padding(.horizontal, 10)
.padding(.vertical, 6)
.background(Color.gray.opacity(0.2))
.cornerRadius(6)
```

### After (Badge Component)

```swift
Badge(text: "Today", icon: "calendar")
```

## File Location

`UI/Components/Badge.swift`

## Version History

- **v1.0** - Initial implementation with text, icon, and color customization

