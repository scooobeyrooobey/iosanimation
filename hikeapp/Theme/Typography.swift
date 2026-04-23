import SwiftUI

// Custom title font: EightiesComeback Extra Condensed.
// Font file must be added to the bundle and registered in Info.plist (UIAppFonts).
// Until the font is provided, we fall back to "NewYork-Black" (SF Compact Rounded not suitable).
enum AppFont {
    /// PostScript name of the bundled OTF — see `Resources/Fonts/EightiesComeback-ExtraCond.otf`.
    static let titleFamily = "EightiesComeback-ExtraCond"
    static let titleFallback = "NewYorkLarge-Black"
}

extension Font {
    /// Card title on Home screen (32pt / 34 lineHeight)
    static func cardTitle() -> Font {
        .custom(AppFont.titleFamily, size: 32, relativeTo: .title)
    }
    /// Card Screen hero title (44pt / 46 lineHeight)
    static func heroTitle() -> Font {
        .custom(AppFont.titleFamily, size: 44, relativeTo: .largeTitle)
    }
    /// SF Pro body (14pt)
    static func bodyS() -> Font { .system(size: 14, weight: .regular) }
    /// SF Pro meta (16pt)
    static func metaM() -> Font { .system(size: 16, weight: .regular) }
    /// SF Pro button label (16pt semibold)
    static func buttonLabel() -> Font { .system(size: 16, weight: .semibold) }
    /// Tab bar label (10pt semibold)
    static func tabLabel() -> Font { .system(size: 10, weight: .semibold) }
}
