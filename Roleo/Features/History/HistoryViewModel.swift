import Foundation
import Observation

/// Pure computation layer for the History feature. Stateless — takes the current
/// `[SpinResult]` snapshot from the View's `@Query` and produces derived data.
/// No SwiftData writes happen here.
@Observable
@MainActor
final class HistoryViewModel {

    // MARK: - Stats

    /// Reference implementation follows the streak algorithm defined in CLAUDE.md.
    /// Current-streak walks backwards from today, counting consecutive completed days.
    /// Longest-streak is a separate single-pass calculation so we can show a useful
    /// "all-time record" stat card (the spec's inline implementation reused `streak`
    /// for both, which is a bug we patch here without changing the public `UserStats`).
    func calculateStats(from results: [SpinResult]) -> UserStats {
        UserStatsCalculator.calculate(from: results)
    }

    // MARK: - Grouping

    /// Groups results by "Month Year" (e.g. "April 2026"), sorted most recent first.
    /// Inside each month, results are sorted by date descending.
    func groupByMonth(_ results: [SpinResult]) -> [(String, [SpinResult])] {
        guard !results.isEmpty else { return [] }

        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"

        let groups = Dictionary(grouping: results) { result -> Date in
            let components = calendar.dateComponents([.year, .month], from: result.date)
            return calendar.date(from: components) ?? result.date
        }

        return groups
            .sorted { $0.key > $1.key }
            .map { (monthStart, results) in
                let label = formatter.string(from: monthStart).capitalized
                let sortedResults = results.sorted { $0.date > $1.date }
                return (label, sortedResults)
            }
    }
}
