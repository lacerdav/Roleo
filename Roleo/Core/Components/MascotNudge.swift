import SwiftUI

struct MascotNudge: View {
    let message: String
    var eyebrow: String? = nil
    var expression: RoleoMascot.Expression = .happy
    var accent: Color = Color(hex: AppConstants.Colors.primaryOrange)
    var active = true
    var compact = false

    var body: some View {
        HStack(alignment: .center, spacing: compact ? 9 : 12) {
            RoleoMascot(
                expression: expression,
                size: compact ? 42 : 52,
                active: active
            )
            .frame(width: compact ? 44 : 54, height: compact ? 44 : 54)

            VStack(alignment: .leading, spacing: 3) {
                if let eyebrow {
                    Text(eyebrow)
                        .font(.system(.caption2, design: .rounded).weight(.black))
                        .tracking(1.1)
                        .foregroundStyle(accent)
                }

                Text(message)
                    .font(.system(compact ? .caption : .subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, compact ? 11 : 13)
        .padding(.vertical, compact ? 10 : 12)
        .background(
            RoundedRectangle(cornerRadius: compact ? 16 : 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.14),
                            Color(hex: AppConstants.Colors.cardSurface).opacity(0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 16 : 18, style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    MascotNudge(
        message: "Pick something small. I'll cheer when it lands.",
        eyebrow: "ROLEO SAYS",
        expression: .cheering
    )
    .padding()
    .warmBackground()
}
