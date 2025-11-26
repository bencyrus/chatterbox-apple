import SwiftUI

/// App-wide color palette.
enum AppColors {
    /// Green accent color - used for success indicators.
    static let green = Color(hex: 0xb3cbc0)
    
    /// Darker green accent for status bars / stronger accents.
    static let darkGreen = Color(hex: 0x7fa395)
    
    /// Blue secondary accent color.
    static let blue = Color(hex: 0xbec8e3)
    
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

