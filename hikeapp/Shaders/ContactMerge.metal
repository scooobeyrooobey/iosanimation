#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// Polynomial smooth-min — classic Inigo Quilez metaball formula.
// Returns the distance to the unioned blob (two circles glued by a neck).
static inline float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / max(k, 1e-4);
    return min(a, b) - h * h * h * k * (1.0 / 6.0);
}

// Metaball neck between two circles. Applied via `.colorEffect(...)` on a
// full-screen rectangle — every pixel is rewritten. Output is transparent
// outside the blob, `tint` inside it, with a 1.5px AA band along the edge.
//
// Used for BOTH the takeoff neck (button ↔ drop) and the landing neck
// (drop ↔ tab bar), differing only in uniforms.
[[ stitchable ]]
half4 contactMerge(float2 position,
                   half4 color,
                   float2 c1,
                   float2 c2,
                   float r1,
                   float r2,
                   float smoothK,
                   half4 tint)
{
    float d1 = length(position - c1) - r1;
    float d2 = length(position - c2) - r2;
    float d = smin(d1, d2, smoothK);

    float aa = 1.0 - smoothstep(0.0, 1.5, d);
    if (aa <= 0.0) { return half4(0.0h); }

    // Premultiplied output — SwiftUI expects premultiplied alpha.
    half a = tint.a * half(aa);
    return half4(tint.rgb * a, a);
}
