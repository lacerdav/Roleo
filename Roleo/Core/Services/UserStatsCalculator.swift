import Foundation

/// Shared stats calculator for streaks, completion totals, points, and rates.
/// Keeping this in Core prevents Spin and History from drifting apart.
enum UserStatsCalculator {
    static func calculate(
        from results: [SpinResult],
        freezeDays: [FreezeDay] = [],
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> UserStats {
        guard !results.isEmpty else { return .empty }

        let completed = results.filter(\.isCompleted)
        let completedDays = Set(
            completed.map { calendar.startOfDay(for: $0.date) }
        )
        let frozenDays = Set(
            freezeDays.map { calendar.startOfDay(for: $0.date) }
        )
        let activeDays = completedDays.union(frozenDays)

        let currentStreak = calculateCurrentStreak(
            activeDays: activeDays,
            calendar: calendar,
            now: now
        )

        let longestStreak = calculateLongestStreak(
            activeDays: activeDays,
            calendar: calendar
        )

        var points = completed.count * AppConstants.Points.perCompletion
        if currentStreak >= 7 { points += AppConstants.Points.streakBonus7 }
        if currentStreak >= 30 { points += AppConstants.Points.streakBonus30 }
        if currentStreak >= 100 { points += AppConstants.Points.streakBonus100 }

        return UserStats(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalCompleted: completed.count,
            totalPoints: points,
            completionRate: Double(completed.count) / Double(results.count)
        )
    }

    private static func calculateCurrentStreak(
        activeDays: Set<Date>,
        calendar: Calendar,
        now: Date
    ) -> Int {
        var streak = 0
        var checkDate = calendar.startOfDay(for: now)

        if !activeDays.contains(checkDate),
           let previous = calendar.date(byAdding: .day, value: -1, to: checkDate) {
            checkDate = previous
        }

        while activeDays.contains(checkDate) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                break
            }
            checkDate = previous
        }

        return streak
    }

    private static func calculateLongestStreak(activeDays: Set<Date>, calendar: Calendar) -> Int {
        var longestStreak = 0
        var runningStreak = 0
        var previousDay: Date?

        for day in activeDays.sorted() {
            if let previousDay,
               let expected = calendar.date(byAdding: .day, value: 1, to: previousDay),
               calendar.isDate(day, inSameDayAs: expected) {
                runningStreak += 1
            } else {
                runningStreak = 1
            }

            longestStreak = max(longestStreak, runningStreak)
            previousDay = day
        }

        return longestStreak
    }
}
