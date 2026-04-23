import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = cleaned.hasPrefix("#") ? String(cleaned.dropFirst()) : cleaned

        guard normalized.count == 6, let value = Int(normalized, radix: 16) else {
            self = Color.clear
            return
        }

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0

        self = Color(red: red, green: green, blue: blue)
    }
}
