import Foundation
import SwiftData

@MainActor
enum StreakFreezeService {
    @discardableResult
    static func autoApplyIfNeeded(
        results: [SpinResult],
        freezeDays: [FreezeDay],
        context: ModelContext,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> FreezeDay? {
        let today = calendar.startOfDay(for: now)
        guard let missedDay = calendar.date(byAdding: .day, value: -1, to: today) else {
            return nil
        }

        let missedStart = calendar.startOfDay(for: missedDay)
        guard !containsActivity(on: missedStart, results: results, freezeDays: freezeDays, calendar: calendar) else {
            return nil
        }

        let weekIdentifier = weekIdentifier(for: missedStart, calendar: calendar)
        guard !freezeDays.contains(where: { $0.weekIdentifier == weekIdentifier }) else {
            return nil
        }

        guard let streakAnchor = calendar.date(byAdding: .day, value: -1, to: missedStart),
              streakLength(endingOn: streakAnchor, results: results, freezeDays: freezeDays, calendar: calendar) > 0 else {
            return nil
        }

        let freeze = FreezeDay(date: missedStart, weekIdentifier: weekIdentifier)
        context.insert(freeze)

        do {
            try context.save()
            return freeze
        } catch {
            context.delete(freeze)
            return nil
        }
    }

    static func weekIdentifier(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let year = components.yearForWeekOfYear ?? 0
        let week = components.weekOfYear ?? 0
        return "\(year)-W\(week)"
    }

    private static func containsActivity(
        on date: Date,
        results: [SpinResult],
        freezeDays: [FreezeDay],
        calendar: Calendar
    ) -> Bool {
        results.contains { calendar.isDate($0.date, inSameDayAs: date) }
            || freezeDays.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private static func streakLength(
        endingOn endDate: Date,
        results: [SpinResult],
        freezeDays: [FreezeDay],
        calendar: Calendar
    ) -> Int {
        let activeDays = Set(
            results.filter(\.isCompleted).map { calendar.startOfDay(for: $0.date) }
            + freezeDays.map { calendar.startOfDay(for: $0.date) }
        )

        var streak = 0
        var checkDate = calendar.startOfDay(for: endDate)

        while activeDays.contains(checkDate) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                break
            }
            checkDate = previous
        }

        return streak
    }
}
