import SwiftUI

/// Squash & stretch bounce applied to the Profile tab icon when the drop
/// lands — anchored at the bottom of the icon so the impact reads as water
/// slapping into the tab-bar glass.
///
/// Driven by `BookmarkDropCoordinator.flight` + a `TimelineView(.animation)`
/// tick. During the splash phase we key through three sub-beats:
/// 1. Impact squash  (tall → short, wide)
/// 2. Bounce back    (short → overshoot tall)
/// 3. Settle         (overshoot → rest)
struct ProfileTabSplash: ViewModifier {
    @Environment(BookmarkDropCoordinator.self) private var coordinator

    func body(content: Content) -> some View {
        TimelineView(.animation) { ctx in
            let (sx, sy) = scale(at: ctx.date)
            content
                .scaleEffect(x: sx, y: sy, anchor: .bottom)
        }
    }

    private func scale(at now: Date) -> (CGFloat, CGFloat) {
        guard let flight = coordinator.flight else { return (1, 1) }
        let elapsed = now.timeIntervalSince(flight.startedAt)
        let (phase, localT) = DropTiming.phase(at: elapsed)
        guard phase == .splash else { return (1, 1) }

        let t = CGFloat(localT)
        if t < 0.22 {
            // Impact squash — drops to 20% height, spreads to 1.90× wide.
            let k = CGFloat(DropEase.smooth(Double(t / 0.22)))
            return (1 + 0.90 * k, 1 - 0.80 * k)
        } else if t < 0.58 {
            // Bounce back — tall overshoot at 1.55× height.
            let k = CGFloat(DropEase.smooth(Double((t - 0.22) / 0.36)))
            return (1.90 - 1.25 * k, 0.20 + 1.35 * k)
        } else {
            // Settle to rest.
            let k = CGFloat(DropEase.smooth(Double((t - 0.58) / 0.42)))
            return (0.65 + 0.35 * k, 1.55 - 0.55 * k)
        }
    }
}

extension View {
    /// Attach the splash-bounce to a view (typically the Profile tab icon).
    func profileTabSplash() -> some View {
        modifier(ProfileTabSplash())
    }
}
