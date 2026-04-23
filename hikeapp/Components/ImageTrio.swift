import SwiftUI

/// Three tilted photos that compose the card's hero area.
/// `progress`: 0 = Home card size, 1 = Card Screen (enlarged) size.
struct ImageTrio: View {
    let expedition: Expedition
    /// 0...1 morph between Home and Card Screen
    var progress: CGFloat = 0
    /// optional matchedGeometry namespace id prefix
    var namespace: Namespace.ID? = nil
    var geoIdPrefix: String = ""
    var heroIsSource: Bool = true

    private func size(_ home: CGFloat, _ card: CGFloat) -> CGFloat {
        home + (card - home) * progress
    }

    // Home offsets — Figma node 11:2304.
    private let leftOffsetHome   = CGSize(width: -203.59, height: -31.10)
    private let rightOffsetHome  = CGSize(width:  199.09, height:  38.56)
    private let centerOffset     = CGSize(width:    -0.15, height:  -5.70)

    // Card Screen offsets — wider spread so there is a visible green gap between
    // the centre card (240.9 pt wide) and each side card (~179 pt wide).
    // At progress = 1: gap ≈ |offset| − (center_half + side_half) = 230 − (120+89) = 21 pt.
    // Offsets scaled 0.85× along with CardImg sizes.
    private let leftOffsetCard   = CGSize(width: -209, height: -31.10)
    private let rightOffsetCard  = CGSize(width:  209, height:  38.56)

    // Interpolate between home and card-screen offsets the same way sizes are interpolated.
    private var leftOffset:  CGSize { interp(leftOffsetHome,  leftOffsetCard)  }
    private var rightOffset: CGSize { interp(rightOffsetHome, rightOffsetCard) }

    private func interp(_ a: CGSize, _ b: CGSize) -> CGSize {
        CGSize(width:  a.width  + (b.width  - a.width)  * progress,
               height: a.height + (b.height - a.height) * progress)
    }

    var body: some View {
        ZStack {
            // Left image (img3) — tilted -19.44°
            tilted(expedition.sideImageLeft,
                   size: size(Metrics.HomeImg.size3, Metrics.CardImg.size3),
                   rotation: Metrics.HomeImg.rot3,
                   id: "img3")
                .offset(leftOffset)

            // Right image (img2) — tilted +11.25°
            tilted(expedition.sideImageRight,
                   size: size(Metrics.HomeImg.size2, Metrics.CardImg.size2),
                   rotation: Metrics.HomeImg.rot2,
                   id: "img2")
                .offset(rightOffset)

            // Center image (img1) — tilted -3.22°
            tilted(expedition.heroImage,
                   size: size(Metrics.HomeImg.size1, Metrics.CardImg.size1),
                   rotation: Metrics.HomeImg.rot1,
                   id: "img1")
                .offset(centerOffset)
        }
        .frame(height: Metrics.cardContentImageHeight)
    }

    @ViewBuilder
    private func tilted(_ name: String, size s: CGFloat, rotation: Double, id: String) -> some View {
        let img = Image(name)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: s, height: s)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    .blur(radius: 0.5)
            )
            .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
            .rotationEffect(.degrees(rotation))

        if let ns = namespace {
            img.matchedGeometryEffect(id: "\(geoIdPrefix)-\(id)", in: ns, isSource: heroIsSource)
        } else {
            img
        }
    }
}
