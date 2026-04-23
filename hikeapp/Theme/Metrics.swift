import CoreGraphics

enum Metrics {
    // Card geometry (Figma node 11:2304 / 11:2306)
    static let cardWidth: CGFloat = 329
    static let cardHeight: CGFloat = 510
    static let cardCornerRadius: CGFloat = 24
    static let cardHPadding: CGFloat = 32
    /// Horizontal padding for the text block (title/meta/dots/description).
    /// 15pt narrower per side than `cardHPadding` → text layer is 30pt wider
    /// than the outer card padding. Used on both Home card and Card Screen so
    /// matched-geometry sees identical intrinsic frames on both sides.
    static let cardTextHPadding: CGFloat = 17
    /// Title's native 44pt wrap bucket — scaled to 32pt visually on Home.
    /// Intentionally based on `cardHPadding` (32), NOT `cardTextHPadding` (17):
    /// the text block is widened so longer descriptions breathe, but the title
    /// must keep its original wrap so short titles ("Patagonia Glacier") still
    /// break into two lines and the card keeps a consistent vertical rhythm.
    static let titleMaxWidth: CGFloat = (cardWidth - 2 * cardHPadding) * (44.0 / 32.0)
    /// Short-description frame width (same on Home card + Card Screen).
    static let shortDescWidth: CGFloat = 267
    static let cardTopPadding: CGFloat = 16
    static let cardBottomPadding: CGFloat = 32
    static let cardContentImageHeight: CGFloat = 266

    // Image stack — Home card
    enum HomeImg {
        static let size1: CGFloat = 186.5   // center img
        static let size2: CGFloat = 160.3   // right img
        static let size3: CGFloat = 159.8   // left img
        static let rot1: Double = -3.22
        static let rot2: Double = 11.25
        static let rot3: Double = -19.44
    }

    // Image stack — Card Screen (larger). Scaled down 15% from the original
    // Figma spec so more vertical space goes to the scrolling bottom panel.
    enum CardImg {
        static let size1: CGFloat = 204.8   // 240.9 × 0.85
        static let size2: CGFloat = 152.2   // 179   × 0.85
        static let size3: CGFloat = 151.6   // 178.4 × 0.85
    }

    // Buttons
    static let buttonPillVPadding: CGFloat = 6
    static let buttonPillHPadding: CGFloat = 20
    static let iconButtonSize: CGFloat = 48
    static let buttonCornerRadius: CGFloat = 1000

    // Bottom panel
    static let bottomPanelCornerRadius: CGFloat = 32
    static let bottomPanelPadding: CGFloat = 32

    // Tab bar
    static let tabWidth: CGFloat = 91
    static let tabBarBottomInset: CGFloat = 0
    static let tabBarTopInset: CGFloat = 48
}
