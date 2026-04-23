import SwiftUI

/// Reusable press feedback for any tappable surface that isn't already wearing
/// the 3D `DuoSpinButtonStyle`. Every interactive element in the app should
/// respond physically — this is the lightweight default.
///
/// - Scales to `pressedScale` while the finger is down.
/// - Springs back on release.
/// - Optional light haptic on press-down (default: on).
struct PressableCardStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.96
    var haptic: Bool = true
    var cornerRadius: CGFloat = 0

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .animation(
                .spring(response: 0.3, dampingFraction: 0.62),
                value: configuration.isPressed
            )
            .sensoryFeedback(
                .impact(weight: .light, intensity: 0.55),
                trigger: configuration.isPressed
            ) { _, isPressed in
                haptic && isPressed
            }
    }
}

extension ButtonStyle where Self == PressableCardStyle {
    /// Default pressable card. Use anywhere you'd normally write `.plain`.
    static var pressable: PressableCardStyle { PressableCardStyle() }

    static func pressable(scale: CGFloat = 0.96, haptic: Bool = true) -> PressableCardStyle {
        PressableCardStyle(pressedScale: scale, haptic: haptic)
    }
}
