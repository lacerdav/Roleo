import SwiftUI
import SwiftData
import UIKit
import UserNotifications

/// Phase 5 settings screen:
/// - **Reminders**: opt-in daily push with time picker. Requests permission on
///   first enable and mirrors system-level authorization changes.
/// - **Subscription**: live status from `StoreService` + restore purchases.
/// - **About**: app version + Privacy / Terms links.
///
/// Uses `Form` with `.scrollContentBackground(.hidden)` so the global warm
/// gradient shows through. All row colors come from `AppConstants.Colors`.
struct SettingsView: View {
    @Environment(StoreService.self) private var storeService
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \SpinResult.date, order: .reverse) private var results: [SpinResult]

    var isActive = true

    @AppStorage(AppConstants.UserDefaultsKeys.notificationsEnabled)
    private var notificationsEnabled = false

    @AppStorage(AppConstants.UserDefaultsKeys.notificationHour)
    private var notificationHour = 9

    @AppStorage(AppConstants.UserDefaultsKeys.notificationMinute)
    private var notificationMinute = 0

    @AppStorage(AppConstants.UserDefaultsKeys.spinSoundsEnabled)
    private var spinSoundsEnabled = true

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isRestoring = false
    @State private var showDeniedAlert = false
    @State private var restoreMessage: String?
    @State private var isPaywallPresented = false

    private let notifications = NotificationService()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            settingsForm
                .warmBackground()
                .navigationTitle("Settings")
        }
        .tint(Color(hex: AppConstants.Colors.primaryOrange))
        .task { await refreshAuthorizationStatus() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await refreshAuthorizationStatus() }
            }
        }
        .alert("Notifications are off", isPresented: $showDeniedAlert) {
            Button("Open Settings") { openSystemSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable notifications in iOS Settings to receive your daily reminder.")
        }
        .alert("Restore complete", isPresented: restoreMessageBinding) {
            Button("OK", role: .cancel) { restoreMessage = nil }
        } message: {
            Text(restoreMessage ?? "")
        }
        .sheet(isPresented: $isPaywallPresented) {
            PaywallView(onClose: { isPaywallPresented = false })
                .environment(storeService)
        }
    }

    private var restoreMessageBinding: Binding<Bool> {
        Binding(
            get: { restoreMessage != nil },
            set: { if !$0 { restoreMessage = nil } }
        )
    }

    // MARK: - Form

    private var settingsForm: some View {
        Form {
            remindersSection
            soundsSection
            subscriptionSection
            aboutSection
            #if DEBUG
            debugSection
            #endif
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Sounds

    private var soundsSection: some View {
        Section {
            Toggle(isOn: $spinSoundsEnabled) {
                Label {
                    Text("Wheel sounds")
                        .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                } icon: {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundStyle(Color(hex: AppConstants.Colors.primaryOrange))
                }
            }
            .tint(Color(hex: AppConstants.Colors.primaryOrange))
            .sensoryFeedback(.selection, trigger: spinSoundsEnabled)
        } header: {
            sectionHeader("Sounds")
        } footer: {
            Text("Plays a tick on each peg and a chime on the winning segment. Respects your ring/silent switch.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
        }
    }

    // MARK: - Reminders

    private var remindersSection: some View {
        Section {
            MascotNudge(
                message: AppCopy.Mascot.reminderNudge(enabled: notificationsEnabled),
                eyebrow: "ROLEO REMINDER",
                expression: notificationsEnabled ? .happy : .curious,
                accent: Color(hex: notificationsEnabled ? AppConstants.Colors.secondaryTeal : AppConstants.Colors.primaryOrange),
                active: isActive,
                compact: true
            )
            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 8, trailing: 0))
            .listRowBackground(Color.clear)

            Toggle(isOn: toggleBinding) {
                Label {
                    Text("Daily reminder")
                        .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                } icon: {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(Color(hex: AppConstants.Colors.primaryOrange))
                }
            }
            .tint(Color(hex: AppConstants.Colors.primaryOrange))
            .sensoryFeedback(.selection, trigger: notificationsEnabled)

            if notificationsEnabled && authorizationStatus == .authorized {
                DatePicker(
                    selection: reminderTimeBinding,
                    displayedComponents: .hourAndMinute
                ) {
                    Label {
                        Text("Time")
                            .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                    } icon: {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(Color(hex: AppConstants.Colors.secondaryTeal))
                    }
                }
            }

            if authorizationStatus == .denied {
                Button {
                    showDeniedAlert = true
                } label: {
                    Label {
                        Text("Notifications disabled in Settings")
                            .foregroundStyle(Color(hex: AppConstants.Colors.coral))
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color(hex: AppConstants.Colors.coral))
                    }
                }
            }
        } header: {
            sectionHeader("Reminders")
        } footer: {
            if notificationsEnabled && authorizationStatus == .authorized {
                Text("A gentle nudge daily to spin your wheel.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
            }
        }
    }

    // MARK: - Access

    private var subscriptionSection: some View {
        Section {
            HStack {
                Label {
                    Text("Status")
                        .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                } icon: {
                    Image(systemName: subscriptionIcon)
                        .foregroundStyle(subscriptionTint)
                }
                Spacer()
                Text(subscriptionStatusText)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(subscriptionTint)
            }

            if !storeService.isUnlocked {
                Button {
                    isPaywallPresented = true
                } label: {
                    Label {
                        Text(upgradeCTATitle)
                            .foregroundStyle(Color(hex: AppConstants.Colors.primaryOrange))
                            .font(.system(.body, design: .rounded).weight(.semibold))
                    } icon: {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Color(hex: AppConstants.Colors.goldBright))
                    }
                }
            }

            Button {
                Task { await restore() }
            } label: {
                HStack {
                    Label {
                        Text("Restore Purchases")
                    } icon: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .foregroundStyle(Color(hex: AppConstants.Colors.primaryOrange))
                    Spacer()
                    if isRestoring {
                        ProgressView()
                    }
                }
            }
            .disabled(isRestoring)
        } header: {
            sectionHeader("Access")
        } footer: {
            if !storeService.isUnlocked && storeService.isInTrial {
                let remaining = storeService.trialRemaining()
                Text("^[\(remaining) day](inflect: true) left in your free trial.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
            } else if !storeService.isUnlocked && !storeService.isInTrial {
                Text("Your free trial has ended. Unlock Roleo once to keep your streak going.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
            } else if storeService.isUnlocked {
                Text("Your one-time unlock is active on this Apple ID.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
            }
        }
    }

    private var upgradeCTATitle: String {
        storeService.isInTrial ? "Unlock Forever" : "Get Lifetime Access"
    }

    private var subscriptionStatusText: String {
        if storeService.isUnlocked { return "Lifetime unlocked" }
        if storeService.isInTrial { return "Free Trial" }
        return "Trial ended"
    }

    private var subscriptionIcon: String {
        if storeService.isUnlocked { return "crown.fill" }
        if storeService.isInTrial { return "sparkles" }
        return "exclamationmark.circle.fill"
    }

    private var subscriptionTint: Color {
        if storeService.isUnlocked {
            return Color(hex: AppConstants.Colors.goldBright)
        }
        if storeService.isInTrial {
            return Color(hex: AppConstants.Colors.primaryOrange)
        }
        return Color(hex: AppConstants.Colors.coral)
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Label {
                    Text("Version")
                        .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                } icon: {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color(hex: AppConstants.Colors.secondaryTeal))
                }
                Spacer()
                Text(appVersion)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
            }

            if let url = URL(string: "https://roleo.app/privacy") {
                Link(destination: url) {
                    Label {
                        Text("Privacy Policy")
                            .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                    } icon: {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(Color(hex: AppConstants.Colors.secondaryTeal))
                    }
                }
            }

            if let url = URL(string: "https://roleo.app/terms") {
                Link(destination: url) {
                    Label {
                        Text("Terms of Service")
                            .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                    } icon: {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(Color(hex: AppConstants.Colors.secondaryTeal))
                    }
                }
            }
        } header: {
            sectionHeader("About")
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Debug (DEBUG builds only)

    #if DEBUG
    @State private var debugRefreshTick = false

    private var debugSection: some View {
        Section {
            // Current trial status — live readout.
            HStack {
                Label {
                    Text("Trial status")
                        .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                } icon: {
                    Image(systemName: "clock.badge.questionmark")
                        .foregroundStyle(Color(hex: AppConstants.Colors.secondaryTeal))
                }
                Spacer()
                Text(debugTrialStatus)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                    .id(debugRefreshTick)
            }

            // Reset: wipes trialStartedAt so the next launch starts a fresh trial.
            Button {
                UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.trialStartedAt)
                debugRefreshTick.toggle()
            } label: {
                Label {
                    Text("Reset trial (fresh 3-day window)")
                        .foregroundStyle(Color(hex: AppConstants.Colors.primaryOrange))
                } icon: {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(Color(hex: AppConstants.Colors.primaryOrange))
                }
            }

            // Expire: sets trial start to 4 days ago so paywall fires immediately.
            Button {
                let expiredStart = Date().addingTimeInterval(-4 * 86_400)
                UserDefaults.standard.set(
                    expiredStart.timeIntervalSince1970,
                    forKey: AppConstants.UserDefaultsKeys.trialStartedAt
                )
                debugRefreshTick.toggle()
            } label: {
                Label {
                    Text("Expire trial now (force paywall)")
                        .foregroundStyle(Color(red: 0.78, green: 0.31, blue: 0.27))
                } icon: {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(Color(red: 0.78, green: 0.31, blue: 0.27))
                }
            }
        } header: {
            sectionHeader("🛠 Debug — removed before release")
        } footer: {
            Text("Only visible in DEBUG builds. These controls let you test the trial and paywall without reinstalling.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
        }
    }

    private var debugTrialStatus: String {
        let key = AppConstants.UserDefaultsKeys.trialStartedAt
        let interval = UserDefaults.standard.double(forKey: key)
        if interval == 0 { return "Not started" }
        let start = Date(timeIntervalSince1970: interval)
        let elapsed = Date().timeIntervalSince(start)
        let remaining = max(0, 3 * 86_400 - elapsed)
        let days = Int(ceil(remaining / 86_400))
        return remaining > 0 ? "\(days)d left" : "Expired"
    }
    #endif

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(.caption2, design: .rounded).weight(.bold))
            .tracking(1.2)
            .foregroundStyle(Color(hex: AppConstants.Colors.textTertiary))
    }

    // MARK: - Bindings

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { notificationsEnabled && authorizationStatus != .denied },
            set: { newValue in handleToggle(newValue) }
        )
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                var comps = DateComponents()
                comps.hour = notificationHour
                comps.minute = notificationMinute
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { newValue in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                notificationHour = comps.hour ?? 9
                notificationMinute = comps.minute ?? 0
                rescheduleIfActive()
            }
        )
    }

    // MARK: - Actions

    private func handleToggle(_ newValue: Bool) {
        if newValue {
            Task { await enableNotifications() }
        } else {
            notificationsEnabled = false
            notifications.cancelNotifications()
        }
    }

    private func enableNotifications() async {
        switch authorizationStatus {
        case .notDetermined:
            let granted = await notifications.requestPermission()
            await refreshAuthorizationStatus()
            notificationsEnabled = granted
            if granted {
                notifications.scheduleDailyNotification(
                    hour: notificationHour,
                    minute: notificationMinute
                )
                notifications.scheduleWeeklyDigest(completedThisWeek: completedCountForWeeklyDigest())
            }
        case .denied:
            notificationsEnabled = false
            showDeniedAlert = true
        case .authorized, .provisional, .ephemeral:
            notificationsEnabled = true
            notifications.scheduleDailyNotification(
                hour: notificationHour,
                minute: notificationMinute
            )
            notifications.scheduleWeeklyDigest(completedThisWeek: completedCountForWeeklyDigest())
        @unknown default:
            notificationsEnabled = false
        }
    }

    private func rescheduleIfActive() {
        guard notificationsEnabled, authorizationStatus == .authorized else { return }
        notifications.scheduleDailyNotification(
            hour: notificationHour,
            minute: notificationMinute
        )
        notifications.scheduleWeeklyDigest(completedThisWeek: completedCountForWeeklyDigest())
    }

    private func refreshAuthorizationStatus() async {
        let status = await notifications.authorizationStatus()
        authorizationStatus = status
        // If the user revoked permission from iOS Settings while we were away,
        // mirror that in our own toggle and clear pending requests.
        if status != .authorized, status != .provisional, status != .ephemeral {
            if notificationsEnabled {
                notificationsEnabled = false
                notifications.cancelNotifications()
            }
        }
    }

    private func restore() async {
        isRestoring = true
        await storeService.restorePurchases()
        isRestoring = false
        restoreMessage = storeService.isUnlocked
            ? "Welcome back — Roleo is unlocked."
            : "Couldn't find a lifetime unlock on this Apple ID."
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func completedCountForWeeklyDigest(now: Date = Date()) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        guard let start = calendar.date(byAdding: .day, value: -7, to: today) else {
            return 0
        }

        return results.reduce(into: 0) { count, result in
            let day = calendar.startOfDay(for: result.date)
            if result.isCompleted, day >= start, day < today {
                count += 1
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(StoreService())
}
