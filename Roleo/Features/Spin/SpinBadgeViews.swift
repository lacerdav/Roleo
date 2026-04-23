import SwiftUI

// MARK: - DuoBadgeBackground

/// Duolingo-style badge chrome: a solid-color rim sits 2pt below the filled
/// shape, creating a "hard shadow" without blurring text or icons.
struct DuoBadgeBackground<Fill: ShapeStyle>: View {
    let fill: Fill
    let border: Color
    let cornerRadius: CGFloat
    var offset: CGFloat = 2

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(border)
                .offset(y: offset)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(fill)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(border, lineWidth: 2)
                )
        }
    }
}

// MARK: - FlameFlickerEffect

/// Applies SF Symbol's variable-color iterative effect to create a subtle
/// flame flicker. Gated on `enabled` so Reduce Motion users get a still flame.
struct FlameFlickerEffect: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.symbolEffect(.variableColor.iterative.reversing, options: .repeating)
        } else {
            content
        }
    }
}

// MARK: - StreakBadgeView

/// Flame badge always visible in the SpinView header.
/// Active state (streak > 0): vivid orange, animated flicker, bump on gain.
/// Dormant state (streak = 0): muted warm-grey — shows the mechanic exists
/// and motivates the user to start their streak today.
struct StreakBadgeView: View {
    let streak: Int
    let streakBump: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isActive: Bool { streak > 0 }
    private var accessibilityText: String {
        streak == 1 ? "1-day streak" : "\(streak)-day streak"
    }

    // Active colours
    private let flameDeep = Color(hex: "#E65100")
    private let flameMid  = Color(hex: "#FF8A3D")
    private let flameHigh = Color(hex: "#FFC95C")
    private let border    = Color(hex: "#E8923A")

    // Dormant colours
    private let dormantFlame  = Color(hex: AppConstants.Colors.textTertiary)
    private let dormantBorder = Color(hex: AppConstants.Colors.textTertiary)

    var body: some View {
        let surfaceGradient = LinearGradient(
            colors: isActive
                ? [Color(hex: "#FFF7E8"), Color(hex: "#FFE3BF")]
                : [Color(hex: "#F5F0EA"), Color(hex: "#EDE8E0")],
            startPoint: .top,
            endPoint: .bottom
        )

        HStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .font(.system(size: 22, weight: .black))
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    isActive
                        ? AnyShapeStyle(LinearGradient(
                            colors: [flameHigh, flameMid, flameDeep],
                            startPoint: .top,
                            endPoint: .bottom))
                        : AnyShapeStyle(dormantFlame.opacity(0.55))
                )
                .modifier(FlameFlickerEffect(enabled: isActive && !reduceMotion))
                .scaleEffect(streakBump ? 1.28 : 1.0)
                .rotationEffect(.degrees(streakBump ? -10 : 0))
                .shadow(
                    color: isActive ? flameDeep.opacity(0.25) : .clear,
                    radius: 3, y: 1
                )

            VStack(alignment: .leading, spacing: -1) {
                Text("\(streak)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(isActive ? flameDeep : dormantFlame.opacity(0.60))
                    .contentTransition(.numericText())
                    .kerning(-0.3)
                Text("DAY STREAK")
                    .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        isActive ? flameDeep.opacity(0.65) : dormantFlame.opacity(0.40)
                    )
                    .kerning(0.8)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            DuoBadgeBackground(
                fill: surfaceGradient,
                border: isActive ? border : dormantBorder.opacity(0.35),
                cornerRadius: 22
            )
        )
        .scaleEffect(streakBump ? 1.08 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isActive)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isActive ? accessibilityText : "No active streak")
    }
}

// MARK: - LevelBadgeView

/// Teal/colored level badge with an XP progress bar — shown in the header
/// alongside the streak badge.
struct LevelBadgeView: View {
    let level: Int
    let xpProgressInLevel: Int
    let xpForNextLevel: Int
    let xpProgress: Double
    let levelAccent: Color
    let levelSoft: Color

    var body: some View {
        let surfaceGradient = LinearGradient(
            colors: [levelSoft.opacity(0.95), levelSoft.opacity(0.75)],
            startPoint: .top,
            endPoint: .bottom
        )
        let barFill = LinearGradient(
            colors: [levelAccent.opacity(0.82), levelAccent],
            startPoint: .leading,
            endPoint: .trailing
        )

        HStack(spacing: 10) {
            ZStack {
                Circle().fill(levelAccent)
                Circle().stroke(Color.white.opacity(0.55), lineWidth: 1.5).padding(1.5)
                Text("\(level)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .frame(width: 30, height: 30)
            .shadow(color: levelAccent.opacity(0.35), radius: 3, y: 2)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Text("LEVEL")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(levelAccent.opacity(0.7))
                        .kerning(0.8)

                    Spacer(minLength: 6)

                    HStack(spacing: 2) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 8, weight: .heavy))
                            .symbolEffect(.bounce, value: level)
                        Text("\(xpProgressInLevel)")
                            .contentTransition(.numericText())
                        Text("/\(xpForNextLevel)")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(levelAccent.opacity(0.85))
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(levelAccent.opacity(0.18))
                        Capsule()
                            .fill(barFill)
                            .frame(width: max(6, proxy.size.width * xpProgress))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
                                    .padding(0.75)
                            )
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: xpProgress)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(width: 175, alignment: .leading)
        .background(DuoBadgeBackground(fill: surfaceGradient, border: levelAccent, cornerRadius: 22))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Level \(level), \(xpProgressInLevel) of \(xpForNextLevel) XP")
    }
}

// MARK: - XPGainBadge

/// Floating "+N XP" badge that appears after a habit is marked done.
struct XPGainBadge: View {
    let amount: Int
    let accent: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            Text("+\(amount) XP")
        }
        .font(.system(size: 20, weight: .black, design: .rounded))
        .foregroundStyle(accent)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.98), Color.white.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(Capsule().stroke(accent.opacity(0.35), lineWidth: 1.2))
        .shadow(color: accent.opacity(0.38), radius: 16, x: 0, y: 8)
    }
}

// MARK: - LevelUpBadge

/// Floating "Level Up!" banner shown alongside XPGainBadge when the user
/// crosses a level threshold.
struct LevelUpBadge: View {
    let level: Int
    let accent: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "crown.fill")
            Text("Level Up!  Lv \(level)")
        }
        .font(.system(size: 14, weight: .heavy, design: .rounded))
        .foregroundStyle(accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.white.opacity(0.95)))
        .overlay(Capsule().stroke(accent.opacity(0.25), lineWidth: 1))
        .shadow(color: accent.opacity(0.28), radius: 10, x: 0, y: 4)
    }
}
