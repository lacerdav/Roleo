import SwiftUI

/// Derived progression state (level, progress inside current level, color tier)
/// computed purely from a cumulative "tasks completed" count.
///
/// This lives in `Core/Services` because it is shared between `SpinView`
/// (header badge + post-completion XP animation) and `HistoryView`
/// (XP bar + badges). Do not duplicate this logic elsewhere.
struct XPProgressionState: Equatable {
    let level: Int
    let xpIntoCurrentLevel: Int
    let xpNeededForNextLevel: Int
    let tier: LevelColorTier

    var progress: Double {
        guard xpNeededForNextLevel > 0 else { return 0 }
        return Double(xpIntoCurrentLevel) / Double(xpNeededForNextLevel)
    }

    static func fromCompletedTasks(_ count: Int) -> XPProgressionState {
        var remainingTasks = max(0, count)
        var level = 1
        var xpIntoCurrentLevel = 0
        var xpNeeded = xpRequired(forLevel: level)

        while remainingTasks > 0 {
            let taskXp = xpPerTask(forLevel: level)
            xpIntoCurrentLevel += taskXp
            remainingTasks -= 1

            while xpIntoCurrentLevel >= xpNeeded {
                xpIntoCurrentLevel -= xpNeeded
                level += 1
                xpNeeded = xpRequired(forLevel: level)
            }
        }

        return XPProgressionState(
            level: level,
            xpIntoCurrentLevel: xpIntoCurrentLevel,
            xpNeededForNextLevel: xpNeeded,
            tier: LevelColorTier.forLevel(level)
        )
    }

    static func totalXP(forCompletedTasks count: Int) -> Int {
        var remainingTasks = max(0, count)
        var level = 1
        var xpIntoCurrentLevel = 0
        var xpNeeded = xpRequired(forLevel: level)
        var total = 0

        while remainingTasks > 0 {
            let earned = xpPerTask(forLevel: level)
            total += earned
            xpIntoCurrentLevel += earned
            remainingTasks -= 1

            while xpIntoCurrentLevel >= xpNeeded {
                xpIntoCurrentLevel -= xpNeeded
                level += 1
                xpNeeded = xpRequired(forLevel: level)
            }
        }

        return total
    }

    /// XP value awarded by the *next* task at the current level.
    /// Used by History to show per-row "+N XP" badges with realistic values.
    static func xpPerTask(atLevel level: Int) -> Int {
        xpPerTask(forLevel: level)
    }

    // Each level requires more XP than the previous one.
    private static func xpRequired(forLevel level: Int) -> Int {
        90 + (level * 20) + ((level - 1) * (level - 1) * 2)
    }

    // Task reward gets harder over time (diminishing XP per task).
    private static func xpPerTask(forLevel level: Int) -> Int {
        max(2, AppConstants.Points.perCompletion - ((level - 1) / 3))
    }
}

struct LevelColorTier: Equatable {
    let accent: Color
    let soft: Color

    static func forLevel(_ level: Int) -> LevelColorTier {
        let band = ((max(1, level) - 1) / 5)
        switch band {
        case 0:
            return LevelColorTier(
                accent: Color(hex: AppConstants.Colors.secondaryTeal),
                soft: Color(hex: AppConstants.Colors.secondarySoft)
            )
        case 1:
            return LevelColorTier(
                accent: Color(hex: AppConstants.Colors.primaryOrange),
                soft: Color(hex: AppConstants.Colors.primarySoft)
            )
        case 2:
            return LevelColorTier(
                accent: Color(hex: AppConstants.Colors.gold),
                soft: Color(hex: AppConstants.Colors.backgroundBottom)
            )
        case 3:
            return LevelColorTier(
                accent: Color(hex: AppConstants.Colors.habitPink),
                soft: Color(hex: AppConstants.Colors.habitPink).opacity(0.14)
            )
        default:
            return LevelColorTier(
                accent: Color(hex: AppConstants.Colors.successGreen),
                soft: Color(hex: AppConstants.Colors.successSoft)
            )
        }
    }
}
