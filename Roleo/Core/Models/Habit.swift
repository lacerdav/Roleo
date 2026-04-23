import SwiftData
import Foundation

@Model
final class Habit {
    var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var isActive: Bool
    var sortOrder: Int
    var createdAt: Date

    init(name: String, iconName: String, colorHex: String, isActive: Bool = true, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}
