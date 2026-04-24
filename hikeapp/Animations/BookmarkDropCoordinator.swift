import SwiftUI
import Observation

/// Cross-screen coordinator for the bookmark-drop flight.
///
/// Lives on `ContentView` (above both the card and the tab bar) because the
/// flight visually crosses layer boundaries — birth on the card (zIndex 3),
/// landing on the tab bar (zIndex 4). Anchors are reported from each end via
/// `PreferenceKey`, and the flight itself is rendered in a dedicated overlay
/// sandwiched between the two (zIndex 3.5).
@Observable
@MainActor
final class BookmarkDropCoordinator {
    struct Flight: Identifiable, Equatable {
        let id: UUID
        let source: CGPoint
        let target: CGPoint
        let startedAt: Date
    }

    /// Current in-flight animation, or nil when idle.
    var flight: Flight?

    /// Bookmark button centre, in the root coordinate space.
    /// Updated by the button's preference report — see `BookmarkAnchorKey`.
    var bookmarkAnchor: CGPoint = .zero

    /// Profile tab icon centre, in the root coordinate space.
    var profileAnchor: CGPoint = .zero

    var isAnimating: Bool { flight != nil }

    /// Starts the flight if idle and anchors are known. Calls `onLand` at the
    /// moment the splash begins — that's when the bookmark icon should flip
    /// to the filled state in the card screen.
    /// Returns `true` if a flight was started, `false` if the trigger was
    /// ignored (mid-flight tap, or anchors not yet reported).
    @discardableResult
    func trigger(onLand: @escaping @MainActor () -> Void) -> Bool {
        guard flight == nil else { return false }
        guard bookmarkAnchor != .zero, profileAnchor != .zero else { return false }

        let newFlight = Flight(
            id: UUID(),
            source: bookmarkAnchor,
            target: profileAnchor,
            startedAt: .now
        )
        flight = newFlight

        let markDelay = DropTiming.birth + DropTiming.rise + DropTiming.hover + DropTiming.fall
        let clearDelay = DropTiming.total + 0.05

        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(markDelay * 1_000_000_000))
            guard self?.flight?.id == newFlight.id else { return }
            onLand()

            let remaining = clearDelay - markDelay
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            guard self?.flight?.id == newFlight.id else { return }
            self?.flight = nil
        }
        return true
    }
}

// MARK: - Preference keys for anchor reporting

struct BookmarkAnchorKey: PreferenceKey {
    static let defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

struct ProfileTabAnchorKey: PreferenceKey {
    static let defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

extension View {
    /// Report this view's centre in the `"root"` coordinate space via the
    /// given preference key. Attach to the bookmark button or profile tab icon.
    func reportAnchor<Key: PreferenceKey>(_ key: Key.Type) -> some View where Key.Value == CGPoint {
        background(
            GeometryReader { proxy in
                let frame = proxy.frame(in: .named("root"))
                Color.clear
                    .preference(key: Key.self, value: CGPoint(x: frame.midX, y: frame.midY))
            }
        )
    }
}
