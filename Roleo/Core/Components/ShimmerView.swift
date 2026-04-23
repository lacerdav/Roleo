import SwiftUI

/// Warm cream → white → cream shimmer used for skeleton placeholders while
/// content is loading. Respects `accessibilityReduceMotion` by falling back
/// to a static warm tone.
struct ShimmerView: View {
    var cornerRadius: CGFloat = 12

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color(hex: AppConstants.Colors.cardElevated))
            .overlay {
                if !reduceMotion {
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.55),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: proxy.size.width * 0.6)
                        .offset(x: phase * proxy.size.width * 1.6)
                        .blendMode(.plusLighter)
                    }
                    .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .accessibilityHidden(true)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

/// Applies a shimmering overlay on top of any view while `isLoading` is true.
/// Keeps the original view in the hierarchy so layout stays stable.
struct ShimmerOverlay: ViewModifier {
    var isLoading: Bool
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .opacity(isLoading ? 0 : 1)
            .overlay {
                if isLoading {
                    ShimmerView(cornerRadius: cornerRadius)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

extension View {
    func shimmer(isLoading: Bool, cornerRadius: CGFloat = 12) -> some View {
        modifier(ShimmerOverlay(isLoading: isLoading, cornerRadius: cornerRadius))
    }
}

#Preview {
    VStack(spacing: 16) {
        ShimmerView(cornerRadius: 16)
            .frame(height: 80)
        ShimmerView(cornerRadius: 99)
            .frame(height: 44)
    }
    .padding()
    .background(Color(hex: AppConstants.Colors.backgroundTop))
}
