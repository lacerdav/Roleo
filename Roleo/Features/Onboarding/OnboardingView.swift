import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppConstants.UserDefaultsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(AppConstants.UserDefaultsKeys.notificationHour) private var notificationHour = 20
    @AppStorage(AppConstants.UserDefaultsKeys.notificationMinute) private var notificationMinute = 0
    @AppStorage(AppConstants.UserDefaultsKeys.notificationsEnabled) private var notificationsEnabled = false

    @State private var selectedPage = 0
    @State private var reminderDate = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    @State private var permissionRequested = false
    @State private var permissionGranted = false
    @State private var sparkleTick = 0
    @State private var pageAppearedTicks: [Int: Bool] = [:]

    private let notificationService = NotificationService()
    private let pageSpring = Animation.spring(response: 0.5, dampingFraction: 0.78)

    private var mascotExpression: RoleoMascot.Expression {
        switch selectedPage {
        case 0: return .happy
        case 1: return .excited
        default: return .happy
        }
    }

    var body: some View {
        VStack(spacing: 24) {
                // Persistent mascot hero — expression morphs as pages change so
                // the character feels like one continuous guide, not a decoration
                // that restarts every slide.
                ZStack {
                    RoleoMascot(expression: mascotExpression, size: 170)
                    SparkleBurst(trigger: sparkleTick)
                        .frame(width: 240, height: 240)
                }
                .frame(height: 200)
                .padding(.top, 20)
                .animation(pageSpring, value: mascotExpression)

                TabView(selection: $selectedPage) {
                    welcomePage.tag(0)
                    spinPreviewPage.tag(1)
                    notificationsPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .animation(pageSpring, value: selectedPage)

                actionBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
        }
        .warmBackground()
        .onAppear {
            reminderDate = Calendar.current.date(
                from: DateComponents(hour: notificationHour, minute: notificationMinute)
            ) ?? reminderDate
            markPageAppeared(0)
        }
        .onChange(of: selectedPage) { _, newValue in
            markPageAppeared(newValue)
            if newValue == 1 {
                sparkleTick += 1
            }
        }
    }

    private func markPageAppeared(_ page: Int) {
        withAnimation(pageSpring) {
            pageAppearedTicks[page] = true
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        let appeared = pageAppearedTicks[0] == true

        return VStack(spacing: 14) {
            Text(AppCopy.Onboarding.welcomeTitle)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(pageSpring.delay(0.05), value: appeared)

            Text(AppCopy.Onboarding.welcomeSubtitle)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(pageSpring.delay(0.15), value: appeared)

            Spacer(minLength: 0)
        }
        .padding(.top, 16)
    }

    private var spinPreviewPage: some View {
        let appeared = pageAppearedTicks[1] == true

        return VStack(spacing: 18) {
            VStack(spacing: 10) {
                Text(AppCopy.Onboarding.mechanicTitle)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(pageSpring.delay(0.05), value: appeared)

                Text(AppCopy.Onboarding.mechanicSubtitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)
                    .animation(pageSpring.delay(0.15), value: appeared)
            }

            VStack(spacing: 10) {
                habitPreviewRow(icon: "figure.run", title: "Exercise", colorHex: AppConstants.Colors.premiumCoralRed, selected: true)
                habitPreviewRow(icon: "book.fill", title: "Read", colorHex: AppConstants.Colors.premiumSkyBlue)
                habitPreviewRow(icon: "heart.fill", title: "Gratitude", colorHex: AppConstants.Colors.premiumRosePink)
            }
            .padding(16)
            .warmCard(radius: 22, level: 2)
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .animation(pageSpring.delay(0.25), value: appeared)

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
    }

    private var notificationsPage: some View {
        let appeared = pageAppearedTicks[2] == true

        return VStack(spacing: 18) {
            VStack(spacing: 10) {
                Text(AppCopy.Onboarding.notificationsTitle)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(pageSpring.delay(0.05), value: appeared)

                Text(AppCopy.Onboarding.notificationsSubtitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)
                    .animation(pageSpring.delay(0.15), value: appeared)
            }

            VStack(spacing: 0) {
                Label {
                    Text("Your ritual time")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                } icon: {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: AppConstants.Colors.primaryOrange))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.top, 12)

                DatePicker(
                    "Reminder time",
                    selection: $reminderDate,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .datePickerStyle(.wheel)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }
            .warmCard(radius: 20, level: 1)
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .animation(pageSpring.delay(0.25), value: appeared)

            if permissionRequested {
                Text(permissionGranted ? "Great — I'll see you at that time." : "No worries, you can enable this later in Settings.")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(
                        Color(
                            hex: permissionGranted
                                ? AppConstants.Colors.successGreen
                                : AppConstants.Colors.textSecondary
                        )
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
    }

    // MARK: - Action bar

    private var actionBar: some View {
        VStack(spacing: 12) {
            if selectedPage < 2 {
                Button {
                    withAnimation(pageSpring) {
                        selectedPage += 1
                    }
                } label: {
                    Text(selectedPage == 0 ? AppCopy.Onboarding.welcomeCTA : AppCopy.Onboarding.mechanicCTA)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .kerning(0.4)
                        .foregroundStyle(Color(hex: AppConstants.Colors.cardSurface))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(hex: AppConstants.Colors.primaryOrange))
                        )
                        .shadow(
                            color: Color(hex: AppConstants.Colors.primaryOrange).opacity(0.28),
                            radius: 16, x: 0, y: 8
                        )
                }
                .buttonStyle(.pressable)
            } else {
                Button {
                    Task { await requestPermissionThenFinish() }
                } label: {
                    Text(AppCopy.Onboarding.notificationsCTA)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .kerning(0.4)
                        .foregroundStyle(Color(hex: AppConstants.Colors.cardSurface))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(hex: AppConstants.Colors.primaryOrange))
                        )
                        .shadow(
                            color: Color(hex: AppConstants.Colors.primaryOrange).opacity(0.28),
                            radius: 16, x: 0, y: 8
                        )
                }
                .buttonStyle(.pressable)

                Button(AppCopy.Onboarding.notificationsSkip) {
                    finishOnboarding(enableNotifications: false)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                .buttonStyle(.pressable(scale: 0.94, haptic: false))
            }
        }
    }

    private func habitPreviewRow(icon: String, title: String, colorHex: String, selected: Bool = false) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: colorHex))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(hex: AppConstants.Colors.cardSurface))
                )

            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))

            Spacer()

            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(hex: AppConstants.Colors.successGreen))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    selected
                        ? Color(hex: AppConstants.Colors.primarySoft)
                        : Color(hex: AppConstants.Colors.cardElevated)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    selected
                        ? Color(hex: AppConstants.Colors.primaryOrange).opacity(0.35)
                        : Color.clear,
                    lineWidth: 1
                )
        )
    }

    @MainActor
    private func requestPermissionThenFinish() async {
        permissionRequested = true
        permissionGranted = await notificationService.requestPermission()
        finishOnboarding(enableNotifications: permissionGranted)
    }

    private func finishOnboarding(enableNotifications: Bool) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
        let hour = components.hour ?? 20
        let minute = components.minute ?? 0

        notificationHour = hour
        notificationMinute = minute
        notificationsEnabled = enableNotifications

        if enableNotifications {
            notificationService.scheduleDailyNotification(hour: hour, minute: minute)
        } else {
            notificationService.cancelNotifications()
        }

        hasCompletedOnboarding = true
        dismiss()
    }
}

#Preview {
    OnboardingView()
}
