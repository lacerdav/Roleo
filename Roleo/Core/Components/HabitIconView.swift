import SwiftUI
import UIKit

/// Renders a habit's icon as either an SF Symbol or an emoji/text glyph.
/// - If `iconName` resolves to a valid SF Symbol, it's rendered as `Image(systemName:)` tinted with `foreground`.
/// - Otherwise the string is rendered as text (used for emoji icons).
/// - Empty strings fall back to `sparkles`.
struct HabitIconView: View {
    let iconName: String
    var size: CGFloat = 18
    var foreground: Color = .white

    var body: some View {
        if isSystemSymbol {
            Image(systemName: iconName)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(foreground)
        } else if !iconName.isEmpty {
            Text(iconName)
                .font(.system(size: size + 4))
        } else {
            Image(systemName: "sparkles")
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(foreground)
        }
    }

    private var isSystemSymbol: Bool {
        UIImage(systemName: iconName) != nil
    }
}

extension String {
    /// `true` when the string resolves to a valid SF Symbol name.
    var isValidSFSymbol: Bool {
        UIImage(systemName: self) != nil
    }
}

#Preview {
    HStack(spacing: 16) {
        HabitIconView(iconName: "figure.run", size: 28, foreground: .white)
            .frame(width: 56, height: 56)
            .background(Circle().fill(.orange))
        HabitIconView(iconName: "🏃", size: 28)
            .frame(width: 56, height: 56)
            .background(Circle().fill(.green))
        HabitIconView(iconName: "📚", size: 28)
            .frame(width: 56, height: 56)
            .background(Circle().fill(.blue))
    }
    .padding()
}
