import SwiftUI
import SwiftData

@main
struct RoleoApp: App {
    @State private var storeService = StoreService()

    init() {
        // Sensible defaults before @AppStorage / raw UserDefaults reads run.
        UserDefaults.standard.register(defaults: [
            AppConstants.UserDefaultsKeys.notificationHour: 9,
            AppConstants.UserDefaultsKeys.notificationMinute: 0,
            AppConstants.UserDefaultsKeys.notificationsEnabled: false,
            AppConstants.UserDefaultsKeys.spinSoundsEnabled: true
        ])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeService)
                .modelContainer(for: [Habit.self, SpinResult.self])
                .task {
                    await storeService.loadProducts()
                    await storeService.checkEntitlements()
                    await rescheduleDailyReminderIfNeeded()
                }
        }
    }

    /// Re-schedules the daily reminder on launch so the rotating body text
    /// updates as the day-of-year advances. No-op if the user has disabled
    /// reminders or has not granted permission.
    @MainActor
    private func rescheduleDailyReminderIfNeeded() async {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: AppConstants.UserDefaultsKeys.notificationsEnabled) else {
            return
        }

        let service = NotificationService()
        let status = await service.authorizationStatus()
        guard status == .authorized || status == .provisional || status == .ephemeral else {
            return
        }

        let hour = defaults.integer(forKey: AppConstants.UserDefaultsKeys.notificationHour)
        let minute = defaults.integer(forKey: AppConstants.UserDefaultsKeys.notificationMinute)
        service.scheduleDailyNotification(hour: hour, minute: minute)
    }
}
