import SwiftUI

extension View {
    /// Applies the liquid-drop refraction layer effect. Uniforms are wired
    /// directly to the Metal entry point `dropRefraction` in `DropRefraction.metal`.
    ///
    /// - Parameters:
    ///   - size: pixel size of the drop sprite (used for uv normalisation).
    ///   - time: shader time from `TimelineView(.animation)`.
    ///   - refractionStrength: 0…1, barrel-lens magnification. 0.85 is a good
    ///     flight value — deliberately stronger than the static reference.
    ///   - depthBoost: 0…1, chromatic aberration + edge vignette.
    ///   - rimStrength: 0…1, teal rim glow intensity.
    ///   - velocity: normalised motion direction for the trail smear.
    func dropRefraction(
        size: CGSize,
        time: Double,
        refractionStrength: CGFloat,
        depthBoost: CGFloat,
        rimStrength: CGFloat,
        velocity: CGVector
    ) -> some View {
        let maxOffset = CGSize(
            width: max(size.width, 1) * 0.5,
            height: max(size.height, 1) * 0.5
        )
        return layerEffect(
            ShaderLibrary.dropRefraction(
                .float2(Float(size.width), Float(size.height)),
                .float(Float(time)),
                .float(Float(refractionStrength)),
                .float(Float(depthBoost)),
                .float(Float(rimStrength)),
                .float2(Float(velocity.dx), Float(velocity.dy))
            ),
            maxSampleOffset: maxOffset
        )
    }
}
