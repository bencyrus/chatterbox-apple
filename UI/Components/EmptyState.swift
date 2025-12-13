import SwiftUI

/// A reusable empty state component for displaying when no content is available.
///
/// Usage:
/// ```swift
/// EmptyState(
///     icon: "tray",
///     title: "No items",
///     message: "Your items will appear here"
/// )
///
/// EmptyState(
///     icon: "exclamationmark.triangle",
///     title: "No results",
///     actionTitle: "Try Again",
///     action: { retry() }
/// )
/// ```
struct EmptyState: View {
    let icon: String
    let title: String
    let message: String?
    var action: (() -> Void)?
    var actionTitle: String?
    
    init(
        icon: String,
        title: String,
        message: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppColors.textPrimary.opacity(0.3))
            
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(Typography.headingMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                if let message {
                    Text(message)
                        .font(Typography.body)
                        .foregroundColor(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
            }
            
            if let action, let actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

