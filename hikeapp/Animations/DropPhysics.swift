import SwiftUI
import CoreGraphics

// MARK: - Trajectory

/// S-curve trajectory from bookmark button to Profile tab icon.
///
/// Built as a cubic Bezier so we get both position AND tangent angle from the
/// same math. Control points shape the flight per `Drop_traektory.png`:
/// rise straight up, lean right over the apex, then curve down-right into the
/// target. The drop's visual tilt follows the tangent automatically.
struct DropTrajectory {
    let source: CGPoint
    let target: CGPoint

    /// Pop-up distance above the source before the drop starts falling.
    static let apexRise: CGFloat = 300
    /// Horizontal shift of the apex to the right of the source — nudges the
    /// S-curve so the drop leans toward the tab bar from the very top.
    /// Tuned so B(t=apexT).x ends up ~20pt right of its previous resting
    /// position (coefficient on p1 at t=0.30 is 3·0.7²·0.3 ≈ 0.441).
    static let apexNudgeX: CGFloat = 70

    var p0: CGPoint { source }
    /// Rises (mostly) straight up with a slight right lean.
    var p1: CGPoint {
        CGPoint(x: source.x + Self.apexNudgeX, y: source.y - Self.apexRise)
    }
    /// Leans toward the target x while still above — produces the right-side
    /// bulge of the S-curve.
    var p2: CGPoint {
        CGPoint(x: target.x, y: source.y - Self.apexRise * 0.45)
    }
    var p3: CGPoint { target }

    /// Position on cubic Bezier, t in [0, 1].
    func point(at t: CGFloat) -> CGPoint {
        let u = 1 - t
        let b0 = u * u * u
        let b1 = 3 * u * u * t
        let b2 = 3 * u * t * t
        let b3 = t * t * t
        let x = b0 * p0.x + b1 * p1.x + b2 * p2.x + b3 * p3.x
        let y = b0 * p0.y + b1 * p1.y + b2 * p2.y + b3 * p3.y
        return CGPoint(x: x, y: y)
    }

    /// First derivative of the Bezier — unnormalised velocity vector.
    func derivative(at t: CGFloat) -> CGVector {
        let u = 1 - t
        let dx = 3 * u * u * (p1.x - p0.x)
               + 6 * u * t * (p2.x - p1.x)
               + 3 * t * t * (p3.x - p2.x)
        let dy = 3 * u * u * (p1.y - p0.y)
               + 6 * u * t * (p2.y - p1.y)
               + 3 * t * t * (p3.y - p2.y)
        return CGVector(dx: dx, dy: dy)
    }

    /// Tangent rotation — nose of the drop points along the velocity vector.
    /// Neutral orientation is "pointing down" (+Y), i.e. a falling teardrop.
    ///
    /// Derivation: a SwiftUI CW rotation by θ applied to the nose vector
    /// `(0, 1)` (in y-down screen space) gives `(-sin θ, cos θ)`. Matching
    /// this to the normalised velocity `(dx, dy)/|d|` solves to
    ///     θ = atan2(-dx, dy)
    /// which is what we return here. An earlier revision used the mirrored
    /// `atan2(dx, dy)` — that made the drop's nose point to the *reflected*
    /// direction, which read visually as "rotating the wrong way at the apex".
    func tangentAngle(at t: CGFloat) -> Angle {
        let d = derivative(at: t)
        return Angle(radians: Double(atan2(-d.dx, d.dy)))
    }

    /// Speed magnitude along the curve, normalised against the peak speed over
    /// [0, 1] sampled at 20 steps. Good enough for a stretch-by-velocity UV.
    func normalisedSpeed(at t: CGFloat) -> CGFloat {
        let d = derivative(at: t)
        let speed = sqrt(d.dx * d.dx + d.dy * d.dy)
        let peak = peakSpeed
        return peak > 0 ? min(speed / peak, 1) : 0
    }

    private var peakSpeed: CGFloat {
        var maxSpeed: CGFloat = 0
        for i in 0...20 {
            let t = CGFloat(i) / 20
            let d = derivative(at: t)
            let s = sqrt(d.dx * d.dx + d.dy * d.dy)
            if s > maxSpeed { maxSpeed = s }
        }
        return maxSpeed
    }
}

// MARK: - Flight timing

/// Single source of truth for the drop's 6-phase schedule.
/// All values are in seconds from the start of the flight.
enum DropTiming {
    // Doubled from the original pass for a slower, more luxurious feel.
    static let birth:  Double = 0.24
    static let rise:   Double = 0.44
    static let hover:  Double = 0.05
    static let fall:   Double = 0.96
    static let splash: Double = 0.36

    static var total: Double { birth + rise + hover + fall + splash }

    /// Normalised boundaries (0…1) for keyframe-like gating.
    static var tBirthEnd:  Double { birth / total }
    static var tRiseEnd:   Double { (birth + rise) / total }
    static var tHoverEnd:  Double { (birth + rise + hover) / total }
    static var tFallEnd:   Double { (birth + rise + hover + fall) / total }
    static var tSplashEnd: Double { 1.0 }

    /// Phase driver — maps absolute time since flight start to (phase, local t).
    static func phase(at elapsed: Double) -> (phase: DropPhase, localT: Double) {
        let clamped = max(0, min(elapsed, total))
        var cursor = 0.0
        for (phase, length) in [
            (DropPhase.birth,  birth),
            (.rise,            rise),
            (.hover,           hover),
            (.fall,            fall),
            (.splash,          splash)
        ] {
            if clamped < cursor + length || phase == .splash {
                let local = length > 0 ? (clamped - cursor) / length : 0
                return (phase, max(0, min(local, 1)))
            }
            cursor += length
        }
        return (.splash, 1)
    }
}

enum DropPhase: Equatable {
    case idle, birth, rise, hover, fall, splash
}

// MARK: - Easing

enum DropEase {
    /// Smooth 0→1 curve, cubic ease-in-out.
    static func inOut(_ t: Double) -> Double {
        let c = max(0, min(t, 1))
        return c < 0.5 ? 4 * c * c * c : 1 - pow(-2 * c + 2, 3) / 2
    }

    /// Hermite smoothstep — 0→1 with zero derivative at both ends.
    /// Use for property cross-fades (scale, slant, opacity) where continuity
    /// of velocity matters more than speed.
    static func smooth(_ t: Double) -> Double {
        let c = max(0, min(t, 1))
        return c * c * (3 - 2 * c)
    }

    /// C² smootherstep — zero first AND second derivative at both ends.
    /// Produces visibly softer ease-in/out than smooth(); use for size
    /// transitions where any hint of "jerk" would read as a pop.
    static func smoother(_ t: Double) -> Double {
        let c = max(0, min(t, 1))
        return c * c * c * (c * (c * 6 - 15) + 10)
    }

    /// Ease-out quint — strong deceleration. Good for gravity-opposed motion.
    static func outQuint(_ t: Double) -> Double {
        let c = max(0, min(t, 1))
        return 1 - pow(1 - c, 5)
    }

    /// Ease-in quart — gentle start, strong acceleration. Good for gravity.
    static func inQuart(_ t: Double) -> Double {
        let c = max(0, min(t, 1))
        return c * c * c * c
    }

    /// Spring-like overshoot for splash bounce.
    static func bounceOut(_ t: Double) -> Double {
        let c = max(0, min(t, 1))
        let n1 = 7.5625
        let d1 = 2.75
        if c < 1 / d1 { return n1 * c * c }
        if c < 2 / d1 { let cc = c - 1.5 / d1; return n1 * cc * cc + 0.75 }
        if c < 2.5 / d1 { let cc = c - 2.25 / d1; return n1 * cc * cc + 0.9375 }
        let cc = c - 2.625 / d1
        return n1 * cc * cc + 0.984375
    }
}
