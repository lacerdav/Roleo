import SwiftUI
import UIKit

/// Premium warm-gold wheel.
///
/// Design language: physical object sitting on the warm cream background.
/// Every surface has visible thickness (hard-offset shadows, bevelled edges).
/// Pointer and ring both use the same "raised brass" visual language as
/// DuoBadgeBackground — hard shadow below creates instant 3D depth.
struct WheelView: View {
    let habits: [Habit]
    let rotation: Double
    var onCenterTap: (() -> Void)? = nil

    @State private var pointerKick: Double = 0
    @State private var lastPegIndex: Int = -1

    var body: some View {
        GeometryReader { proxy in
            let size       = min(proxy.size.width, proxy.size.height)
            let center     = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let wheelRadius = size * 0.42

            ZStack {
                floatingShadow(size: size)
                raisedGoldRing(wheelRadius: wheelRadius)
                rotatingDisc(size: size, center: center, wheelRadius: wheelRadius)
                centerHubDome(wheelRadius: wheelRadius)
                raisedPointer(wheelRadius: wheelRadius)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: rotation) { _, newValue in
                handlePegWobble(newRotation: newValue)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Rotating disc

    private func rotatingDisc(size: CGFloat, center: CGPoint, wheelRadius: CGFloat) -> some View {
        ZStack {
            segmentCanvas(center: center, wheelRadius: wheelRadius)
            segmentIcons(center: center, wheelRadius: wheelRadius)
        }
        .rotationEffect(.degrees(rotation))
    }

    // MARK: - Segment canvas

    private func segmentCanvas(center: CGPoint, wheelRadius: CGFloat) -> some View {
        Canvas { context, _ in
            let segmentCount = max(habits.count, 1)
            let segmentAngle = (2 * Double.pi) / Double(segmentCount)

            for index in habits.indices {
                let start = (Double(index) * segmentAngle) - (.pi / 2)
                let end   = start + segmentAngle

                var segmentPath = Path()
                segmentPath.move(to: center)
                segmentPath.addArc(
                    center: center,
                    radius: wheelRadius,
                    startAngle: .radians(start),
                    endAngle: .radians(end),
                    clockwise: false
                )
                segmentPath.closeSubpath()

                let base      = Color(hex: habits[index].colorHex)
                let lightened = base.adjustBrightness(0.16)
                let darkened  = base.adjustBrightness(-0.12)

                // Radial: warm-light near hub → full colour at mid-ring → slightly
                // deeper at the outer edge where the gold ring casts a shadow.
                context.fill(
                    segmentPath,
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: lightened, location: 0.00),
                            .init(color: base,      location: 0.60),
                            .init(color: darkened,  location: 1.00)
                        ]),
                        center: center,
                        startRadius: 0,
                        endRadius: wheelRadius
                    )
                )

                // Gold divider lines between segments
                let sep = Path { p in
                    p.move(to: center)
                    p.addLine(to: CGPoint(
                        x: center.x + CGFloat(cos(start)) * wheelRadius,
                        y: center.y + CGFloat(sin(start)) * wheelRadius
                    ))
                }
                context.stroke(sep,
                               with: .color(Color(hex: AppConstants.Colors.gold).opacity(0.85)),
                               lineWidth: 1.6)
            }

            // Thin dark rim right at the outer edge — separates segments from the ring
            // and adds a sense of physical containment (like paint stopping at a border).
            var rimPath = Path()
            rimPath.addEllipse(in: CGRect(
                x: center.x - wheelRadius,
                y: center.y - wheelRadius,
                width: wheelRadius * 2,
                height: wheelRadius * 2
            ))
            context.stroke(rimPath,
                           with: .color(Color(hex: "#5A3A08").opacity(0.28)),
                           lineWidth: 1.5)
        }
    }

    // MARK: - Segment icons

    private func segmentIcons(center: CGPoint, wheelRadius: CGFloat) -> some View {
        let segmentCount = max(habits.count, 1)
        let segmentAngle = (2 * Double.pi) / Double(segmentCount)
        let iconRadius   = wheelRadius * 0.60
        let iconSize     = wheelRadius * 0.17

        return ZStack {
            ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                let start     = (Double(index) * segmentAngle) - (.pi / 2)
                let iconAngle = start + (segmentAngle / 2)
                let x = center.x + CGFloat(cos(iconAngle)) * iconRadius
                let y = center.y + CGFloat(sin(iconAngle)) * iconRadius

                HabitIconView(iconName: habit.iconName, size: iconSize, foreground: .white)
                    .shadow(color: Color(hex: "#3D2606").opacity(0.50), radius: 2, x: 0, y: 1.5)
                    .position(x: x, y: y)
            }
        }
    }

    // MARK: - Floating warm ellipse ground shadow

    private func floatingShadow(size: CGFloat) -> some View {
        Ellipse()
            .fill(Color(hex: "#C8873A").opacity(0.16))
            .frame(width: size * 0.76, height: size * 0.09)
            .blur(radius: 18)
            .offset(y: size * 0.45)
            .allowsHitTesting(false)
    }

    // MARK: - Raised gold ring

    /// Three layers using the "hard offset shadow" approach (same as DuoBadgeBackground):
    ///   1. Deep-shadow ring  (offset y+3, no blur)  → visible ring thickness
    ///   2. Mid-shadow rim    (offset y+1, slightly wider) → smooth depth transition
    ///   3. Gold face ring    (angular gradient, the main surface)
    ///   4. Outer bright line (white highlight on the upper face)
    ///   5. Inner dark line   (shadow where ring meets the segments)
    private func raisedGoldRing(wheelRadius: CGFloat) -> some View {
        let rw  = wheelRadius * 0.155  // ring face width
        let pad = rw / 2 + 3           // padding to centre stroke on intended radius

        return ZStack {
            // Layer 1: deep hard shadow — makes the ring look thick and raised
            Circle()
                .stroke(Color(hex: "#3D2606"), lineWidth: rw + 2)
                .padding(pad)
                .offset(y: 3)

            // Layer 2: mid shadow — softens the hard edge slightly
            Circle()
                .stroke(Color(hex: "#6B4A10").opacity(0.60), lineWidth: rw + 1)
                .padding(pad)
                .offset(y: 1.5)

            // Layer 3: main ring face — angular gradient for metallic sheen
            Circle()
                .stroke(
                    AngularGradient(
                        stops: [
                            .init(color: Color(hex: "#FFF0A0"), location: 0.00),
                            .init(color: Color(hex: "#D4A843"), location: 0.16),
                            .init(color: Color(hex: "#8B6220"), location: 0.38),
                            .init(color: Color(hex: "#C9A84C"), location: 0.55),
                            .init(color: Color(hex: "#EDD050"), location: 0.72),
                            .init(color: Color(hex: "#FFF0A0"), location: 0.88),
                            .init(color: Color(hex: "#D4A843"), location: 1.00)
                        ],
                        center: .center
                    ),
                    lineWidth: rw
                )
                .padding(pad)

            // Layer 4: outer bevel highlight — the bright upper face of the ring's
            // outer chamfer. Strongest at the top (noon), fades toward the bottom.
            Circle()
                .stroke(
                    AngularGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.55), location: 0.00),
                            .init(color: Color.white.opacity(0.18), location: 0.28),
                            .init(color: Color.white.opacity(0.04), location: 0.50),
                            .init(color: Color.white.opacity(0.18), location: 0.72),
                            .init(color: Color.white.opacity(0.55), location: 1.00)
                        ],
                        center: .center
                    ),
                    lineWidth: 1.8
                )
                .padding(3)

            // Layer 5: inner shadow line — where the raised ring casts a shadow
            // inward onto the painted segment surface.
            Circle()
                .stroke(Color(hex: "#3D2606").opacity(0.38), lineWidth: 1.2)
                .padding(rw + 3)
        }
    }

    // MARK: - Polished gold dome hub

    private func centerHubDome(wheelRadius: CGFloat) -> some View {
        let hubSize = wheelRadius * 0.25

        return Button {
            onCenterTap?()
        } label: {
            ZStack {
                // Hard shadow — dome is also a raised 3D object
                Circle()
                    .fill(Color(hex: "#3D2606"))
                    .frame(width: hubSize, height: hubSize)
                    .offset(y: 2.5)

                // Dome face: radial gradient with highlight offset to top-left
                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: Color(hex: "#FFF8C0"), location: 0.00),
                                .init(color: Color(hex: "#EDD050"), location: 0.25),
                                .init(color: Color(hex: "#C9A84C"), location: 0.55),
                                .init(color: Color(hex: "#8B6220"), location: 1.00)
                            ],
                            center: UnitPoint(x: 0.30, y: 0.25),
                            startRadius: 0,
                            endRadius: hubSize * 0.55
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "#5A3A08").opacity(0.65), lineWidth: 1.8)
                    )
                    .frame(width: hubSize, height: hubSize)

                // Sparkle glint — the pinpoint highlight on polished metal
                Image(systemName: "sparkle")
                    .font(.system(size: hubSize * 0.30, weight: .light))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .offset(x: -hubSize * 0.09, y: -hubSize * 0.10)
            }
        }
        .buttonStyle(.plain)
        .allowsHitTesting(onCenterTap != nil)
    }

    // MARK: - Raised metallic pointer

    /// Replicates the DuoBadgeBackground "raised stamp" technique on the pointer:
    /// a hard dark shadow offset slightly below/behind the main shape gives it
    /// visible 3D thickness, as if it's a brass pin mounted on the ring surface.
    ///
    /// The left-edge highlight overlay (white → transparent gradient going left→right)
    /// creates the cylindrical "round metal pin" light-catch that distinguishes
    /// a premium pointer from a flat painted arrow.
    private func raisedPointer(wheelRadius: CGFloat) -> some View {
        let pW = wheelRadius * 0.165   // narrower than before = more elegant/precise
        let pH = wheelRadius * 0.310   // taller = more dramatic taper to the point

        return VStack(spacing: 0) {
            ZStack {
                // Hard shadow — the "thickness" of the cast-metal pointer
                PointerShape()
                    .fill(Color(hex: "#3D2606"))
                    .frame(width: pW, height: pH)
                    .offset(y: 2.5)

                // Base body: warm top-to-bottom gold gradient
                PointerShape()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(hex: "#FFF4B8"), location: 0.00),
                                .init(color: Color(hex: "#D4A843"), location: 0.28),
                                .init(color: Color(hex: "#C29030"), location: 0.60),
                                .init(color: Color(hex: "#8B6010"), location: 1.00)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: pW, height: pH)
                    // Left-edge highlight: simulates the light catch on a round
                    // metal pin — the brightest strip is on the leading (left) edge,
                    // fading to transparent by the centre of the shape.
                    .overlay(
                        PointerShape()
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.58), location: 0.00),
                                        .init(color: Color.white.opacity(0.22), location: 0.28),
                                        .init(color: Color.clear,               location: 0.54)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    // Right-edge shadow: the opposite side of the pin is in shadow
                    .overlay(
                        PointerShape()
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.clear,                        location: 0.46),
                                        .init(color: Color(hex: "#5A3A08").opacity(0.28), location: 0.75),
                                        .init(color: Color(hex: "#5A3A08").opacity(0.44), location: 1.00)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    // Crisp outline — the machined edge of a cast-metal pin
                    .overlay(
                        PointerShape()
                            .stroke(Color(hex: "#5A3A08").opacity(0.70), lineWidth: 1.6)
                    )
            }
            .rotationEffect(.degrees(pointerKick), anchor: .top)
            .animation(.interactiveSpring(response: 0.10, dampingFraction: 0.35), value: pointerKick)
            .offset(y: -2)

            Spacer()
        }
    }

    // MARK: - Peg wobble detection (drives haptics in SpinViewModel — unchanged)

    private func handlePegWobble(newRotation: Double) {
        let segmentCount = max(habits.count, 1)
        let normalized = ((newRotation.truncatingRemainder(dividingBy: 360)) + 360)
            .truncatingRemainder(dividingBy: 360)
        let index = Int(floor(normalized / (360.0 / Double(segmentCount))))
        guard index != lastPegIndex else { return }
        lastPegIndex = index
        pointerKick = -12
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(60))
            pointerKick = 5
            try? await Task.sleep(for: .milliseconds(60))
            pointerKick = 0
        }
    }
}

// MARK: - Pointer shape

/// Elongated pin: wide rounded cap at the top (attachment point to the ring),
/// body tapers gently through the middle, then draws in to a clean sharp point
/// at the bottom. The narrow body makes the left/right highlight gradients read
/// convincingly as a cylindrical metal pin rather than a flat painted arrow.
private struct PointerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = rect.width * 0.5   // cap radius — fills the full width at the top

        // Tip (bottom centre)
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))

        // Left side: sweeps up from tip to the base of the rounded cap
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + r),
            control1: CGPoint(x: rect.midX - rect.width * 0.28, y: rect.maxY - rect.height * 0.18),
            control2: CGPoint(x: rect.minX, y: rect.minY + r + rect.height * 0.28)
        )

        // Rounded top cap — full semicircle flush with the pointer width
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.minY + r),
            radius: r,
            startAngle: .radians(.pi),
            endAngle: .radians(0),
            clockwise: false
        )

        // Right side: mirror of the left, curving back down to the tip
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.minY + r + rect.height * 0.28),
            control2: CGPoint(x: rect.midX + rect.width * 0.28, y: rect.maxY - rect.height * 0.18)
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Colour helpers

private extension Color {
    func adjustBrightness(_ amount: CGFloat) -> Color {
        let ui = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }
        return Color(hue: Double(h),
                     saturation: Double(s),
                     brightness: Double(min(max(b + amount, 0), 1)),
                     opacity: Double(a))
    }
}

#Preview {
    let habits = [
        Habit(name: "Exercise",  iconName: "figure.run",           colorHex: AppConstants.Colors.habitGreen,    sortOrder: 0),
        Habit(name: "Meditate",  iconName: "figure.mind.and.body", colorHex: AppConstants.Colors.secondaryTeal, sortOrder: 1),
        Habit(name: "Read",      iconName: "book.fill",            colorHex: AppConstants.Colors.habitBlue,     sortOrder: 2),
        Habit(name: "Hydrate",   iconName: "drop.fill",            colorHex: AppConstants.Colors.habitOlive,    sortOrder: 3),
        Habit(name: "Gratitude", iconName: "heart.fill",           colorHex: AppConstants.Colors.habitPink,     sortOrder: 4)
    ]
    return WheelView(habits: habits, rotation: 0)
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color(hex: AppConstants.Colors.backgroundTop),
                    Color(hex: AppConstants.Colors.backgroundBottom)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
}
