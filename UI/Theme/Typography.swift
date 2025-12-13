import SwiftUI

enum Typography {
    // MARK: - Display
    
    /// Display large - for app branding and large titles.
    static let displayLarge = Font.system(.largeTitle, weight: .bold)
    
    /// Display medium - for section titles.
    static let displayMedium = Font.system(.title, weight: .bold)
    
    // MARK: - Headings
    
    /// Heading large - primary content headings.
    static let headingLarge = Font.system(.title2, weight: .bold)
    
    /// Heading medium - subsection headings.
    static let headingMedium = Font.system(.title3, weight: .semibold)
    
    /// Heading small - card titles and small headings.
    static let headingSmall = Font.system(.headline, weight: .semibold)
    
    // MARK: - Body (Keep existing)
    
    /// Body - standard text.
    static let body = Font.body
    
    /// Body medium - slightly smaller body text.
    static let bodyMedium = Font.system(.callout, weight: .regular)
    
    // MARK: - Labels
    
    /// Label large - prominent labels.
    static let labelLarge = Font.system(.subheadline, weight: .medium)
    
    /// Label medium - standard labels.
    static let labelMedium = Font.system(.caption, weight: .medium)
    
    /// Label small - minimal labels.
    static let labelSmall = Font.system(.caption2, weight: .medium)
    
    // MARK: - Supporting Text
    
    /// Caption - secondary information.
    static let caption = Font.caption
    
    /// Footnote - fine print.
    static let footnote = Font.footnote
    
    // MARK: - Specialty
    
    /// Monospaced timer - for recording timers.
    static let monospacedTimer = Font.system(size: 36, weight: .medium, design: .monospaced)
    
    /// Monospaced code - for debug/code display.
    static let monospacedCode = Font.system(.body, design: .monospaced)
    
    // MARK: - Legacy (deprecated, use new names)
    
    @available(*, deprecated, message: "Use displayMedium instead")
    static let title = Font.system(.title, weight: .bold)
    
    @available(*, deprecated, message: "Use headingLarge instead")
    static let heading = Font.system(.title2, weight: .bold)
}


