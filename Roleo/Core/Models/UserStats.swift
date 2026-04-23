import Foundation

struct UserStats: Equatable {
    var currentStreak: Int
    var longestStreak: Int
    var totalCompleted: Int
    var totalPoints: Int
    var completionRate: Double

    static let empty = UserStats(
        currentStreak: 0,
        longestStreak: 0,
        totalCompleted: 0,
        totalPoints: 0,
        completionRate: 0.0
    )
}
