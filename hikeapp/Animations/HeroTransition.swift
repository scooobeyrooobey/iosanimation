import SwiftUI

/// Single source of truth for the Home ↔ Card Screen hero morph.
///
/// Duration + bounce are shared across ContentView (screen swap) and
/// CardScreenView (staggered controls), so both sides move on the same
/// spring and nothing lags behind.
enum HeroTransition {
    /// 0.3 s — matches the requested hero duration. Light bounce so the
    /// settle feels alive without overshoot.
    static let duration: Double = 0.3
    static let bounce:   Double = 0.18

    static var spring: Animation {
        .spring(duration: duration, bounce: bounce)
    }

    // Staggers measured from the start of the main morph — scaled to fit
    // inside the 0.3 s envelope, so everything lands together rather than
    // trailing after the hero has settled.
    static let delayAccent: Double = 0.05  // Book now
    static let delayIcon:   Double = 0.09  // Bookmark
    static let delayBack:   Double = 0.12  // Back arrow (slides right→left)
    static let delayBottom: Double = 0.15  // Long-description panel
}
