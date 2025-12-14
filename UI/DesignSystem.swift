import SwiftUI

/// App-wide color palette.
enum AppColors {
    // MARK: - Brand Colors
    
    /// Green accent color - used for success indicators.
    static let green = Color(hex: 0xb3cbc0)

    /// Darker green accent for status bars / stronger accents.
    static let darkGreen = Color(hex: 0x7fa395)

    /// Blue secondary accent color.
    static let blue = Color(hex: 0xbec8e3)

    /// Darker blue accent for buttons / stronger accents.
    static let darkBlue = Color(hex: 0x8f9bb8)

    /// Beige - used for detail cards and error indicators.
    static let beige = Color(hex: 0xf7e4d6)

    /// Dark Beige - used for cue card backgrounds.
    static let darkBeige = Color(hex: 0xe5d2c4)

    /// Sand - primary app background.
    static let sand = Color(hex: 0xeeeee6)

    /// Page background token (keep aligned with Android `AppColors.PageBackground` / `@color/chatterbox_page_background`).
    /// iOS currently uses `beige.opacity(0.4)` in places like Login.
    static let pageBackground = beige.opacity(0.4)
    
    // MARK: - Recording UI Colors
    
    /// Recording red - primary recording indicator.
    static let recordingRed = Color(hex: 0xE74C3C)
    
    /// Recording red light - delete actions.
    static let recordingRedLight = Color(hex: 0xd98f8f)
    
    /// Recording red dark - text on light recording backgrounds.
    static let recordingRedDark = Color(hex: 0xC0392B)
    
    /// Recording background - pause state background.
    static let recordingBackground = Color(hex: 0xE5C4B8)
    
    // MARK: - System Colors
    
    /// System gray for neutral UI elements.
    static let systemGray = Color(.systemGray3)
    
    // MARK: - Error Colors
    
    /// Error background - destructive actions.
    static let errorBackground = Color(red: 0.7, green: 0.1, blue: 0.1)
    
    // MARK: - Text Colors
    
    /// Primary text color.
    static let textPrimary = Color.black
    
    /// Secondary text color (60% opacity).
    static let textSecondary = Color.black.opacity(0.6)
    
    /// Tertiary text color (70% opacity).
    static let textTertiary = Color.black.opacity(0.7)
    
    /// Quaternary text color (80% opacity).
    static let textQuaternary = Color.black.opacity(0.8)

    /// Contrast text for dark backgrounds.
    static let textContrast = Color.white
    
    // MARK: - Semantic Colors
    
    /// Card background (alias for darkBeige).
    static let cardBackground = darkBeige
    
    /// Surface light (alias for beige).
    static let surfaceLight = beige
    
    /// Input field background.
    static let inputBackground = darkBeige
    
    /// Border color for neutral elements.
    static let borderNeutral = Color.gray.opacity(0.3)
    
    /// Badge background - neutral.
    static let badgeBackground = Color.gray.opacity(0.2)
    
    /// Divider or separator color.
    static let divider = Color.black.opacity(0.1)
    
    /// Overlay background for modals.
    static let overlayBackground = Color.black.opacity(0.4)
    
    /// Shadow color.
    static let shadow = Color.black.opacity(0.15)
}

extension Color {
    /// Initialize a Color from a hex value.
    /// - Parameter hex: The hex color value (e.g., 0xb3cbc0).
    init(hex: UInt) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

// MARK: - Button styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.body.weight(.medium))
            .foregroundColor(AppColors.textContrast)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .background(AppColors.textPrimary)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Rounded primary button for prominent CTAs (e.g. sign-in).
struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.body.weight(.medium))
            .foregroundColor(AppColors.textContrast)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.xl)
            .background(AppColors.textPrimary)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.body.weight(.medium))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.red, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Common Components

struct PageHeader<Actions: View>: View {
    let title: String
    @ViewBuilder let actions: () -> Actions

    init(_ title: String, @ViewBuilder actions: @escaping () -> Actions = { EmptyView() }) {
        self.title = title
        self.actions = actions
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(Typography.headingLarge)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            actions()
        }
        .frame(minHeight: 48)
        .padding(.horizontal)
    }
}

