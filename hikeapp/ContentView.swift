//
//  ContentView.swift
//  hikeapp
//
//  Hero transition architecture — based on swiftui-lab's reference
//  implementation (https://swiftui-lab.com/matchedgeometryeffect-part1/).
//
//  The canonical rules we follow:
//  1. HomeView is ALWAYS in the hierarchy (zIndex 1).
//  2. The selected card inside HomeView is REPLACED by Color.clear of the
//     same size while the detail is open — this removes the matched-geometry
//     source from the hierarchy in the same `withAnimation` transaction that
//     inserts the detail, so SwiftUI can interpolate frames between them.
//     A visible source + visible destination would be "multiple sources →
//     results undefined" per Apple's docs.
//  3. CardScreenView is wrapped in `Color.clear.overlay(…)` on zIndex 3 so
//     matchedGeometryEffect can drive its position without fighting layout.
//  4. Transition is an explicit `.opacity` — NOT `.identity`. `.identity`
//     disables the insert/remove transition mechanism that hero depends on.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedExp: Expedition?
    @State private var tab: AppTab = .explore
    @Namespace private var heroNS
    @State private var dropCoordinator = BookmarkDropCoordinator()

    private let expeditions: [Expedition] = Expedition.samples

    var body: some View {
        ZStack {
            HomeView(
                expeditions: expeditions,
                initialID: expeditions[1].id,
                namespace: heroNS,
                selectedExpID: selectedExp?.id,
                onCardTap: { exp in
                    withAnimation(HeroTransition.spring) {
                        selectedExp = exp
                    }
                }
            )
            .zIndex(1)

            if let exp = selectedExp {
                CardScreenView(
                    expedition: exp,
                    namespace: heroNS,
                    onBack: {
                        withAnimation(HeroTransition.spring) {
                            selectedExp = nil
                        }
                    }
                )
                .zIndex(3)
                // Explicit .opacity transition — NOT .identity. Without an
                // explicit transition, the default fade still runs; with
                // .identity, SwiftUI skips the insertion transaction that
                // matchedGeometryEffect depends on.
                .transition(.opacity)
            }

            // Bookmark drop overlay — sandwiched between the card (zIndex 3)
            // and the tab bar (zIndex 4). The tab bar on top means the drop
            // visually "enters" the glass capsule at landing rather than
            // sitting on top of it.
            BookmarkDrop()
                .allowsHitTesting(false)
                .zIndex(3.5)

            // Persistent tab bar — its GlassEffectContainer lives outside the
            // hero layers so we don't rebuild it during the morph.
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                TabBarView(selected: $tab)
            }
            .zIndex(4)
        }
        .coordinateSpace(name: "root")
        .environment(dropCoordinator)
        .onPreferenceChange(BookmarkAnchorKey.self) { point in
            Task { @MainActor in dropCoordinator.bookmarkAnchor = point }
        }
        .onPreferenceChange(ProfileTabAnchorKey.self) { point in
            Task { @MainActor in dropCoordinator.profileAnchor = point }
        }
    }
}

#Preview {
    ContentView()
}
