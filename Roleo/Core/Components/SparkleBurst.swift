import SwiftUI

/// Small, short-lived sparkle burst for inline celebrations that don't
/// warrant a full confetti rain. Fires when `trigger` changes and plays
/// for `duration` before disappearing. Safe to leave mounted — it only
/// draws while animating.
///
/// Respects Reduce Motion by rendering a single gentle fade instead of
/// the radial burst.
struct SparkleBurst: View {
    var trigger: AnyHashable
    var palette: [Color] = [
        Color(hex: AppConstants.Colors.primaryOrange),
        Color(hex: AppConstants.Colors.goldBright),
        Color(hex: AppConstants.Colors.secondaryTeal),
        Color(hex: AppConstants.Colors.successGreen)
    ]
    var particleCount: Int = 14
    var duration: Double = 0.85

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var activeID: AnyHashable?
    @State private var animationStart: Date = .distantPast

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: activeID == nil)) { timeline in
            Canvas { context, size in
                guard activeID != nil else { return }
                let elapsed = timeline.date.timeIntervalSince(animationStart)
                let progress = min(1.0, elapsed / duration)
                guard progress < 1.0 else { return }

                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let maxRadius = min(size.width, size.height) * 0.55

                if reduceMotion {
                    let alpha = 1.0 - progress
                    let radius = maxRadius * 0.35
                    let rect = CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(palette[0].opacity(0.35 * alpha))
                    )
                    return
                }

                for index in 0..<particleCount {
                    let seed = Double(index) / Double(particleCount)
                    let angle = seed * .pi * 2 + seed * 1.7
                    let distance = maxRadius * (0.35 + 0.65 * easeOut(progress)) * (0.7 + (seed * 0.6))
                    let x = center.x + CGFloat(cos(angle)) * distance
                    let y = center.y + CGFloat(sin(angle)) * distance
                    let radius: CGFloat = 3.0 + CGFloat((index % 3))
                    let alpha = (1.0 - progress) * (0.7 + seed * 0.3)
                    let color = palette[index % palette.count].opacity(alpha)
                    let rect = CGRect(
                        x: x - radius,
                        y: y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .onChange(of: trigger) { _, newValue in
            activeID = newValue
            animationStart = Date()
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(duration + 0.1))
                if activeID == newValue {
                    activeID = nil
                }
            }
        }
    }

    private func easeOut(_ t: Double) -> Double {
        1 - pow(1 - t, 3)
    }
}

#Preview {
    struct Demo: View {
        @State private var tick = 0
        var body: some View {
            ZStack {
                Color(hex: AppConstants.Colors.backgroundTop).ignoresSafeArea()
                Button("Sparkle") {
                    tick += 1
                }
                .buttonStyle(.borderedProminent)
                .overlay(SparkleBurst(trigger: tick).frame(width: 160, height: 160))
            }
        }
    }
    return Demo()
}
