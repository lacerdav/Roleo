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
                .modelContainer(for: [Habit.self, SpinResult.self, FreezeDay.self])
                .task {
                    await storeService.loadProducts()
                    await storeService.checkEntitlements()
                }
        }
    }
}
