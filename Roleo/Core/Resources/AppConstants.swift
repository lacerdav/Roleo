import Foundation

enum AppConstants {
    enum Store {
        static let monthlyProductID = "com.seunome.roleo.premium.monthly"
        static let annualProductID = "com.seunome.roleo.premium.annual"
        static let allProductIDs = [monthlyProductID, annualProductID]
    }

    enum AppGroup {
        static let suiteName = "group.com.seunome.roleo"
        static let widgetStreak = "widget.streak"
        static let widgetTodayHabitName = "widget.todayHabitName"
        static let widgetTodayHabitIcon = "widget.todayHabitIcon"
        static let widgetTodayCompleted = "widget.todayCompleted"
    }

    enum UserDefaultsKeys {
        static let hasSeededHabits = "hasSeededHabits"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let notificationHour = "notificationHour"
        static let notificationMinute = "notificationMinute"
        static let notificationsEnabled = "notificationsEnabled"
        static let spinSoundsEnabled = "spinSoundsEnabled"
        static let trialStartedAt = "trialStartedAt"
    }

    enum Points {
        static let perCompletion = 10
        static let streakBonus7 = 50
        static let streakBonus30 = 200
        static let streakBonus100 = 1000
    }

    enum Colors {
        static let backgroundTop = "#FDF6EC"
        static let backgroundBottom = "#FAF0DC"
        static let cardSurface = "#FFFFFF"
        static let cardElevated = "#FFF8F0"

        static let primaryOrange = "#FF6B35"
        static let primarySoft = "#FFF0E8"
        static let secondaryTeal = "#00A896"
        static let secondarySoft = "#E0F5F3"
        static let successGreen = "#2ECC8F"
        static let successSoft = "#E3F9F0"
        static let gold = "#C9A84C"
        static let goldBright = "#FFB800"
        static let goldSoft = "#FFF8E0"
        static let coral = "#FF6B6B"
        static let coralSoft = "#FFF0F0"

        static let textPrimary = "#1A1207"
        static let textSecondary = "#7A6652"
        static let textTertiary = "#B8A898"

        static let habitGreen = "#4CAF50"
        static let habitOlive = "#7B8B3E"
        static let habitBlue = "#64B5F6"
        static let habitOrange = "#FF7043"
        static let habitPink = "#E91E63"
        static let habitRed = "#C62828"

        // Premium palette (tuned for harmony; adjacent slots differ by >=40° hue).
        static let premiumSkyBlue = "#5BB8F5"
        static let premiumCoralRed = "#E8564A"
        static let premiumEmerald = "#2ECC8F"
        static let premiumWarmPurple = "#9B7FE8"
        static let premiumSunsetOrange = "#F5924E"
        static let premiumRosePink = "#F06292"
        static let premiumSteelTeal = "#4DB6AC"
        static let premiumGolden = "#F5C842"

        static let premiumPalette: [String] = [
            premiumSkyBlue,
            premiumCoralRed,
            premiumEmerald,
            premiumWarmPurple,
            premiumSunsetOrange,
            premiumRosePink,
            premiumSteelTeal,
            premiumGolden
        ]
    }

    enum SF {
        static let tabSpin = "circle.dotted.circle"
        static let tabHabits = "list.bullet.circle"
        static let tabHistory = "calendar.circle"
        static let tabSettings = "gearshape.circle"
    }
}
