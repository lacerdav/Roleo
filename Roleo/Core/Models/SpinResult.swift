import SwiftData
import Foundation

@Model
final class SpinResult {
    var id: UUID
    var date: Date
    var habitID: UUID
    var habitName: String
    var habitIconName: String
    var habitColorHex: String
    var isCompleted: Bool
    var completedAt: Date?

    init(date: Date, habit: Habit) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.habitID = habit.id
        self.habitName = habit.name
        self.habitIconName = habit.iconName
        self.habitColorHex = habit.colorHex
        self.isCompleted = false
        self.completedAt = nil
    }
}
