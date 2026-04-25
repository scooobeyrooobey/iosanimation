import SwiftUI

struct HomeView: View {
    let expeditions: [Expedition]
    var namespace: Namespace.ID
    /// ID of the expedition whose detail is currently open (if any). While
    /// non-nil, we render `Color.clear` of the card's exact footprint in its
    /// slot instead of the card — this removes the matched-geometry source
    /// view from the hierarchy at the same moment the detail overlay inserts
    /// its matching destination, which is what lets SwiftUI interpolate the
    /// frame (swiftui-lab hero pattern).
    var selectedExpID: Expedition.ID? = nil
    var onCardTap: (Expedition) -> Void

    @State private var scrolledID: Expedition.ID?
    @State private var filterID: String? = "Expeditions"
    private let filters = ["All", "1 Day", "1+ Day", "Expeditions"]

    /// Stored so the vertical scroll can snap to it on first appear — SwiftUI's
    /// `.scrollPosition(id:)` doesn't reliably honour its initial @State value
    /// during the first layout pass (same pattern as the filters row below).
    private let initialID: Expedition.ID

    /// True when the currently centered card is the Northern Lights
    /// expedition (marked via `hasAuroraBackdrop`). Drives the screen-wide
    /// aurora backdrop fade in/out.
    private var auroraActive: Bool {
        expeditions.first(where: { $0.id == scrolledID })?.hasAuroraBackdrop == true
    }

    init(expeditions: [Expedition],
         initialID: Expedition.ID,
         namespace: Namespace.ID,
         selectedExpID: Expedition.ID? = nil,
         onCardTap: @escaping (Expedition) -> Void) {
        self.expeditions = expeditions
        self.initialID = initialID
        self.namespace = namespace
        self.selectedExpID = selectedExpID
        self.onCardTap = onCardTap
        self._scrolledID = State(initialValue: initialID)
    }

    var body: some View {
        GeometryReader { geo in
            let inset = max(0, (geo.size.height - Metrics.cardHeight) / 2)
            // Vertical nudge — selected card sits 70pt below screen midline.
            // Implemented via asymmetric content margins + anchor (instead of
            // `.offset(y:)`) so the last card can ALSO scroll to the same
            // anchor position; otherwise scrollMax clamps it to the geometric
            // centre and the nudge gets lost on the bottom edge.
            let nudge: CGFloat = 70
            let cardAnchor = UnitPoint(x: 0.5, y: 0.5 + nudge / geo.size.height)

            ZStack(alignment: .top) {
                LinearGradient(colors: [AppColor.homeBGTop, AppColor.homeBGBottom],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                // Scroll fills the whole screen — card snaps to anchor below
                // midline, neighbours peek above / below the overlays. The
                // top/bottom bars are drawn ABOVE the scroll, masking the
                // peek with their gradient fades.
                ScrollView(.vertical, showsIndicators: false) {
                    // Eager VStack (3 items total) — LazyVStack would defer
                    // rendering of the Northern Lights card until it scrolls
                    // into view, which made `.scrollPosition(id:)` fail to
                    // snap to the initial @State value on launch.
                    VStack(spacing: 24) {
                        ForEach(expeditions) { exp in
                            // swiftui-lab hero pattern: replace the source card
                            // with an invisible placeholder of identical size
                            // while the detail overlay is open. This removes
                            // the matchedGeometry source from the hierarchy
                            // so SwiftUI has exactly one source→destination
                            // pair to interpolate.
                            if exp.id == selectedExpID {
                                Color.clear
                                    .frame(width: Metrics.cardWidth,
                                           height: Metrics.cardHeight)
                            } else {
                                cardView(exp)
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.top, inset + nudge, for: .scrollContent)
                .contentMargins(.bottom, max(0, inset - nudge), for: .scrollContent)
                // alwaysByOne — один жест = одна карточка, без проскоков и
                // без "тягучего" скролла мимо нескольких ячеек.
                .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
                .scrollPosition(id: $scrolledID, anchor: cardAnchor)
                .task {
                    // SwiftUI `.scrollPosition(id:)` doesn't reliably snap to
                    // the initial @State value on first layout. We wait one
                    // run-loop for the ScrollView to settle, then toggle
                    // scrolledID through nil so the re-assignment isn't a
                    // no-op and SwiftUI re-applies the anchor position.
                    try? await Task.sleep(for: .milliseconds(200))
                    scrolledID = nil
                    try? await Task.sleep(for: .milliseconds(16))
                    scrolledID = initialID
                }

                // Aurora sky — screen-wide backdrop, visible only when the
                // Northern Lights expedition is the centered card. Sits
                // ABOVE the scroll (so bands read across full width, incl.
                // over the card and around it via the shader's transparent
                // gaps) but BELOW the top bar (filter chips stay readable).
                // Top-aligned VStack + Spacer caps the vertical coverage to
                // ~55% of screen height, matching the marked reference area.
                VStack(spacing: 0) {
                    // Wrap aurora in a Color.clear container sized to the
                    // screen so the ZStack / ScrollView don't inherit the
                    // oversized width. The overlay itself may extend 40pt
                    // past each edge without affecting parent layout.
                    Color.clear
                        .frame(height: geo.size.height * 0.55)
                        .overlay {
                            AuroraSkyView()
                                .frame(width: geo.size.width + 80)
                                .offset(x: -40, y: -20)
                        }
                    Spacer(minLength: 0)
                }
                .allowsHitTesting(false)
                .opacity(auroraActive ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: scrolledID)

                // Top bar (status bar zone + navigation) — pinned to top, ignores top safe area
                topBar(safeTop: geo.safeAreaInsets.top)
                    .frame(maxWidth: .infinity, alignment: .top)

            }
            .ignoresSafeArea(.container, edges: .top)
        }
    }

    @ViewBuilder
    private func cardView(_ exp: Expedition) -> some View {
        let isSelected = exp.id == scrolledID

        // Matched-geometry source for the hero morph. Only the selected card
        // has matched IDs — when the user taps, HomeView replaces THIS card
        // with Color.clear in the same transaction that inserts CardScreenView
        // (see the ForEach above). isSource stays `true` here because the
        // source being "removed from hierarchy" is what drives the pairing.
        ExpeditionCard(
            expedition: exp,
            isSelected: isSelected,
            namespace: isSelected ? namespace : nil,
            heroIsSource: true,
            applyLens: isSelected
        )
        .matchedGeometryEffect(
            id: "card-\(exp.id.uuidString)-bg",
            in: namespace,
            isSource: true
        )
        .scrollTransition(axis: .vertical) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.8)
                .scaleEffect(phase.isIdentity ? 1 : 0.94)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelected {
                onCardTap(exp)
            } else {
                withAnimation(.spring(duration: 0.45, bounce: 0.15)) {
                    scrolledID = exp.id
                }
            }
        }
    }

    // Top - Fixed (status bar + Navigation 90pt). Gradient solid at top → transparent at bottom.
    // LOCKED: spacer height and navigationRow Y are finalised — do not tweak without user request.
    private func topBar(safeTop: CGFloat) -> some View {
        VStack(alignment: .center, spacing: 0) {
            Color.clear.frame(height: safeTop + 35)
            navigationRow
                .frame(height: 90)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.12, green: 0.18, blue: 0.11).opacity(0), location: 0.00),
                    Gradient.Stop(color: Color(red: 0.09, green: 0.17, blue: 0.10).opacity(0.78), location: 0.63),
                ],
                startPoint: UnitPoint(x: 0.5, y: 1),
                endPoint: UnitPoint(x: 0.5, y: 0)
            )
        )
    }

    private var navigationRow: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    GlassGroup {
                        HStack(spacing: 8) {
                            ForEach(filters, id: \.self) { f in
                                LiquidGlassButton(style: filterID == f ? .accent : .text) {
                                    withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                                        filterID = f
                                        proxy.scrollTo(f, anchor: .center)
                                    }
                                } content: {
                                    Text(f)
                                }
                                .id(f)
                            }
                        }
                        .scrollTargetLayout()
                    }
                }
                .contentMargins(.horizontal, geo.size.width / 2, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $filterID, anchor: .center)
                .scrollClipDisabled()
                .onAppear {
                    // SwiftUI .scrollPosition doesn't reliably honour its initial
                    // @State value — snap to the selected chip explicitly.
                    if let id = filterID {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }
}
