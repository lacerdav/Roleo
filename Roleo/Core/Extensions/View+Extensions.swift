import SwiftUI

// MARK: - WarmBackground

/// Applies the global warm-cream gradient behind any view.
/// Replaces the copy-pasted `ZStack { gradient; content }` pattern
/// that previously appeared in every top-level view.
struct WarmBackground: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: AppConstants.Colors.backgroundTop),
                    Color(hex: AppConstants.Colors.backgroundBottom)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            content
        }
    }
}

extension View {
    func warmBackground() -> some View {
        modifier(WarmBackground())
    }
}

// MARK: - WarmCard

struct WarmCard: ViewModifier {
    var radius: CGFloat = 20
    var level: Int = 1

    func body(content: Content) -> some View {
        content
            .background(Color(hex: "#FFFFFF"), in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Color(hex: "#1A1207").opacity(0.05), lineWidth: 0.5)
            )
            .shadow(
                color: Color(hex: "#C8873A").opacity(level == 1 ? 0.10 : 0.15),
                radius: level == 1 ? 12 : 20,
                x: 0,
                y: level == 1 ? 4 : 6
            )
            .shadow(
                color: Color(hex: "#C8873A").opacity(level == 1 ? 0.05 : 0.07),
                radius: level == 1 ? 4 : 6,
                x: 0,
                y: level == 1 ? 1 : 2
            )
    }
}

extension View {
    func warmCard(radius: CGFloat = 20, level: Int = 1) -> some View {
        modifier(WarmCard(radius: radius, level: level))
    }

    func orangeGlow(active: Bool) -> some View {
        self
            .shadow(
                color: Color(hex: AppConstants.Colors.primaryOrange).opacity(active ? 0.35 : 0.18),
                radius: active ? 16 : 8,
                x: 0,
                y: 0
            )
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: active)
    }
}

extension AnyTransition {
    static var addPanelFromTrigger: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.08, anchor: .topTrailing)
                .combined(with: .opacity)
                .combined(with: .offset(x: 30, y: -30)),
            removal: .scale(scale: 0.08, anchor: .topTrailing)
                .combined(with: .opacity)
                .combined(with: .offset(x: 30, y: -30))
        )
    }
}

extension Animation {
    static var addPanelSpring: Animation {
        .spring(response: 0.52, dampingFraction: 0.82)
    }
}
