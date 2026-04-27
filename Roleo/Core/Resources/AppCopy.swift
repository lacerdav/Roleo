import Foundation

/// Centralized warm, human copy for every user-facing string that shouldn't
/// sound like a system prompt. Anything that reads as generic ("No data",
/// "Operation failed") lives here so the tone stays consistent and is easy
/// to tune in one pass.
enum AppCopy {
    enum Empty {
        static let habitsTitle = "Let's add your first habit"
        static let habitsMessage = "Pick something small you can do every day. We'll take care of the rest."

        static let historyTitle = "Your streak starts today"
        static let historyMessage = "Complete your first habit and it'll show up here, warm and glowing."

        static let spinNotEnoughTitle = "I need a few more habits to spin"
        static let spinNotEnoughMessage = "Add at least four and I'll pick one for you every morning."
        static let spinNotEnoughCTA = "Add habits"

        static func historyProgressReflection(streak: Int, completed: Int) -> String {
            if streak > 1 {
                return "You showed up \(streak) days in a row. Keep this little rhythm alive."
            }
            if streak == 1 {
                return "You showed up today. That is the whole ritual."
            }
            if completed > 0 {
                return "Every completed spin still counts. Come back today to restart the rhythm."
            }
            return "Your first completed spin will start the story here."
        }
    }

    enum Success {
        /// Rotate through these after marking a habit done. Picked by day-of-year
        /// so the toast changes over time without repeating in a session.
        static let completionToasts: [String] = [
            "Nice one.",
            "You're on fire.",
            "Keep it rolling.",
            "That's the habit.",
            "Beautiful.",
            "One more in the books."
        ]

        static func completionToast(for date: Date = Date()) -> String {
            let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
            return completionToasts[day % completionToasts.count]
        }

        static let habitCreated = "Welcome to the wheel"
        static let habitUpdated = "Saved"
    }

    enum Errors {
        static let duplicateHabit = "Hmm, that name's already taken. Try another?"
        static let emptyHabitName = "Give it a name so I know what to cheer for."
        static let restoreFailed = "Couldn't reach the store. Mind trying again?"
    }

    enum Mascot {
        static let habitFormEmpty = "Pick something small. I'll cheer when it lands."
        static let habitFormReady = "This one feels ready for the wheel."
        static let habitFormDuplicate = "I already know one like that. Give this habit its own little name."

        static func reminderNudge(enabled: Bool) -> String {
            enabled
                ? "I'll tap your shoulder once a day, then get out of the way."
                : "Want a tiny daily nudge? I can help you remember the ritual."
        }
    }

    enum Habits {
        static let readyLabel = "Ready to spin"
        static let restingLabel = "Resting"

        static let addFirstCTA = "Add your first"
        static let addAnotherCTA = "Add another"

        static let rowHint = "Tap to edit · swipe to remove"

        static func readinessBuilding(active: Int, needed: Int) -> String {
            let remaining = max(0, needed - active)
            switch remaining {
            case needed:
                return "Add \(needed) habits so Roleo has enough to choose from"
            case 1:
                return "One more and Roleo can choose for you"
            default:
                return "\(remaining) more so the wheel has room to surprise you"
            }
        }

        static func readinessReady(active: Int) -> String {
            if active == 4 {
                return "You're set — the wheel's ready"
            }
            return "\(active) ready · let's spin"
        }

        // Delete confirmation — warmer, reassuring (never blames the user).
        static let deleteTitle = "Remove this habit?"
        static let deleteMessage = "It'll vanish from your list. You can always add it back later."
        static let deleteConfirm = "Remove"
        static let deleteCancel = "Keep it"
    }

    enum Spin {
        static let resultTitle = "Here's your habit for today"
        static let readyToComplete = "Ready when you are."
        static let alreadyCompleted = "Already done. Well played."
        static let markDoneCTA = "Done"
        static let closeCTA = "Close"

        // Spin button states — warm, never clinical.
        static let spinCTA = "SPIN"
        static let spinningCTA = "PICKING..."
        static let viewResultCTA = "SEE TODAY'S PICK"

        /// Rotating reassurance copy shown under the wheel while spinning,
        /// so users don't stare at silence for a second or two.
        static let spinningHints: [String] = [
            "Picking something good for you...",
            "Warming up the wheel...",
            "Giving the wheel a gentle nudge..."
        ]

        static func spinningHint(for date: Date = Date()) -> String {
            let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
            return spinningHints[day % spinningHints.count]
        }
    }

    enum Onboarding {
        static let welcomeTitle = "Hey, I'm Roleo."
        static let welcomeSubtitle = "Your habit wheel, once a day."
        static let welcomeCTA = "Let's go"

        static let mechanicTitle = "One habit. Every day."
        static let mechanicSubtitle = "Spin the wheel and I'll pick what you focus on. No decisions, no guilt."
        static let mechanicCTA = "Continue"

        static let notificationsTitle = "When should I nudge you?"
        static let notificationsSubtitle = "Pick a ritual time. I'll give you a gentle nudge, then get out of the way."
        static let notificationsCTA = "Allow notifications"
        static let notificationsSkip = "Maybe later"
    }

    enum Paywall {
        static let heroTitle = "Roleo Premium"
        static let heroSubtitle = "Keep your daily wheel, streak, and progress ritual going."
        static let ctaPrimary = "Unlock forever"
        static let trialHint = "3 days free, then one simple unlock"
    }
}
