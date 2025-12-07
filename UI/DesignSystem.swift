import SwiftUI

/// App-wide color palette.
enum AppColors {
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

    /// Primary text color.
    static let textPrimary = Color.black

    /// Contrast text for dark backgrounds.
    static let textContrast = Color.white
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
                .font(Typography.heading)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            actions()
        }
        .frame(minHeight: 48)
        .padding(.horizontal)
    }
}

