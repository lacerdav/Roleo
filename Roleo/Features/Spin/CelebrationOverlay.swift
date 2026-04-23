import SwiftUI

// MARK: - CelebrationOverlay

/// Full-screen Canvas particle burst launched the moment a habit is marked done.
/// Particles fan out from a captured emission origin (the DONE button's global
/// center) so confetti literally bursts out of the button itself.
///
/// Extracted from SpinView to keep that file focused on layout and state.
struct CelebrationOverlay: View {
    /// Global-coordinate emission point. Falls back to bottom-center when nil.
    let origin: CGPoint?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date()

    private static let palette: [Color] = [
        Color(hex: AppConstants.Colors.primaryOrange),
        Color(hex: "#FF3B5C"),
        Color(hex: "#FF4D97"),
        Color(hex: "#FF9B52"),
        Color(hex: AppConstants.Colors.secondaryTeal),
        Color(hex: "#3B82F6"),
        Color(hex: "#00D4C8"),
        Color(hex: "#A3E635"),
        Color(hex: "#FFC93C"),
        Color(hex: "#F5E9D4")
    ]

    /// Pre-built, deterministic particle set — stable across frames so Canvas
    /// just replays the same motion curves each tick.
    private static let particles: [ConfettiParticle] = {
        (0..<240).map { ConfettiParticle.make(seed: $0, palette: palette) }
    }()

    private let totalDuration: Double = 2.6
    private let flashDuration: Double = 0.35

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)

            Canvas { context, size in
                let center = resolvedOrigin(in: size)

                if elapsed < flashDuration && !reduceMotion {
                    drawFlash(elapsed: elapsed, center: center, context: context)
                }

                for particle in Self.particles {
                    let localT = elapsed - particle.delay
                    guard localT >= 0, localT <= particle.lifetime else { continue }
                    drawParticle(particle, t: localT, center: center, context: context, size: size)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { startDate = Date() }
        .accessibilityHidden(true)
    }

    private func resolvedOrigin(in size: CGSize) -> CGPoint {
        origin ?? CGPoint(x: size.width / 2, y: size.height * 0.68)
    }

    // MARK: - Draw

    private func drawFlash(elapsed: Double, center: CGPoint, context: GraphicsContext) {
        let progress = min(1.0, elapsed / flashDuration)
        let alpha = pow(1.0 - progress, 2.2) * 0.6
        let radius = 120 + progress * 360

        let rect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        var local = context
        local.opacity = alpha
        local.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(
                Gradient(colors: [
                    Color.white,
                    Color(hex: "#FFE6B8").opacity(0.7),
                    Color.clear
                ]),
                center: center,
                startRadius: 0,
                endRadius: radius
            )
        )
    }

    private func drawParticle(
        _ particle: ConfettiParticle,
        t: Double,
        center: CGPoint,
        context: GraphicsContext,
        size: CGSize
    ) {
        let gravity = reduceMotion ? 220.0 : 620.0
        let life = min(1.0, t / particle.lifetime)

        let wobble = sin(t * particle.wobbleFreq + particle.phase) * particle.wobbleAmp
        let x = center.x + particle.startX + particle.velocityX * t + wobble
        let y = center.y + particle.startY + particle.velocityY * t + 0.5 * gravity * t * t

        if y > size.height + 40 { return }

        let fadeStart = 0.75
        let alpha: Double
        if life < fadeStart {
            alpha = 1.0
        } else {
            let f = (life - fadeStart) / (1.0 - fadeStart)
            alpha = 1.0 - f * f
        }

        let birth = min(1.0, t / 0.12)
        let birthScale = 0.55 + 0.45 * birth
        let rotation = reduceMotion ? 0 : (particle.rotationStart + particle.rotationRate * t)

        var local = context
        local.translateBy(x: x, y: y)
        local.rotate(by: .radians(rotation))
        local.scaleBy(x: birthScale, y: birthScale)
        local.opacity = alpha

        let color = particle.color

        switch particle.shape {
        case .disk:
            let r = particle.size * 0.5
            let rect = CGRect(x: -r, y: -r, width: particle.size, height: particle.size)
            local.fill(Path(ellipseIn: rect), with: .color(color))
            let hlRadius = r * 0.35
            let hlRect = CGRect(x: -r * 0.35 - hlRadius * 0.5, y: -r * 0.35 - hlRadius * 0.5,
                                width: hlRadius * 2, height: hlRadius * 2)
            local.fill(Path(ellipseIn: hlRect), with: .color(Color.white.opacity(0.55)))

        case .square:
            let s = particle.size
            let rect = CGRect(x: -s * 0.5, y: -s * 0.5, width: s, height: s)
            local.fill(Path(roundedRect: rect, cornerSize: CGSize(width: 1.2, height: 1.2)),
                       with: .color(color))
            let hlRect = CGRect(x: -s * 0.45, y: -s * 0.45, width: s * 0.9, height: s * 0.18)
            local.fill(Path(roundedRect: hlRect, cornerSize: CGSize(width: 0.6, height: 0.6)),
                       with: .color(Color.white.opacity(0.45)))

        case .streamer:
            let w = particle.size * 0.48
            let h = particle.size * 2.1
            let rect = CGRect(x: -w * 0.5, y: -h * 0.5, width: w, height: h)
            local.fill(
                Path(roundedRect: rect, cornerSize: CGSize(width: 1.0, height: 1.0)),
                with: .linearGradient(
                    Gradient(colors: [color.opacity(1.0), color.opacity(0.78), color.opacity(0.55)]),
                    startPoint: CGPoint(x: 0, y: -h * 0.5),
                    endPoint: CGPoint(x: 0, y: h * 0.5)
                )
            )

        case .sparkle:
            let s = particle.size * 1.0
            var path = Path()
            path.move(to: CGPoint(x: 0, y: -s))
            path.addLine(to: CGPoint(x: s * 0.22, y: -s * 0.22))
            path.addLine(to: CGPoint(x: s, y: 0))
            path.addLine(to: CGPoint(x: s * 0.22, y: s * 0.22))
            path.addLine(to: CGPoint(x: 0, y: s))
            path.addLine(to: CGPoint(x: -s * 0.22, y: s * 0.22))
            path.addLine(to: CGPoint(x: -s, y: 0))
            path.addLine(to: CGPoint(x: -s * 0.22, y: -s * 0.22))
            path.closeSubpath()
            local.fill(path, with: .color(color))
            let coreRect = CGRect(x: -s * 0.18, y: -s * 0.18, width: s * 0.36, height: s * 0.36)
            local.fill(Path(ellipseIn: coreRect), with: .color(Color.white.opacity(0.85)))
        }
    }
}

// MARK: - ConfettiParticle

struct ConfettiParticle {
    enum Shape { case disk, square, streamer, sparkle }

    var startX: Double
    var startY: Double
    var velocityX: Double
    var velocityY: Double
    var rotationStart: Double
    var rotationRate: Double
    var wobbleFreq: Double
    var wobbleAmp: Double
    var phase: Double
    var size: Double
    var delay: Double
    var lifetime: Double
    var shape: Shape
    var color: Color

    static func make(seed: Int, palette: [Color]) -> ConfettiParticle {
        func rand(_ salt: Double) -> Double {
            let v = sin(Double(seed) * 12.9898 + salt * 78.233) * 43758.5453
            return v - floor(v)
        }

        let shapeRoll = rand(1)
        let shape: Shape
        switch shapeRoll {
        case ..<0.45: shape = .streamer
        case ..<0.73: shape = .disk
        case ..<0.88: shape = .square
        default:      shape = .sparkle
        }

        let startX = (rand(2) - 0.5) * 140
        let startY = (rand(3) - 0.5) * 24

        let angleDeg = (rand(4) - 0.5) * 156
        let angle = angleDeg * .pi / 180
        let speed = 680 + rand(5) * 820
        let velocityX = speed * sin(angle)
        let velocityY = -speed * cos(angle)

        let size: Double
        switch shape {
        case .streamer: size = 9  + rand(7) * 9
        case .disk:     size = 7  + rand(7) * 8
        case .square:   size = 7  + rand(7) * 7
        case .sparkle:  size = 4  + rand(7) * 4
        }

        let rotationStart = rand(8) * .pi * 2
        let rotationRate  = (rand(9) - 0.5) * 18
        let wobbleFreq = 2.8 + rand(10) * 4.0
        let wobbleAmp  = 8   + rand(11) * 22
        let phase = rand(12) * .pi * 2

        let delayRoll = rand(13)
        let delay = delayRoll < 0.85 ? 0 : (delayRoll - 0.85) * 1.2

        let lifetime = 2.2 + rand(14) * 0.6

        let colorIndex = Int(rand(15) * Double(palette.count)) % palette.count

        return ConfettiParticle(
            startX: startX, startY: startY,
            velocityX: velocityX, velocityY: velocityY,
            rotationStart: rotationStart, rotationRate: rotationRate,
            wobbleFreq: wobbleFreq, wobbleAmp: wobbleAmp, phase: phase,
            size: size, delay: delay, lifetime: lifetime,
            shape: shape, color: palette[colorIndex]
        )
    }
}
