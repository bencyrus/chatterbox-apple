import SwiftUI

/// A reusable card container with consistent styling.
///
/// Usage:
/// ```swift
/// Card {
///     Text("Content")
/// }
/// ```
///
/// Or use the convenience modifier:
/// ```swift
/// Text("Content")
///     .cardStyle()
/// ```
struct Card<Content: View>: View {
    let content: Content
    var backgroundColor: Color = AppColors.cardBackground
    var padding: CGFloat = Spacing.md
    var cornerRadius: CGFloat = 12
    
    init(
        backgroundColor: Color = AppColors.cardBackground,
        padding: CGFloat = Spacing.md,
        cornerRadius: CGFloat = 12,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
    }
}

// MARK: - View Extension

extension View {
    /// Applies card styling to any view.
    ///
    /// - Parameters:
    ///   - backgroundColor: The background color of the card. Defaults to `AppColors.cardBackground`.
    ///   - padding: The internal padding. Defaults to `Spacing.md`.
    ///   - cornerRadius: The corner radius. Defaults to 12.
    /// - Returns: A view styled as a card.
    func cardStyle(
        backgroundColor: Color = AppColors.cardBackground,
        padding: CGFloat = Spacing.md,
        cornerRadius: CGFloat = 12
    ) -> some View {
        Card(backgroundColor: backgroundColor, padding: padding, cornerRadius: cornerRadius) {
            self
        }
    }
}

