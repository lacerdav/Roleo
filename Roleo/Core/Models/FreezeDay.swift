import SwiftData
import Foundation

@Model
final class FreezeDay {
    var id: UUID
    var date: Date
    var createdAt: Date
    var weekIdentifier: String

    init(date: Date, weekIdentifier: String, createdAt: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.createdAt = createdAt
        self.weekIdentifier = weekIdentifier
    }
}
