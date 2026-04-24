#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// Aurora sky — two drifting bands (green + purple) with sparse twinkling
// stars overhead. Adapted from nimitz "aurora" on ShaderToy (XtGGRt) using
// the triNoise2d / tri / tri2 family. The original does a 3D volumetric
// ray-march through a frustum; here we simplify to a 2D layered march
// along Y inside a narrow strip around each band centre, which reads as
// a drifting curtain at a fraction of the ALU cost.
//
// Applied via `.layerEffect(...)`. The shader is fully procedural — the
// `layer` argument is required by the SwiftUI signature but unused; output
// is written over a transparent canvas in premultiplied RGBA so the card
// background shows through in gaps.

// ---------- Tuning constants ----------

constant int   kMarchSteps      = 22;     // per band; 44 noise calls/pixel total
constant float kBandHalfWidth   = 0.07;   // vertical strip around bandY (±7%) — halved height
constant float kCurtainThinning = 96.0;   // larger = thinner vertical curtains (×4 → half height)
constant float kStepWeight      = 0.26;   // per-step color contribution (boosted for visibility over dark bg)
constant float kHighlightGain   = 0.70;   // rare bright flares on noise peaks
constant float3 kHighlightTint  = float3(0.95, 1.00, 0.92); // near-white cool
constant float kNoiseDrift      = 0.05;   // horizontal drift speed — visible but still calm
constant float kNoiseFreq       = 0.12;   // time scalar inside triNoise2d (faster evolution)
constant float kStarCellSize    = 2.0;    // stars grid cell in pixels
constant float kStarCoreRadius  = 0.40;   // star visible radius inside cell
constant float kStarSkyFade     = 0.5;    // stars fade below this uv.y

// Dark-blue backdrop filling the sky zone so the HomeView gradient doesn't
// bleed through behind the aurora. Coverage is separate from the star mask
// — sky extends nearly to the bottom of AuroraSkyView, stars stay on top.
constant float3 kSkyColor       = float3(0.010, 0.017, 0.045); // ≈ #03050B dark navy
constant float  kSkyOpacity     = 1.00;   // fully opaque in the covered zone
constant float  kSkyCoverage    = 0.95;   // sky extends to this uv.y before fading out

// ---------- Hashing ----------

static inline float hash12(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// ---------- Triangle-wave noise (nimitz) ----------

// Triangle wave, period 1, peak 0.5.
static inline float tri(float x) {
    return abs(fract(x) - 0.5);
}

// Folded veil — the building block of the aurora look.
static inline float tri2(float2 p) {
    return tri(p.x + tri(p.y) * 0.5) + tri(p.y);
}

// 3-octave triangle noise with per-octave rotation + time drift.
// `seed` shifts the noise field so two bands evolve independently.
static inline float triNoise2d(float2 p, float speed, float time, float seed) {
    const float2x2 rot = float2x2(0.95, -0.31, 0.31, 0.95);
    float z2 = 2.5;
    float rz = 0.0;
    p *= 0.25;
    p += seed * 0.137;
    for (int i = 0; i < 3; ++i) {
        float2 dg = float2(tri2(p * 1.85)) * 0.75;
        float g   = tri(p.x + tri(p.y + dg.y) * 0.5 + dg.x);
        z2 *= 1.25;
        p  *= 1.2;
        p   = rot * p;
        p  += time * speed * float(i + 1);
        rz += (tri(g + g + seed) * 0.5) / z2;
    }
    return rz;
}

// ---------- Aurora band sampler ----------

// Layered Y-march around `bandY`. Each step picks up a fall-off-weighted
// noise sample and contributes to the band's colour. Low per-step weight
// keeps the accumulated output from clipping past 1.0 on noise peaks.
static inline float3 auroraBand(float2 uv, float time, float bandY,
                                float3 color, float amplitude,
                                float seed, int steps) {
    // Per-column vertical wiggle — two incommensurate sinusoids break the
    // band out of a straight horizontal line into a drifting curtain whose
    // peak height varies across the canvas. Amplitude ±0.075 UV.
    float wiggle = sin(uv.x * 5.1 + time * 0.18 + seed) * 0.050
                 + sin(uv.x * 12.7 + time * 0.33 + seed * 2.3) * 0.025;
    float baseY  = bandY + wiggle;

    float3 col = float3(0.0);
    for (int i = 0; i < steps; ++i) {
        float t       = (float(i) + 0.5) / float(steps);
        float offsetY = (t - 0.5) * (kBandHalfWidth * 2.0);
        float y       = uv.y - (baseY + offsetY);
        float2 p      = float2(uv.x * 2.0 + time * kNoiseDrift + seed,
                               y * 6.0);
        float n    = triNoise2d(p, kNoiseFreq, time, seed);
        float fall = exp(-(y * y) * kCurtainThinning);
        col += color * n * fall * (kStepWeight * amplitude);

        // Rare near-white highlights — only the top ~15% of noise peaks
        // trigger, hardened further by a cubic knee. Produces flickering
        // bright filaments that catch the eye without washing the band out.
        float highlight = pow(smoothstep(0.58, 0.88, n), 4.0);
        col += kHighlightTint * highlight * fall * (kHighlightGain * amplitude);
    }
    return col;
}

// ---------- Stars ----------

// Hash-grid stars at constant brightness, localised to the upper part of
// the canvas via `skyMask`. Density ∈ 0…1 — percentage of cells that emit.
static inline float3 stars(float2 uv, float2 size, float time,
                           float density, float brightness) {
    float2 grid   = uv * size / kStarCellSize;
    float2 cell   = floor(grid);
    float  r      = hash12(cell + 11.17);
    float  birth  = step(1.0 - density, r);
    float  d      = length(grid - cell - 0.5);
    float  core   = smoothstep(kStarCoreRadius, 0.0, d);
    float  twinkle = 1.0;  // pulsation disabled — stars hold peak brightness
    float  skyMask = smoothstep(kStarSkyFade, 0.0, uv.y);
    return float3(0.96, 0.96, 1.0) * birth * core * twinkle * brightness * skyMask;
}

// ---------- Entry point ----------

// Using `.colorEffect` signature — takes the rasterized pixel colour and
// returns a replacement. We don't sample `sourceColor`; the aurora is fully
// procedural and overrides the pixel entirely.
[[ stitchable ]]
half4 auroraSky(float2 position,
                half4 sourceColor,
                float2 size,
                float time,
                float amplitude,
                float greenBandY,
                float purpleBandY,
                float3 greenColor,
                float3 purpleColor,
                float starDensity,
                float starBrightness) {
    float2 uv = position / size;

    // Two bands — seeds of 0.0 and 37.13 give visibly different drift.
    float3 greenLayer  = auroraBand(uv, time, greenBandY,  greenColor,
                                    amplitude, 0.0,   kMarchSteps);
    float3 purpleLayer = auroraBand(uv, time, purpleBandY, purpleColor,
                                    amplitude, 37.13, kMarchSteps);
    float3 auroraRGB   = greenLayer + purpleLayer;

    float3 starRGB = stars(uv, size, time, starDensity, starBrightness);

    // Horizontal edges already exit the screen (HomeView oversizes the view
    // by +80pt), so only vertical soft edges remain. Bottom fade starts at
    // 85% so the bleed dissolves into the tab bar gradient.
    float edgeFade =
          smoothstep(0.00, 0.06, uv.y)
        * smoothstep(1.00, 0.85, uv.y);

    // Dark-blue backdrop covering nearly the full aurora canvas — fills the
    // gaps between / around the bands so the HomeView gradient never shows
    // through. Independent from kStarSkyFade so stars stay in the upper half.
    float skyMask = smoothstep(kSkyCoverage, 0.0, uv.y);
    float skyA    = kSkyOpacity * skyMask;

    float auroraL = length(auroraRGB);
    float starL   = length(starRGB);
    float auroraA = saturate(auroraL * 2.6 + starL);

    // Porter-Duff "over": aurora + stars composited on top of the sky.
    float  outA   = auroraA + skyA * (1.0 - auroraA);
    float3 outRGB = ((auroraRGB + starRGB) * auroraA
                  +  kSkyColor             * skyA * (1.0 - auroraA))
                  / max(outA, 0.0001);

    outA *= edgeFade;
    return half4(half3(outRGB * outA), half(outA));
}
