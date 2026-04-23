import SwiftUI

struct ExpeditionCard: View {
    let expedition: Expedition
    var isSelected: Bool = true
    var namespace: Namespace.ID? = nil
    /// When false, internal matched-geometry entries register as non-source
    /// so CardScreenView can own the hero-morph geometry without collision.
    var heroIsSource: Bool = true
    /// Currently unused — chromatic rim refraction now lives in
    /// `CardGlowView` as a sibling overlay because `.layerEffect`
    /// cannot rasterise UIViewRepresentable content (TightTitleLabel).
    var applyLens: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            ImageTrio(expedition: expedition,
                      progress: 0,
                      namespace: namespace,
                      geoIdPrefix: "home-\(expedition.id.uuidString)",
                      heroIsSource: heroIsSource)
                .padding(.top, Metrics.cardTopPadding)

            VStack(spacing: 16) {
                // Title renders at native 44pt so matchedGeometry owns the
                // same intrinsic frame on both Home and Card Screen — a single
                // scaleEffect gives the visual 32pt on Home without a second
                // competing transform during the morph.
                // frame(height: 68) reserves the scaled layout bounds
                // (34pt × 2 lines) — scaleEffect itself does not shrink bounds.
                // NOTE: tuned for 2-line titles; single-line strings would need
                // a dynamic height.
                titleView
                    .fixedSize(horizontal: false, vertical: true)
                    .scaleEffect(32.0 / 44.0, anchor: .top)
                    .frame(height: 68, alignment: .top)
                    .shadow(color: Color(hex: 0xF0D5C2).opacity(0.5), radius: 50)
                    .matched(namespace, "text-title-\(expedition.id.uuidString)", isSource: heroIsSource)

                Text(expedition.meta)
                    .font(.metaM())
                    .foregroundStyle(AppColor.textWhite.opacity(0.5))
                    .tracking(-0.5)
                    .matched(namespace, "text-meta-\(expedition.id.uuidString)", isSource: heroIsSource)

                DifficultyDots(level: expedition.difficulty)
                    .matched(namespace, "text-dots-\(expedition.id.uuidString)", isSource: heroIsSource)

                Text(expedition.shortDescription)
                    .font(.bodyS())
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(AppColor.textWhite)
                    .frame(width: Metrics.shortDescWidth)
                    .matched(namespace, "text-desc-\(expedition.id.uuidString)", isSource: heroIsSource)
            }
            .padding(.horizontal, Metrics.cardTextHPadding)
            .padding(.bottom, Metrics.cardBottomPadding)
        }
        .frame(width: Metrics.cardWidth, height: Metrics.cardHeight)
        .background(
            LinearGradient(colors: [AppColor.cardBGTop, AppColor.cardBGBottom],
                           startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous))
        .glassEffect(
            .regular.tint(AppColor.cardBGBottom.opacity(0.35)),
            in: RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous)
        )
        .shadow(color: .black.opacity(0.45), radius: 24, y: 18)
    }

    private var titleView: some View {
        TightTitleLabel(
            text: expedition.title,
            fontName: AppFont.titleFamily,
            fontSize: 44,
            lineHeight: 46,
            color: AppColor.textWhite,
            numberOfLines: 2,
            maxWidth: Metrics.titleMaxWidth
        )
    }
}

private extension View {
    /// Apply matchedGeometryEffect only when a namespace is provided.
    @ViewBuilder
    func matched(_ namespace: Namespace.ID?, _ id: String, isSource: Bool = true) -> some View {
        if let ns = namespace {
            self.matchedGeometryEffect(id: id, in: ns, isSource: isSource)
        } else {
            self
        }
    }
}

