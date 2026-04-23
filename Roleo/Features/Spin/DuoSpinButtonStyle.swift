import SwiftUI

// MARK: - DuoSpinButtonStyle

/// Duolingo-style 3D button: a darker "bottom-edge" rectangle sits below the
/// main slab. When pressed the slab slides down and the edge shrinks to 0,
/// giving the "button depressed into its socket" feel.
struct DuoSpinButtonStyle: ButtonStyle {
    let isSpinning: Bool

    private let cornerRadius: CGFloat = 16
    private let buttonHeight: CGFloat = 58
    private let edgeHeight:   CGFloat = 4
    private let faceColor = Color(hex: AppConstants.Colors.primaryOrange)
    private let edgeColor = Color(hex: "#C94B1A")

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && !isSpinning
        let translate: CGFloat       = pressed ? edgeHeight : 0
        let edgeVisibleHeight: CGFloat = pressed ? 0 : edgeHeight

        return ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(edgeColor)
                .frame(height: buttonHeight + edgeVisibleHeight)
                .opacity(isSpinning ? 0 : 1)

            configuration.label
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(faceColor)
                )
                .offset(y: translate)
        }
        .frame(height: buttonHeight + edgeHeight)
        .opacity(isSpinning ? 0.55 : 1)
        .animation(.easeOut(duration: 0.06), value: pressed)
        .animation(.easeOut(duration: 0.12), value: isSpinning)
    }
}
