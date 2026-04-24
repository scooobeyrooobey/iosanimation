import SwiftUI

/// Full-screen metaball neck between two points.
///
/// Renders a solid white Rectangle under a `.colorEffect` so every pixel gets
/// rewritten by the shader — inside the blob it becomes `tint`, outside it
/// becomes transparent. Positions are expected in the same coordinate space
/// as the parent ZStack (i.e. the `"root"` space used by the coordinator).
struct ContactMergeView: View {
    let c1: CGPoint
    let c2: CGPoint
    let r1: CGFloat
    let r2: CGFloat
    let smoothK: CGFloat
    let tint: Color

    var body: some View {
        Rectangle()
            .fill(Color.white)
            .colorEffect(
                ShaderLibrary.contactMerge(
                    .float2(Float(c1.x), Float(c1.y)),
                    .float2(Float(c2.x), Float(c2.y)),
                    .float(Float(r1)),
                    .float(Float(r2)),
                    .float(Float(smoothK)),
                    .color(tint)
                )
            )
            .allowsHitTesting(false)
    }
}
