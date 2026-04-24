import SwiftUI
import UIKit

struct CardScreenView: View {
    let expedition: Expedition
    var namespace: Namespace.ID
    var onBack: () -> Void

    @Environment(BookmarkDropCoordinator.self) private var dropCoordinator
    @State private var isBookmarked = false
    // Individual controls are staggered independently, so each button owns
    // its own offset/opacity pair.
    @State private var accentOffset: CGFloat = 30
    @State private var accentOpacity: CGFloat = 0
    @State private var iconOffset: CGFloat = 30
    @State private var iconOpacity: CGFloat = 0
    @State private var backOffsetX: CGFloat = 40
    @State private var backOpacity: CGFloat = 0
    @State private var panelOffset: CGFloat = 40
    @State private var panelOpacity: CGFloat = 0

    var body: some View {
        ZStack {
            // isSource: true — when Card Screen mounts, Home's matching view
            // simultaneously flips `heroIsSource` OFF (via isCoveredByCard).
            // Source ownership passes here, and SwiftUI animates the rendered
            // frame from Home's previous source position to this layout.
            LinearGradient(colors: [AppColor.cardBGTop, AppColor.cardBGBottom],
                           startPoint: .top, endPoint: .bottom)
                .matchedGeometryEffect(
                    id: "card-\(expedition.id.uuidString)-bg",
                    in: namespace,
                    isSource: true
                )
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Nav with back button
                GlassGroup {
                    HStack {
                        LiquidGlassButton(style: .icon, action: onBack) {
                            Image("IconArrowBack")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        }
                        .offset(x: backOffsetX)
                        .opacity(backOpacity)
                        Spacer()
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)

                // 16pt below the back bar.
                ImageTrio(expedition: expedition,
                          progress: 1,
                          namespace: namespace,
                          geoIdPrefix: "home-\(expedition.id.uuidString)",
                          heroIsSource: true)
                    .frame(height: 204)
                    .padding(.top, 16)

                textBlock
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                // Bottom panel — scrolls internally; page hero above does not.
                ScrollView(.vertical, showsIndicators: false) {
                    Text(expedition.longDescription)
                        .font(.bodyS())
                        .tracking(-0.5)
                        .foregroundStyle(AppColor.textWhite.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 32)
                        .padding(.top, 32)
                        .padding(.bottom, 160)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColor.bottomPanel)
                .clipShape(.rect(topLeadingRadius: Metrics.bottomPanelCornerRadius,
                                 topTrailingRadius: Metrics.bottomPanelCornerRadius))
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        stops: [
                            .init(color: AppColor.bottomPanel.opacity(0), location: 0.0),
                            .init(color: AppColor.bottomPanel, location: 0.6),
                            .init(color: AppColor.bottomPanel, location: 1.0),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 140)
                    .allowsHitTesting(false)
                }
                .ignoresSafeArea(.container, edges: .bottom)
                .offset(y: panelOffset)
                .opacity(panelOpacity)
            }
        }
        .onAppear { playEnterAnimation() }
    }

    private var textBlock: some View {
        VStack(spacing: 16) {
            VStack(spacing: 16) {
                // No scaleEffect here — ExpeditionCard renders the same 44pt
                // label scaled to 32pt visually, so matchedGeometry morphs a
                // single intrinsic frame on both sides without a competing
                // transform.
                TightTitleLabel(
                    text: expedition.title,
                    fontName: AppFont.titleFamily,
                    fontSize: 44,
                    lineHeight: 46,
                    color: AppColor.textWhite,
                    numberOfLines: 2,
                    // Same maxWidth as ExpeditionCard — line wrapping must be
                    // identical so matched-geometry morph sees the same
                    // intrinsic frame on both sides.
                    maxWidth: Metrics.titleMaxWidth
                )
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: Color(hex: 0xF0D5C2).opacity(0.5), radius: 50)
                .matchedGeometryEffect(
                    id: "text-title-\(expedition.id.uuidString)",
                    in: namespace,
                    isSource: true
                )

                Text(expedition.meta)
                    .font(.metaM())
                    .foregroundStyle(AppColor.textWhite.opacity(0.5))
                    .tracking(-0.5)
                    .matchedGeometryEffect(
                        id: "text-meta-\(expedition.id.uuidString)",
                        in: namespace,
                        isSource: true
                    )

                DifficultyDots(level: expedition.difficulty)
                    .matchedGeometryEffect(
                        id: "text-dots-\(expedition.id.uuidString)",
                        in: namespace,
                        isSource: true
                    )

                Text(expedition.shortDescription)
                    .font(.bodyS())
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(AppColor.textWhite)
                    .frame(width: Metrics.shortDescWidth)
                    .matchedGeometryEffect(
                        id: "text-desc-\(expedition.id.uuidString)",
                        in: namespace,
                        isSource: true
                    )
            }

            GlassGroup {
                HStack(spacing: 16) {
                    LiquidGlassButton(style: .accent, action: {}) {
                        Text("Book now")
                    }
                    .offset(y: accentOffset)
                    .opacity(accentOpacity)

                    LiquidGlassButton(style: .icon, action: handleBookmarkTap) {
                        Image(isBookmarked ? "IconBookmarkCheck" : "IconBookmark")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            // Crossfade with the drop sprite during birth —
                            // without the explicit animation the icon snaps
                            // to zero, which reads as a "pop" right as the
                            // drop begins to emerge.
                            .opacity(dropCoordinator.isAnimating ? 0 : 1)
                            .animation(
                                .easeInOut(duration: 0.2),
                                value: dropCoordinator.isAnimating
                            )
                    }
                    .reportAnchor(BookmarkAnchorKey.self)
                    .offset(y: iconOffset)
                    .opacity(iconOpacity)
                    .disabled(dropCoordinator.isAnimating)
                }
            }
            .padding(.vertical, 12)
        }
    }

    // Bookmark tap handler.
    // - Already bookmarked → instant toggle off (no drop animation for removal).
    // - Not bookmarked → trigger the drop flight; the filled state is set when
    //   the splash begins (coordinator callback), so the icon flips at the
    //   exact moment the drop "arrives" visually.
    // - Mid-flight taps are swallowed by both `.disabled(...)` and the
    //   coordinator's internal guard.
    private func handleBookmarkTap() {
        if isBookmarked {
            isBookmarked = false
            return
        }
        dropCoordinator.trigger {
            withAnimation(.spring(duration: 0.22, bounce: 0.25)) {
                isBookmarked = true
            }
        }
    }

    // Controls/panel/back arrive one after another on top of the main hero
    // morph — all on the shared HeroTransition.spring for a cohesive feel.
    private func playEnterAnimation() {
        withAnimation(HeroTransition.spring.delay(HeroTransition.delayAccent)) {
            accentOpacity = 1
            accentOffset = 0
        }
        withAnimation(HeroTransition.spring.delay(HeroTransition.delayIcon)) {
            iconOpacity = 1
            iconOffset = 0
        }
        withAnimation(HeroTransition.spring.delay(HeroTransition.delayBack)) {
            backOffsetX = 0
            backOpacity = 1
        }
        withAnimation(HeroTransition.spring.delay(HeroTransition.delayBottom)) {
            panelOpacity = 1
            panelOffset = 0
        }
    }
}
