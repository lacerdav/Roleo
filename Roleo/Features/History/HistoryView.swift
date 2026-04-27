import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SpinResult.date, order: .reverse) private var results: [SpinResult]
    @Query(sort: \FreezeDay.date, order: .reverse) private var freezeDays: [FreezeDay]

    var isActive = true

    @State private var viewModel = HistoryViewModel()
    @State private var animateStats = false
    @State private var animateXPBar = false

    private var stats: UserStats {
        viewModel.calculateStats(from: results, freezeDays: freezeDays)
    }

    private var progression: XPProgressionState {
        XPProgressionState.fromCompletedTasks(stats.totalCompleted)
    }

    private var groupedResults: [(String, [SpinResult])] {
        viewModel.groupByMonth(results)
    }

    /// Number of completed spins in the last 30 days (inclusive of today).
    private var last30Completed: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let windowStart = calendar.date(byAdding: .day, value: -29, to: today) else {
            return 0
        }
        return results.reduce(into: 0) { count, result in
            let day = calendar.startOfDay(for: result.date)
            if result.isCompleted, day >= windowStart, day <= today {
                count += 1
            }
        }
    }

    private var recentFreeze: FreezeDay? {
        freezeDays.first
    }

    private let last30Window = 30

    var body: some View {
        ZStack {
            if results.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .warmBackground()
        .onAppear(perform: triggerAppearanceIfActive)
        .onChange(of: isActive) { _, _ in
            triggerAppearanceIfActive()
        }
        .onChange(of: results.count) { _, _ in
            guard isActive else { return }
            // Re-run the appearance animation any time the XP source changes.
            animateXPBar = false
            withAnimation(.easeOut(duration: 0.7)) {
                animateXPBar = true
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            header

            VStack(spacing: 20) {
                RoleoMascot(expression: .happy, size: 140, active: isActive)

                VStack(spacing: 8) {
                    Text(AppCopy.Empty.historyTitle)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                        .multilineTextAlignment(.center)

                    Text(AppCopy.Empty.historyMessage)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                statCards

                progressReflection

                xpBar

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("LAST 30 DAYS")
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .tracking(1.4)
                            .foregroundStyle(Color(hex: AppConstants.Colors.textTertiary))

                        Spacer()

                        Text("\(last30Completed) / \(last30Window)")
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .tracking(0.6)
                            .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                            .contentTransition(.numericText())
                            .accessibilityLabel("\(last30Completed) of \(last30Window) days completed")
                    }

                    CalendarGridView(results: results, freezeDays: freezeDays, isActive: isActive)
                        .padding(16)
                        .warmCard(radius: 20, level: 1)
                }

                historyList
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }

    private var progressReflection: some View {
        let message = AppCopy.Empty.historyProgressReflection(
            streak: stats.currentStreak,
            completed: stats.totalCompleted
        )
        let accent = reflectionAccent

        return HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                accent.opacity(0.95),
                                Color(hex: AppConstants.Colors.goldBright).opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: accent.opacity(0.30), radius: 12, x: 0, y: 6)

                RoleoMascot(
                    expression: reflectionExpression,
                    size: 52,
                    active: isActive
                )
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 4) {
                Text(reflectionEyebrow)
                    .font(.system(.caption2, design: .rounded).weight(.black))
                    .tracking(1.2)
                    .foregroundStyle(accent)

                Text(message)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: AppConstants.Colors.goldSoft),
                            Color(hex: AppConstants.Colors.primarySoft)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: "sparkles")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(hex: AppConstants.Colors.gold))
                .padding(.top, 12)
                .padding(.trailing, 14)
                .opacity(0.75)
                .symbolEffect(.pulse, value: animateStats)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accent.opacity(0.24), lineWidth: 1)
        )
        .shadow(color: accent.opacity(0.12), radius: 16, x: 0, y: 8)
        .scaleEffect(animateStats ? 1 : 0.97)
        .opacity(animateStats ? 1 : 0)
        .offset(y: animateStats ? 0 : 10)
        .animation(.spring(response: 0.45, dampingFraction: 0.78).delay(0.12), value: animateStats)
        .accessibilityLabel("Progress reflection")
        .accessibilityValue("\(reflectionEyebrow). \(message)")
    }

    private var reflectionAccent: Color {
        stats.currentStreak > 0
            ? Color(hex: AppConstants.Colors.primaryOrange)
            : Color(hex: AppConstants.Colors.secondaryTeal)
    }

    private var reflectionExpression: RoleoMascot.Expression {
        if stats.currentStreak > 1 { return .cheering }
        if stats.currentStreak == 1 { return .happy }
        return stats.totalCompleted > 0 ? .thinking : .curious
    }

    private var reflectionEyebrow: String {
        if stats.currentStreak > 1 { return "\(stats.currentStreak)-DAY STREAK" }
        if stats.currentStreak == 1 { return "TODAY COUNTS" }
        if recentFreeze != nil { return "STREAK SAVED" }
        return stats.totalCompleted > 0 ? "READY WHEN YOU ARE" : "FIRST WIN WAITING"
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            Text("History")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
            Spacer()
            if !results.isEmpty {
                completedBadge
            }
        }
    }

    /// Vibrant "N completed" pill: warm cream fill, solid green status dot,
    /// bold rounded dark-brown text. Pops against the beige background without
    /// competing with the wheel/cards.
    private var completedBadge: some View {
        let green = Color(hex: AppConstants.Colors.successGreen)
        let text = Color(hex: AppConstants.Colors.textPrimary)
        let fill = Color(hex: AppConstants.Colors.cardElevated)
        let stroke = Color(hex: AppConstants.Colors.textPrimary).opacity(0.06)

        return HStack(spacing: 7) {
            Circle()
                .fill(green)
                .frame(width: 9, height: 9)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: green.opacity(0.35), radius: 3, x: 0, y: 1)

            Text("\(stats.totalCompleted) completed")
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundStyle(text)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(fill)
                .overlay(
                    Capsule()
                        .stroke(stroke, lineWidth: 0.5)
                )
                .shadow(color: Color(hex: "#C8873A").opacity(0.10), radius: 6, x: 0, y: 2)
        )
        .accessibilityLabel("\(stats.totalCompleted) completed")
    }

    // MARK: - Stat cards

    private var statCards: some View {
        HStack(spacing: 10) {
            statCard(
                symbol: "flame.fill",
                title: "Streak",
                value: "\(stats.currentStreak)",
                suffix: stats.currentStreak == 1 ? "day" : "days",
                accent: Color(hex: AppConstants.Colors.primaryOrange),
                index: 0
            )
            statCard(
                symbol: "checkmark.seal.fill",
                title: "Completed",
                value: "\(stats.totalCompleted)",
                suffix: "total",
                accent: Color(hex: AppConstants.Colors.successGreen),
                index: 1
            )
        }
    }

    private func statCard(symbol: String, title: String, value: String, suffix: String, accent: Color, index: Int = 0) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent)
                Text(title.uppercased())
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(Color(hex: AppConstants.Colors.textTertiary))
            }

            Text(value)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(accent)
                .contentTransition(.numericText())
                .scaleEffect(animateStats ? 1 : 0.85)
                .opacity(animateStats ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: animateStats)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(suffix)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard(radius: 14, level: 1)
        .scaleEffect(animateStats ? 1 : 0.94)
        .opacity(animateStats ? 1 : 0)
        .offset(y: animateStats ? 0 : 12)
        .animation(
            .spring(response: 0.45, dampingFraction: 0.78)
                .delay(Double(index) * 0.08),
            value: animateStats
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value) \(suffix)")
    }

    // MARK: - XP Bar

    private var xpBar: some View {
        let accent = progression.tier.accent
        let goldStart = Color(hex: AppConstants.Colors.goldBright)
        let goldEnd = Color(hex: AppConstants.Colors.gold)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("XP PROGRESS")
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(Color(hex: AppConstants.Colors.textTertiary))

                Spacer()

                Text("\(progression.xpIntoCurrentLevel) / \(progression.xpNeededForNextLevel) XP")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                    .contentTransition(.numericText())
            }

            HStack(spacing: 12) {
                levelChip(level: progression.level, filled: true, accent: accent)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: AppConstants.Colors.textPrimary).opacity(0.07))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [goldStart, goldEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: max(
                                    0,
                                    (animateXPBar ? CGFloat(progression.progress) : 0) * proxy.size.width
                                )
                            )
                            .overlay(alignment: .topLeading) {
                                // Subtle gloss highlight on the filled portion.
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.35), Color.white.opacity(0.0)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(height: 4)
                                    .padding(.horizontal, 4)
                                    .padding(.top, 2)
                            }
                    }
                }
                .frame(height: 14)

                levelChip(level: progression.level + 1, filled: false, accent: accent)
            }
        }
        .padding(14)
        .warmCard(radius: 16, level: 1)
    }

    private func levelChip(level: Int, filled: Bool, accent: Color) -> some View {
        Text("Lv. \(level)")
            .font(.system(.caption, design: .rounded).weight(.bold))
            .foregroundStyle(filled ? Color.white : accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(filled ? accent : accent.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(accent.opacity(filled ? 0 : 0.35), lineWidth: 1)
            )
    }

    // MARK: - Section helper

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .tracking(1.4)
                .foregroundStyle(Color(hex: AppConstants.Colors.textTertiary))
            content()
        }
    }

    // MARK: - History list

    private var historyList: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            ForEach(groupedResults, id: \.0) { monthLabel, monthResults in
                VStack(alignment: .leading, spacing: 10) {
                    Text(monthLabel.uppercased())
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .tracking(1.4)
                        .foregroundStyle(Color(hex: AppConstants.Colors.textTertiary))

                    VStack(spacing: 8) {
                        ForEach(monthResults, id: \.id) { result in
                            historyRow(result)
                        }
                    }
                }
            }
        }
    }

    private func historyRow(_ result: SpinResult) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: result.habitColorHex))
                HabitIconView(
                    iconName: result.habitIconName,
                    size: 16,
                    foreground: .white
                )
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.habitName)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                Text(result.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
            }

            Spacer()

            trailingBadge(isCompleted: result.isCompleted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .warmCard(radius: 16, level: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(historyRowAccessibilityLabel(for: result))
    }

    @ViewBuilder
    private func trailingBadge(isCompleted: Bool) -> some View {
        if isCompleted {
            VStack(spacing: 4) {
                xpBadge
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(hex: AppConstants.Colors.successGreen))
            }
        } else {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(hex: AppConstants.Colors.coral))
        }
    }

    private var xpBadge: some View {
        // Display the base per-completion XP reward — per-row retroactive level
        // calculation would require storing the level snapshot on SpinResult,
        // which isn't in the data model yet.
        HStack(spacing: 2) {
            Image(systemName: "plus")
                .font(.system(size: 8, weight: .black, design: .rounded))
            Text("\(AppConstants.Points.perCompletion) XP")
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .foregroundStyle(Color(hex: AppConstants.Colors.gold))
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color(hex: AppConstants.Colors.goldSoft))
        )
        .overlay(
            Capsule()
                .stroke(Color(hex: AppConstants.Colors.gold).opacity(0.35), lineWidth: 1)
        )
    }

    private func historyRowAccessibilityLabel(for result: SpinResult) -> String {
        let date = result.date.formatted(.dateTime.weekday(.wide).month().day())
        let status = result.isCompleted ? "completed" : "not completed"
        return "\(result.habitName), \(date), \(status)"
    }

    // MARK: - Appearance

    private func triggerAppearanceIfActive() {
        guard isActive else { return }
        triggerAppearance()
    }

    private func triggerAppearance() {
        animateStats = false
        animateXPBar = false

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.05)) {
            animateStats = true
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.15)) {
            animateXPBar = true
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [SpinResult.self, Habit.self, FreezeDay.self], inMemory: true)
}
