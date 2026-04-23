import SwiftUI

// MARK: - DoneButtonCenterKey

/// Carries the DONE button's global-coordinate center up to SpinView so the
/// CelebrationOverlay can launch confetti from that exact point. Nil values
/// are ignored so dismiss animations don't wipe out the last known center.
struct DoneButtonCenterKey: PreferenceKey {
    static let defaultValue: CGPoint? = nil
    static func reduce(value: inout CGPoint?, nextValue: () -> CGPoint?) {
        value = nextValue() ?? value
    }
}

// MARK: - SpinResultModalView

/// Modal card shown after the wheel stops. Presents the selected habit, lets
/// the user mark it done, and fires `onMarkDone` / `onClose` callbacks.
///
/// Extracted from SpinView to keep that file focused on the wheel mechanic.
struct SpinResultModalView: View {
    let result: SpinResult
    let sparkleTick: Int
    let completionToast: String
    let onMarkDone: () -> Void
    let onClose: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            // Warm amber-tinted backdrop — never cold black.
            RadialGradient(
                colors: [
                    Color(hex: "#1A1207").opacity(0.45),
                    Color(hex: "#C8873A").opacity(0.35)
                ],
                center: .center,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()
            .onTapGesture(perform: onClose)

            VStack(spacing: 18) {
                RoleoMascot(
                    expression: result.isCompleted ? .happy : .cheering,
                    size: 84
                )
                .padding(.top, 4)
                .onAppear {
                    withAnimation { appeared = true }
                }

                Text(AppCopy.Spin.resultTitle)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .kerning(0.3)
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                    .textCase(.uppercase)

                VStack(spacing: 12) {
                    ZStack {
                        SparkleBurst(trigger: sparkleTick)
                            .frame(width: 140, height: 140)

                        Circle()
                            .fill(Color(hex: result.habitColorHex))
                            .frame(width: 76, height: 76)
                            .overlay(
                                HabitIconView(
                                    iconName: result.habitIconName,
                                    size: 34,
                                    foreground: Color(hex: AppConstants.Colors.cardSurface)
                                )
                            )
                            .shadow(
                                color: Color(hex: result.habitColorHex).opacity(0.35),
                                radius: 16, x: 0, y: 8
                            )
                            .scaleEffect(appeared ? 1.0 : 0)
                            .animation(
                                .spring(response: 0.45, dampingFraction: 0.62),
                                value: appeared
                            )
                    }

                    Text(result.habitName)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.78).delay(0.18),
                            value: appeared
                        )

                    Text(result.isCompleted ? completionToast : AppCopy.Spin.readyToComplete)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .animation(
                            .easeOut(duration: 0.35).delay(0.30),
                            value: appeared
                        )
                }

                if result.isCompleted {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .symbolEffect(.bounce, value: sparkleTick)
                        Text(AppCopy.Spin.alreadyCompleted)
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.successGreen))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(hex: AppConstants.Colors.successSoft))
                    )
                } else {
                    Button(action: onMarkDone) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text(AppCopy.Spin.markDoneCTA)
                                .textCase(.uppercase)
                                .kerning(1.6)
                        }
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: AppConstants.Colors.cardSurface))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(hex: AppConstants.Colors.successGreen))
                        )
                        .shadow(
                            color: Color(hex: AppConstants.Colors.successGreen).opacity(0.32),
                            radius: 14, x: 0, y: 6
                        )
                        // Capture the button's global center so CelebrationOverlay
                        // can launch confetti from this exact point.
                        .background(
                            GeometryReader { proxy in
                                let frame = proxy.frame(in: .global)
                                Color.clear.preference(
                                    key: DoneButtonCenterKey.self,
                                    value: CGPoint(x: frame.midX, y: frame.midY)
                                )
                            }
                        )
                    }
                    .buttonStyle(.pressable)
                }

                Button(action: onClose) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                        Text(AppCopy.Spin.closeCTA)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color(hex: AppConstants.Colors.textSecondary).opacity(0.08))
                    )
                }
                .buttonStyle(.pressable(scale: 0.94, haptic: false))
            }
            .padding(24)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(hex: AppConstants.Colors.cardSurface))
            )
            .warmCard(radius: 28, level: 2)
            .padding(.horizontal, 20)
        }
    }
}
