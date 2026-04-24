import SwiftUI

/// Procedural aurora sky + stars overlay. Two drifting bands (green + purple)
/// with sparse twinkling stars overhead — rendered by `AuroraSky.metal` via
/// `.layerEffect`. The view is a transparent canvas, so it composes over any
/// background. Non-interactive (`.allowsHitTesting(false)`).
///
/// Designed to sit behind the Northern Lights expedition card in HomeView,
/// but reusable — drop `AuroraSkyView()` into any `ZStack` and frame it.
struct AuroraSkyView: View {
    /// Overall aurora intensity. Scales the per-step colour contribution.
    var amplitude: Float = 1.0

    /// Vertical centre of the green band in normalised UV (0 = top, 1 = bottom).
    var greenBandY: Float = 0.55

    /// Vertical centre of the purple band. Kept above the green band, with
    /// ~0.17 UV separation so the two read as distinct curtains.
    var purpleBandY: Float = 0.38

    /// Green band tint. Default ≈ #29F28D.
    var greenColor: SIMD3<Float> = SIMD3(0.16, 0.95, 0.55)

    /// Purple band tint. Default ≈ #8C59F2.
    var purpleColor: SIMD3<Float> = SIMD3(0.55, 0.35, 0.95)

    /// Star emission density, 0…1. 0.025 ≈ more stars than the earlier
    /// sparse setting, matching the denser sky backdrop.
    var starDensity: Float = 0.025

    /// Star peak brightness multiplier — pumped so stars read clearly
    /// against the near-opaque dark-navy sky.
    var starBrightness: Float = 2.6

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { ctx in
                // `timeIntervalSinceReferenceDate` is ~8×10⁸ seconds, which
                // collapses to ≥128-second precision once cast to Float32 —
                // the shader would effectively freeze. Modulo by one hour
                // keeps the value small enough that Float stays accurate to
                // the sub-millisecond, while noise continuity holds because
                // the aurora's triangle-wave basis wraps naturally.
                let tWrapped = ctx.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 3600)

                // `.colorEffect` needs an opaque pixel source so the shader
                // fires on every pixel — any fill colour works; we output
                // premultiplied RGBA that replaces it entirely.
                Rectangle()
                    .fill(Color.black)
                    .auroraSky(
                        size: geo.size,
                        time: tWrapped,
                        amplitude: amplitude,
                        greenBandY: greenBandY,
                        purpleBandY: purpleBandY,
                        greenColor: greenColor,
                        purpleColor: purpleColor,
                        starDensity: starDensity,
                        starBrightness: starBrightness
                    )
            }
        }
        .allowsHitTesting(false)
    }
}

extension View {
    /// Wires the `auroraSky` Metal entry point to a view. All uniforms flow
    /// straight to the shader — see `AuroraSky.metal` for their meanings.
    func auroraSky(
        size: CGSize,
        time: Double,
        amplitude: Float,
        greenBandY: Float,
        purpleBandY: Float,
        greenColor: SIMD3<Float>,
        purpleColor: SIMD3<Float>,
        starDensity: Float,
        starBrightness: Float
    ) -> some View {
        // `.colorEffect` replaces each pixel's colour using the shader. For a
        // procedural overlay this is simpler (and more reliable across iOS
        // versions) than `.layerEffect`, which needs a non-trivial layer
        // source to actually run on some builds.
        colorEffect(
            ShaderLibrary.auroraSky(
                .float2(Float(size.width), Float(size.height)),
                .float(Float(time)),
                .float(amplitude),
                .float(greenBandY),
                .float(purpleBandY),
                .float3(greenColor.x, greenColor.y, greenColor.z),
                .float3(purpleColor.x, purpleColor.y, purpleColor.z),
                .float(starDensity),
                .float(starBrightness)
            )
        )
    }
}

// MARK: - Preview

#Preview("Aurora sky — static frame") {
    ZStack {
        // Mimic card background so the aurora reads like it will on Home.
        LinearGradient(colors: [Color(red: 0.14, green: 0.24, blue: 0.13),
                                Color(red: 0.04, green: 0.07, blue: 0.03)],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

        AuroraSkyView()
            .frame(width: 329, height: 530)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
