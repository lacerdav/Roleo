import SwiftUI
import SwiftData
import WidgetKit

struct SpinView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query(sort: \SpinResult.date, order: .reverse) private var results: [SpinResult]
    @State private var viewModel = SpinViewModel()

    // Overlay state
    @State private var showCelebration = false
    @State private var rewardHideTask: Task<Void, Never>?
    @State private var showResultModal = false
    @State private var lastPresentedResultID: UUID?
    @State private var latestXPGain = 0
    @State private var showXPGain = false
    @State private var showLevelUp = false

    // Animation triggers
    @State private var resultSparkleTick = 0
    @State private var cachedCompletionToast = AppCopy.Success.completionToast()
    @State private var cachedSpinningHint = AppCopy.Spin.spinningHint()
    @State private var headerAppeared = false
    @State private var idleBreath = false
    @State private var readyPulse = false
    @State private var streakBump = false

    /// Captured DONE-button center — used as confetti origin.
    @State private var doneButtonCenter: CGPoint?

#if DEBUG
    private let allowSpinReplayForTesting = true
#else
    private let allowSpinReplayForTesting = false
#endif

    private var activeHabits: [Habit] { habits.filter(\.isActive) }

    private var canSpinNow: Bool {
        (viewModel.todayResult == nil || allowSpinReplayForTesting) && !viewModel.isSpinning
    }

    private var resultsStatsSignature: String {
        results
            .map { result in
                "\(result.id.uuidString)|\(result.date.timeIntervalSinceReferenceDate)|\(result.isCompleted)"
            }
            .joined(separator: ",")
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 8)

            if activeHabits.count < 4 {
                notEnoughHabitsState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                wheelArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .warmBackground()
        .safeAreaInset(edge: .bottom) {
            if activeHabits.count >= 4 {
                spinButton
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            }
        }
        // Celebration confetti — no entrance animation so it lands with the audio.
        .overlay(alignment: .top) {
            if showCelebration {
                CelebrationOverlay(origin: doneButtonCenter)
                    .allowsHitTesting(false)
                    .transition(.asymmetric(insertion: .identity, removal: .opacity))
            }
        }
        // XP gain badge
        .overlay(alignment: .top) {
            if showXPGain {
                XPGainBadge(amount: latestXPGain, accent: viewModel.levelAccent)
                    .padding(.top, 78)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.72)
                                .combined(with: .move(edge: .top))
                                .combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
        }
        // Level-up badge
        .overlay(alignment: .top) {
            if showLevelUp {
                LevelUpBadge(level: viewModel.currentLevel, accent: viewModel.levelAccent)
                    .padding(.top, 128)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.75).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
        }
        // Result modal
        .overlay {
            if showResultModal, let result = viewModel.todayResult {
                SpinResultModalView(
                    result: result,
                    sparkleTick: resultSparkleTick,
                    completionToast: cachedCompletionToast,
                    onMarkDone: {
                        viewModel.markComplete(context: modelContext, results: results)
                        updateWidgetStreak()
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                            showResultModal = false
                        }
                    },
                    onClose: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showResultModal = false
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: viewModel.didStartSpin)
        .sensoryFeedback(.impact(weight: .heavy), trigger: viewModel.didCompleteSpin)
        .sensoryFeedback(.success, trigger: viewModel.didCompleteHabit)
        .onPreferenceChange(DoneButtonCenterKey.self) { center in
            if let center { doneButtonCenter = center }
        }
        .onAppear {
            viewModel.loadTodayResult(context: modelContext)
            viewModel.updateDerivedStats(results: results)
            updateWidgetStreak()
            lastPresentedResultID = viewModel.todayResult?.id
            idleBreath = true
            readyPulse = true
            if !headerAppeared {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(60))
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                        headerAppeared = true
                    }
                }
            }
        }
        .onChange(of: resultsStatsSignature) { _, _ in
            let oldStreak = viewModel.currentStreak
            viewModel.updateDerivedStats(results: results)
            updateWidgetStreak()

            // Celebrate streak growth with a brief badge bump.
            if viewModel.currentStreak > oldStreak {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { streakBump = true }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(420))
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { streakBump = false }
                }
            }
        }
        .onChange(of: viewModel.isSpinning) { _, isNowSpinning in
            if isNowSpinning {
                cachedSpinningHint = AppCopy.Spin.spinningHint()
            }
        }
        .onChange(of: viewModel.didStartSpin) { _, _ in
            withAnimation(.easeOut(duration: 0.16)) { showResultModal = false }
        }
        .onChange(of: viewModel.didCompleteSpin) { _, _ in
            guard !viewModel.isSpinning else { return }
            guard let resultID = viewModel.todayResult?.id else { return }
            guard resultID != lastPresentedResultID else { return }
            lastPresentedResultID = resultID

            Task {
                try? await Task.sleep(for: .milliseconds(120))
                guard !viewModel.isSpinning else { return }
                await MainActor.run {
                    cachedCompletionToast = AppCopy.Success.completionToast()
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                        showResultModal = true
                    }
                    resultSparkleTick += 1
                }
            }
        }
        .onChange(of: viewModel.didCompleteHabit) { _, _ in
            let newCount = viewModel.completedTasksCount
            let oldCount = max(0, newCount - 1)
            let oldState = XPProgressionState.fromCompletedTasks(oldCount)
            let newState = XPProgressionState.fromCompletedTasks(newCount)
            let gain = XPProgressionState.totalXP(forCompletedTasks: newCount)
                     - XPProgressionState.totalXP(forCompletedTasks: oldCount)

            latestXPGain = gain

            rewardHideTask?.cancel()

            SoundService.shared.play(.celebrate)
            var instantTxn = Transaction(animation: nil)
            instantTxn.disablesAnimations = true
            withTransaction(instantTxn) { showCelebration = true }

            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                showXPGain = gain > 0
                showLevelUp = newState.level > oldState.level
            }

            rewardHideTask = Task {
                try? await Task.sleep(for: .seconds(2.8))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation(.easeIn(duration: 0.28)) {
                        showCelebration = false
                        showXPGain = false
                        showLevelUp = false
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(spacing: 12) {
            StreakBadgeView(streak: viewModel.currentStreak, streakBump: streakBump)
                .opacity(headerAppeared || reduceMotion ? 1 : 0)
                .offset(y: headerAppeared || reduceMotion ? 0 : -10)

            Spacer()

            LevelBadgeView(
                level: viewModel.currentLevel,
                xpProgressInLevel: viewModel.xpProgressInLevel,
                xpForNextLevel: viewModel.xpForNextLevel,
                xpProgress: viewModel.xpProgress,
                levelAccent: viewModel.levelAccent,
                levelSoft: viewModel.levelSoft
            )
            .opacity(headerAppeared || reduceMotion ? 1 : 0)
            .offset(y: headerAppeared || reduceMotion ? 0 : -10)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.2)
                    : .spring(response: 0.55, dampingFraction: 0.78).delay(0.08),
                value: headerAppeared
            )
        }
    }

    private var wheelArea: some View {
        GeometryReader { geometry in
            let wheelSize = min(geometry.size.width, geometry.size.height) * 0.98
            ZStack {
                // Idle breath glow behind the wheel.
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 160/255, blue: 100/255)
                                    .opacity(idleBreath ? 0.26 : 0.16),
                                .clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: wheelSize * 0.65
                        )
                    )
                    .frame(width: wheelSize * 1.2, height: wheelSize * 1.2)
                    .scaleEffect(idleBreath ? 1.04 : 1.0)
                    .allowsHitTesting(false)
                    .animation(
                        reduceMotion || viewModel.isSpinning
                            ? .default
                            : .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                        value: idleBreath
                    )

                // Ready-state pulse ring.
                if canSpinNow && !reduceMotion {
                    Circle()
                        .stroke(
                            Color(hex: AppConstants.Colors.primaryOrange)
                                .opacity(readyPulse ? 0.0 : 0.35),
                            lineWidth: 2
                        )
                        .frame(
                            width:  wheelSize * (readyPulse ? 1.12 : 0.98),
                            height: wheelSize * (readyPulse ? 1.12 : 0.98)
                        )
                        .allowsHitTesting(false)
                        .animation(
                            .easeOut(duration: 1.8).repeatForever(autoreverses: false),
                            value: readyPulse
                        )
                }

                WheelView(
                    habits: activeHabits,
                    rotation: viewModel.wheelRotation,
                    onCenterTap: { triggerSpinAction() }
                )
                .frame(width: wheelSize, height: wheelSize)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .overlay(alignment: .bottom) {
                if viewModel.isSpinning {
                    Text(cachedSpinningHint)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(hex: AppConstants.Colors.cardSurface).opacity(0.85))
                        )
                        .shadow(color: Color(hex: "#C8873A").opacity(0.08), radius: 10, x: 0, y: 4)
                        .padding(.bottom, 8)
                        .transition(.opacity.combined(with: .offset(y: 8)))
                }
            }
        }
    }

    private var spinButton: some View {
        Button { triggerSpinAction() } label: {
            HStack(spacing: 10) {
                if viewModel.isSpinning {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .bold))
                }
                Text(spinButtonTitle)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .kerning(1.5)
                    .contentTransition(.opacity)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
        }
        .buttonStyle(DuoSpinButtonStyle(isSpinning: viewModel.isSpinning))
        .background(
            Capsule()
                .fill(Color(hex: AppConstants.Colors.primaryOrange))
                .blur(radius: 22)
                .opacity(canSpinNow && !reduceMotion ? (readyPulse ? 0.42 : 0.18) : 0)
                .scaleEffect(canSpinNow && !reduceMotion ? (readyPulse ? 1.08 : 0.92) : 1.0)
                .animation(
                    canSpinNow && !reduceMotion
                        ? .easeInOut(duration: 1.6).repeatForever(autoreverses: true)
                        : .default,
                    value: readyPulse
                )
                .animation(.easeOut(duration: 0.25), value: canSpinNow)
                .allowsHitTesting(false)
        )
        .padding(.bottom, 20)
        .disabled(viewModel.isSpinning)
        .accessibilityLabel(spinButtonAccessibilityLabel)
        .accessibilityHint(spinButtonAccessibilityHint)
    }

    private var spinButtonTitle: String {
        if viewModel.isSpinning { return AppCopy.Spin.spinningCTA }
        return (viewModel.todayResult == nil || allowSpinReplayForTesting)
            ? AppCopy.Spin.spinCTA
            : AppCopy.Spin.viewResultCTA
    }

    private var spinButtonAccessibilityLabel: String {
        if viewModel.isSpinning { return "Picking today's habit" }
        return viewModel.todayResult == nil ? "Spin the wheel" : "See today's pick"
    }

    private var spinButtonAccessibilityHint: String {
        if viewModel.isSpinning { return "Please wait for the wheel to stop." }
        return viewModel.todayResult == nil
            ? "Chooses one active habit for today."
            : "Opens today's selected habit."
    }

    private var notEnoughHabitsState: some View {
        VStack(spacing: 20) {
            RoleoMascot(expression: .sleepy, size: 150)

            VStack(spacing: 8) {
                Text(AppCopy.Empty.spinNotEnoughTitle)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                    .multilineTextAlignment(.center)

                Text(AppCopy.Empty.spinNotEnoughMessage)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Actions

    private func triggerSpinAction() {
        guard allowSpinReplayForTesting || viewModel.todayResult == nil else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                showResultModal = true
            }
            return
        }
        viewModel.spin(
            habits: activeHabits,
            context: modelContext,
            allowMultipleSpins: allowSpinReplayForTesting
        )
    }

    private func updateWidgetStreak() {
        guard let defaults = UserDefaults(suiteName: AppConstants.AppGroup.suiteName) else { return }
        defaults.set(viewModel.currentStreak, forKey: AppConstants.AppGroup.widgetStreak)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    SpinView()
        .modelContainer(for: [Habit.self, SpinResult.self], inMemory: true)
}
