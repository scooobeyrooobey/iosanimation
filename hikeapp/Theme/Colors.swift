import SwiftUI

enum AppColor {
    static let homeBGTop    = Color(hex: 0x152716)
    static let homeBGBottom = Color(hex: 0x060C06)

    static let cardBGTop    = Color(hex: 0x233D20)
    static let cardBGBottom = Color(hex: 0x0A1208)

    static let bottomPanel  = Color(hex: 0x0C0C0C)

    static let textWhite    = Color(hex: 0xF4E1D3)
    static let textBlack    = Color(hex: 0x0C1F09)

    static let accent       = Color(hex: 0x5FF453)
    static let accentAlt    = Color(hex: 0x59F34F)

    // Card border glow
    static let glowTeal     = Color(hex: 0x18DE9B)
    static let glowCyan     = Color(hex: 0x1DB6D5)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
