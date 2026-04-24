import SwiftUI

/// Full-screen overlay that renders the in-flight bookmark drop.
///
/// Drives all motion from a single `TimelineView(.animation)` tick — every
/// property (position, rotation, stretch, refraction, neck strengths) is a
/// pure function of `elapsed = now − flight.startedAt`. No `@State` physics,
/// no intermediate animators: one source of truth means there's nothing to
/// get out of sync.
struct BookmarkDrop: View {
    @Environment(BookmarkDropCoordinator.self) private var coordinator

    /// Drop diameter — matches the icon-button footprint so the birth / land
    /// feels like the button itself is dispensing liquid.
    private let dropSize: CGFloat = 35

    var body: some View {
        TimelineView(.animation) { ctx in
            if let flight = coordinator.flight {
                let elapsed = ctx.date.timeIntervalSince(flight.startedAt)
                let state = DropState(elapsed: elapsed, flight: flight, size: dropSize)
                DropFlightLayer(state: state, shaderTime: elapsed, dropSize: dropSize)
            } else {
                Color.clear
            }
        }
    }
}

// MARK: - Per-frame derived state

private struct DropState {
    let position: CGPoint
    let rotation: Angle
    let scaleX: CGFloat
    let scaleY: CGFloat
    let opacity: CGFloat
    let refractionStrength: CGFloat
    let rimStrength: CGFloat
    let velocity: CGVector          // normalised, for shader smear
    let birthNeck: CGFloat          // 0…1
    let splashNeck: CGFloat         // 0…1
    let sourceAnchor: CGPoint
    let targetAnchor: CGPoint
    let dropSize: CGFloat

    init(elapsed: Double, flight: BookmarkDropCoordinator.Flight, size: CGFloat) {
        self.sourceAnchor = flight.source
        self.targetAnchor = flight.target
        self.dropSize = size

        let (phase, localT) = DropTiming.phase(at: elapsed)
        let trajectory = DropTrajectory(source: flight.source, target: flight.target)

        // --- Global Bezier t per phase ---
        // Cross-phase continuity is critical here: the *derivative* of bezierT
        // with respect to real time must match across phase boundaries, or the
        // drop will visibly jerk. Rise ends with zero velocity (ease-out),
        // hover holds that value, fall begins with zero velocity (ease-in) —
        // so all three joints are C¹-smooth by construction.
        let apexT: CGFloat = 0.30
        let bezierT: CGFloat
        switch phase {
        case .idle, .birth:
            bezierT = 0
        case .rise:
            let k = CGFloat(DropEase.outQuint(localT))
            bezierT = apexT * k
        case .hover:
            bezierT = apexT
        case .fall:
            let k = CGFloat(DropEase.inQuart(localT))
            bezierT = apexT + (1 - apexT) * k
        case .splash:
            bezierT = 1
        }

        // --- Position ---
        // Pure Bezier point, no wobble. Hover-time wobble turned out to break
        // C¹ continuity at the hover→fall seam (sin(π·t) has non-zero slope
        // at its zeros), producing a visible jerk just before the fall starts.
        var pos = trajectory.point(at: bezierT)
        if phase == .birth {
            // During birth the sprite grows in place at the button so the
            // contact neck has a single stable anchor point.
            pos = flight.source
        }
        self.position = pos

        // --- Velocity & speed (used for shader smear and stretch factor) ---
        let d = trajectory.derivative(at: bezierT)
        let mag = sqrt(d.dx * d.dx + d.dy * d.dy)
        self.velocity = mag > 0.01 ? CGVector(dx: d.dx / mag, dy: d.dy / mag) : .zero
        let speed = trajectory.normalisedSpeed(at: bezierT)

        // --- Rotation: a single monotonic curve from "nose up" to "nose down" ---
        // We follow the trajectory tangent directly, with no slant factor.
        // tangentAngle on this Bezier decreases monotonically from ≈175°
        // (nose up-and-right at birth) through ≈90° (horizontal at apex) to
        // 0° (straight down at target) — so the drop rotates in ONE direction
        // across the entire flight and lands nose-down, exactly as requested.
        //
        // A previous version multiplied tangent by a rising slant factor,
        // which caused the product to first grow (CW) and then shrink (CCW) —
        // that's the "wobble at apex" the user saw.
        self.rotation = trajectory.tangentAngle(at: bezierT)

        // --- Base size: grows from 0 to 2x at apex, returns to 1x at target ---
        // Size curve is its own smooth interpolation, independent of bezierT.
        let baseSize: CGFloat
        switch phase {
        case .idle:
            baseSize = 0
        case .birth:
            // 0 → 1 with smooth ease, no overshoot.
            baseSize = CGFloat(DropEase.smooth(localT))
        case .rise:
            // 1 → 2.4 with C² smoother — zero slope and curvature at both ends.
            baseSize = 1 + 1.4 * CGFloat(DropEase.smoother(localT))
        case .hover:
            baseSize = 2.4
        case .fall:
            // 2.4 → 1 with C² smoother.
            baseSize = 2.4 - 1.4 * CGFloat(DropEase.smoother(localT))
        case .splash:
            baseSize = 1
        }

        // --- Velocity stretch (conserves area around baseSize) ---
        let stretchAmount = 1 + 0.30 * speed
        let stretchY = stretchAmount
        let stretchX = 1 / sqrt(stretchAmount)

        switch phase {
        case .idle:
            self.scaleX = 0; self.scaleY = 0
        case .birth:
            self.scaleX = baseSize * stretchX
            self.scaleY = baseSize * stretchY
        case .rise, .hover, .fall:
            self.scaleX = baseSize * stretchX
            self.scaleY = baseSize * stretchY
        case .splash:
            // 3-beat impact, seamlessly continuing from fall-end scale.
            // At fall end: baseSize = 1, stretch ≈ 1.30 → scale ≈ (0.877, 1.30).
            // Start splash from there so there's zero scale jump on impact.
            let fallEndX: CGFloat = 0.877
            let fallEndY: CGFloat = 1.300
            let t = CGFloat(localT)
            if t < 0.35 {
                // Impact squash: stretched-falling → flat-wide puddle.
                let k = CGFloat(DropEase.smooth(Double(t / 0.35)))
                self.scaleX = fallEndX + (1.45 - fallEndX) * k
                self.scaleY = fallEndY + (0.45 - fallEndY) * k
            } else if t < 0.70 {
                // Bounce back — overshoot taller than rest.
                let k = CGFloat(DropEase.smooth(Double((t - 0.35) / 0.35)))
                self.scaleX = 1.45 - 0.55 * k
                self.scaleY = 0.45 + 0.65 * k
            } else {
                // Collapse into the tab bar.
                let k = CGFloat(DropEase.smooth(Double((t - 0.70) / 0.30)))
                let shrink = 1 - k
                self.scaleX = 0.9 * shrink
                self.scaleY = 1.10 * shrink
            }
        }

        // --- Opacity ---
        switch phase {
        case .idle:
            self.opacity = 0
        case .birth:
            self.opacity = CGFloat(DropEase.smooth(localT))
        case .rise, .hover, .fall:
            self.opacity = 1
        case .splash:
            let t = CGFloat(localT)
            if t < 0.70 {
                self.opacity = 1
            } else {
                self.opacity = 1 - CGFloat(DropEase.smooth(Double((t - 0.70) / 0.30)))
            }
        }

        // --- Refraction intensity: strongest during flight ---
        switch phase {
        case .idle, .birth:
            self.refractionStrength = 0.55 + 0.30 * CGFloat(DropEase.smooth(localT))
            self.rimStrength = 0.85
        case .rise, .hover, .fall:
            self.refractionStrength = 0.85
            self.rimStrength = 0.95
        case .splash:
            let k = CGFloat(DropEase.smooth(localT))
            self.refractionStrength = max(0, 0.85 - k * 0.85)
            self.rimStrength = max(0, 0.9 - k)
        }

        // --- Contact necks ---
        switch phase {
        case .birth:
            // Neck peaks mid-birth, then snaps as the drop leaves.
            self.birthNeck = sin(CGFloat(localT) * .pi)
            self.splashNeck = 0
        case .rise:
            // Tail of the birth neck, fading out in the first 40% of the rise.
            self.birthNeck = max(0, 1 - CGFloat(localT) / 0.4) * 0.35
            self.splashNeck = 0
        case .splash:
            let t = CGFloat(localT)
            self.birthNeck = 0
            // Neck strong at impact (t<0.35), dissolves as drop sinks in.
            if t < 0.35 {
                self.splashNeck = t / 0.35
            } else {
                self.splashNeck = max(0, 1 - (t - 0.35) / 0.55)
            }
        default:
            self.birthNeck = 0
            self.splashNeck = 0
        }
    }
}

// MARK: - Rendering

private struct DropFlightLayer: View {
    let state: DropState
    let shaderTime: Double
    let dropSize: CGFloat

    var body: some View {
        // A single transaction on the container propagates down the whole
        // subtree (docs: "applies to this view's children"). Per-child
        // `.transaction` modifiers didn't cover the sibling transform
        // modifiers (.rotationEffect/.scaleEffect/.position) themselves —
        // the enclosing `withAnimation(HeroTransition.spring)` in ContentView
        // could then interpolate them with its spring curve on top of our
        // per-frame values, producing visible wobble during the flight.
        ZStack {
            // 1) Birth neck — between bookmark button and drop centre
            if state.birthNeck > 0.01 {
                ContactMergeView(
                    c1: state.sourceAnchor,
                    c2: state.position,
                    r1: dropSize * 0.55,
                    r2: dropSize * 0.48 * state.birthNeck,
                    smoothK: 44 * state.birthNeck,
                    tint: neckTint(opacity: state.birthNeck)
                )
                .allowsHitTesting(false)
            }

            // 2) Splash neck — between drop and profile tab icon
            if state.splashNeck > 0.01 {
                ContactMergeView(
                    c1: state.targetAnchor,
                    c2: state.position,
                    r1: dropSize * 0.52 * state.splashNeck,
                    r2: dropSize * 0.48 * state.splashNeck,
                    smoothK: 38 * state.splashNeck,
                    tint: neckTint(opacity: state.splashNeck * 0.9)
                )
                .allowsHitTesting(false)
            }

            // 3) The drop sprite itself
            dropSprite
                .scaleEffect(x: state.scaleX, y: state.scaleY)
                .opacity(state.opacity)
                .position(state.position)
        }
        .transaction { $0.disablesAnimations = true }
    }

    private var dropSprite: some View {
        Image("DropPic")
            .resizable()
            .scaledToFill()
            .frame(width: dropSize, height: dropSize)
            .clipShape(Circle())
            .dropRefraction(
                size: CGSize(width: dropSize, height: dropSize),
                time: shaderTime,
                refractionStrength: state.refractionStrength,
                depthBoost: 0.55,
                rimStrength: state.rimStrength,
                velocity: state.velocity
            )
            .shadow(color: AppColor.accent.opacity(0.25), radius: 10)
    }

    private func neckTint(opacity: CGFloat) -> Color {
        // Liquid-glass tint — near-white with a faint teal so both necks read
        // as "the same substance" as the drop's rim glow.
        Color(red: 0.92, green: 0.98, blue: 0.95).opacity(Double(opacity))
    }
}
