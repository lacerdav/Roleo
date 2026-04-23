import Foundation
import UserNotifications

/// Owns the single daily reminder notification. Body text rotates through a
/// pool of 5 messages, indexed by day-of-year, so back-to-back days feel fresh.
/// Call `scheduleDailyNotification(hour:minute:)` on app launch (when enabled)
/// to rotate the body as the day-of-year advances.
@MainActor
final class NotificationService {
    static let identifier = "roleo.daily.reminder"

    /// Rotating body strings — see CLAUDE.md > Notifications.
    private static let bodies = [
        "Time to spin your wheel! 🎡",
        "Your habit is waiting. Let's go!",
        "One spin. One habit. One step forward. 🌀",
        "Keep your streak alive today.",
        "Spin the wheel. Build the life. ✨"
    ]

    // MARK: - Authorization

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // MARK: - Scheduling

    func scheduleDailyNotification(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "Roleo"
        content.body = Self.todayBody()
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.identifier,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    func cancelNotifications() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.identifier])
    }

    // MARK: - Body rotation

    /// Selects today's copy deterministically from day-of-year so every launch
    /// on the same calendar day gets the same string.
    private static func todayBody() -> String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return bodies[(day - 1) % bodies.count]
    }
}
