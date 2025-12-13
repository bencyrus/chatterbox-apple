import SwiftUI

/// A reusable badge component for displaying small pieces of information.
///
/// Usage:
/// ```swift
/// Badge(text: "Today")
/// Badge(text: "5", icon: "calendar")
/// Badge(text: "New", backgroundColor: AppColors.green)
/// ```
struct Badge: View {
    let text: String
    var icon: String?
    var backgroundColor: Color = AppColors.badgeBackground
    var foregroundColor: Color = AppColors.textPrimary
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(Typography.labelMedium)
        }
        .foregroundColor(foregroundColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .cornerRadius(6)
    }
}

// MARK: - View Extension

extension View {
    /// Applies badge styling to any view with text.
    ///
    /// - Parameters:
    ///   - backgroundColor: The background color of the badge.
    ///   - foregroundColor: The text/icon color.
    /// - Returns: A view styled as a badge.
    func badgeStyle(
        backgroundColor: Color = AppColors.badgeBackground,
        foregroundColor: Color = AppColors.textPrimary
    ) -> some View {
        self
            .font(Typography.labelMedium)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .cornerRadius(6)
    }
}

