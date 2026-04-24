#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// Liquid-drop refraction. Applied via `.layerEffect(...)` to the clipped
// DropPic sprite — the shader distorts and decorates its OWN content.
//
// The look is intentionally stronger than `images for app/Drop_ref.png`
// (per spec): aggressive barrel lens + chromatic aberration + fresnel edge
// + upper-left specular + teal rim + velocity smear during flight.
[[ stitchable ]]
half4 dropRefraction(float2 position,
                     SwiftUI::Layer layer,
                     float2 size,
                     float time,
                     float refractionStrength,  // 0…1, target ≈0.85 in flight
                     float depthBoost,          // 0…1, chromatic + vignette
                     float rimStrength,         // 0…1
                     float2 velocity)           // normalised motion vector
{
    float2 uv = position / size;
    float2 centered = uv - 0.5;
    float r = length(centered) * 2.0;          // 0 center → 1 edge

    // Outside the circle → transparent.
    if (r > 1.02) { return half4(0.0h); }

    // --- Barrel lens: magnifies centre, falls off toward the rim ---
    float lens = 1.0 - r * r;
    float barrel = refractionStrength * lens;
    float2 sampleUV = 0.5 + centered * (1.0 - barrel);

    // --- Velocity smear: trail content along motion vector ---
    // Negative projection → the trailing half of the drop.
    float2 safeCentered = centered + float2(1e-4, 1e-4);
    float trail = max(0.0, -dot(normalize(safeCentered), velocity)) * r;
    sampleUV -= velocity * trail * 0.09;

    float2 samplePos = sampleUV * size;

    // --- Chromatic aberration by depth ---
    float chroma = depthBoost * r * 8.0;
    float2 dir = centered / max(r, 1e-4);
    half4 rCh = layer.sample(samplePos + dir * chroma);
    half4 gCh = layer.sample(samplePos);
    half4 bCh = layer.sample(samplePos - dir * chroma);
    half4 col = half4(rCh.r, gCh.g, bCh.b, gCh.a);

    // --- Edge darkening (sells the 3D volume) ---
    float edge = pow(r, 3.0);
    col.rgb *= (1.0h - half(edge * 0.55 * depthBoost));

    // --- Specular highlight (upper-left quadrant) ---
    float2 specOffset = centered - float2(-0.22, -0.22);
    float specDist = length(specOffset);
    float spec = smoothstep(0.26, 0.02, specDist) * (1.0 - r * 0.55);
    col.rgb += half3(spec * 0.95h);

    // --- Rim glow (teal — matches card glow palette) ---
    float rim = smoothstep(0.74, 0.98, r) * (1.0 - smoothstep(0.98, 1.02, r));
    half3 rimColor = half3(0.094h, 0.871h, 0.608h);
    col.rgb += rimColor * half(rim * rimStrength);

    // --- Anti-aliased circle mask ---
    float aa = 1.0 - smoothstep(0.96, 1.02, r);
    col.a *= half(aa);
    col.rgb *= half(aa);

    return col;
}
