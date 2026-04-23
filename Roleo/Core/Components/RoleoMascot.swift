import SwiftUI

/// Roleo's mascot: a friendly anthropomorphic spin wheel. The character lives
/// entirely in SwiftUI shapes so it scales crisply on every device and can be
/// tinted or animated without raster assets.
///
/// Expressions drive the eyes and mouth. The wheel body stays consistent so
/// users always recognize "Roleo" across onboarding, empty states, and the
/// result celebration.
struct RoleoMascot: View {
    enum Expression: Equatable {
        case happy
        case sleepy
        case excited
        case cheering
        case thinking
        case curious
    }

    var expression: Expression = .happy
    var size: CGFloat = 140
    /// When true, the mascot breathes (subtle scale loop). Disable for static
    /// previews or when Reduce Motion is on.
    var breathing: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathScale: CGFloat = 1.0
    @State private var bounce: CGFloat = 0

    private var shouldBreathe: Bool { breathing && !reduceMotion }
    private var shouldBounce: Bool { expression == .cheering || expression == .excited }

    var body: some View {
        ZStack {
            wheelBody
            face
                .offset(y: size * 0.02)
        }
        .frame(width: size, height: size)
        .scaleEffect(breathScale)
        .offset(y: bounce)
        .accessibilityHidden(true)
        .onAppear(perform: startIdleAnimations)
        .onChange(of: expression) { _, _ in startIdleAnimations() }
    }

    // MARK: Body

    private var wheelBody: some View {
        ZStack {
            // Gold ring — premium metal border (app icon DNA).
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: AppConstants.Colors.goldBright),
                            Color(hex: AppConstants.Colors.gold)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: size * 0.07
                )

            // Six colored segments arranged clockwise from the top.
            ForEach(0..<6, id: \.self) { index in
                WheelSegment(index: index, total: 6)
                    .fill(Color(hex: AppConstants.Colors.premiumPalette[index % AppConstants.Colors.premiumPalette.count]))
                    .opacity(0.92)
            }

            // Gold dividers between segments.
            ForEach(0..<6, id: \.self) { index in
                Rectangle()
                    .fill(Color(hex: AppConstants.Colors.gold))
                    .frame(width: size * 0.012, height: size * 0.42)
                    .offset(y: -size * 0.21)
                    .rotationEffect(.degrees(Double(index) * 60))
            }

            // Inner cream disc where the face lives.
            Circle()
                .fill(Color(hex: AppConstants.Colors.cardElevated))
                .frame(width: size * 0.58, height: size * 0.58)
                .overlay(
                    Circle()
                        .stroke(Color(hex: AppConstants.Colors.gold).opacity(0.45), lineWidth: 1.5)
                )
                .shadow(
                    color: Color(hex: "#C8873A").opacity(0.20),
                    radius: size * 0.05,
                    x: 0,
                    y: size * 0.02
                )

            // Top pointer (matches app icon).
            Triangle()
                .fill(Color(hex: AppConstants.Colors.primaryOrange))
                .frame(width: size * 0.1, height: size * 0.12)
                .offset(y: -size * 0.5)
                .shadow(color: Color(hex: "#C8873A").opacity(0.2), radius: 2, y: 1)
        }
        .shadow(color: Color(hex: "#C8873A").opacity(0.18), radius: size * 0.08, x: 0, y: size * 0.04)
    }

    // MARK: Face

    private var face: some View {
        VStack(spacing: size * 0.04) {
            HStack(spacing: size * 0.08) {
                eye(left: true)
                eye(left: false)
            }
            mouth
        }
    }

    @ViewBuilder
    private func eye(left: Bool) -> some View {
        let width = size * 0.08
        let height = size * 0.10

        switch expression {
        case .happy, .excited, .cheering:
            // Open oval eye with a small highlight.
            ZStack {
                Capsule()
                    .fill(Color(hex: AppConstants.Colors.textPrimary))
                    .frame(width: width, height: height)
                Circle()
                    .fill(Color.white)
                    .frame(width: width * 0.32, height: width * 0.32)
                    .offset(x: width * 0.15, y: -height * 0.2)
            }
        case .sleepy:
            // Gentle arc — closed eye.
            ClosedEyeShape()
                .stroke(Color(hex: AppConstants.Colors.textPrimary), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: width * 1.1, height: height * 0.5)
        case .thinking:
            // Half-lidded: oval clipped by a top bar.
            ZStack {
                Capsule()
                    .fill(Color(hex: AppConstants.Colors.textPrimary))
                    .frame(width: width, height: height)
                Rectangle()
                    .fill(Color(hex: AppConstants.Colors.cardElevated))
                    .frame(width: width, height: height * 0.45)
                    .offset(y: -height * 0.27)
            }
        case .curious:
            // Left bigger than right to read as "hmm?".
            Capsule()
                .fill(Color(hex: AppConstants.Colors.textPrimary))
                .frame(
                    width: width * (left ? 1.05 : 0.9),
                    height: height * (left ? 1.1 : 0.85)
                )
        }
    }

    @ViewBuilder
    private var mouth: some View {
        let mouthWidth = size * 0.18
        let mouthHeight = size * 0.08
        let color = Color(hex: AppConstants.Colors.textPrimary)

        switch expression {
        case .happy:
            SmileShape()
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: mouthWidth, height: mouthHeight * 0.6)
        case .excited, .cheering:
            // Open "o" mouth.
            Circle()
                .fill(color)
                .frame(width: mouthWidth * 0.55, height: mouthWidth * 0.55)
                .overlay(
                    Circle()
                        .fill(Color(hex: AppConstants.Colors.coral))
                        .frame(width: mouthWidth * 0.35, height: mouthWidth * 0.35)
                        .offset(y: mouthWidth * 0.08)
                )
        case .sleepy:
            // Tiny neutral line.
            Capsule()
                .fill(color)
                .frame(width: mouthWidth * 0.4, height: 3)
        case .thinking:
            // Offset small smirk.
            SmileShape()
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: mouthWidth * 0.55, height: mouthHeight * 0.35)
                .offset(x: mouthWidth * 0.15)
        case .curious:
            // Small oval.
            Capsule()
                .fill(color)
                .frame(width: mouthWidth * 0.35, height: mouthHeight * 0.35)
        }
    }

    // MARK: Animations

    private func startIdleAnimations() {
        breathScale = 1.0
        bounce = 0

        if shouldBreathe {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                breathScale = 1.025
            }
        }

        if shouldBounce && !reduceMotion {
            withAnimation(
                .spring(response: 0.45, dampingFraction: 0.55)
                .repeatForever(autoreverses: true)
            ) {
                bounce = -size * 0.03
            }
        }
    }
}

// MARK: Shapes

private struct WheelSegment: Shape {
    let index: Int
    let total: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let anglePerSegment = 360.0 / Double(total)
        let start = Angle.degrees(Double(index) * anglePerSegment - 90)
        let end = Angle.degrees(Double(index + 1) * anglePerSegment - 90)

        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        path.closeSubpath()
        return path
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

private struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY * 1.8)
        )
        return path
    }
}

private struct ClosedEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        return path
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 32) {
            ForEach(
                [RoleoMascot.Expression.happy, .sleepy, .excited, .cheering, .thinking, .curious],
                id: \.self
            ) { expression in
                VStack(spacing: 12) {
                    RoleoMascot(expression: expression, size: 140)
                    Text(String(describing: expression))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                }
            }
        }
        .padding(40)
    }
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

extension RoleoMascot.Expression: Hashable {}
