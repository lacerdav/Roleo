import SwiftUI

/// Week-aligned activity grid. Renders 5 full weeks ending on the final day of
/// the week containing today. Each cell is 36pt. Three distinct visual states:
///
/// - `past`:   stroke-only circle (no activity OR spun-but-missed).
/// - `today`:  filled green circle with checkmark when completed; warm outline when not.
/// - `future`: very faint dot (no circle), no interaction.
struct CalendarGridView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let results: [SpinResult]
    let freezeDays: [FreezeDay]
    var isActive = true

    @State private var selectedDay: DayEntry?
    @State private var appeared = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let cellSize: CGFloat = 36

    /// Single-letter weekday symbols rotated to match `Calendar.current.firstWeekday`
    /// (e.g. en_US → `[S, M, T, W, T, F, S]`, en_GB → `[M, T, W, T, F, S, S]`).
    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortWeekdaySymbols
        let first = max(0, calendar.firstWeekday - 1)
        guard first < symbols.count else { return symbols }
        return Array(symbols[first...] + symbols[..<first])
    }

    // MARK: - Data model

    struct DayEntry: Identifiable, Hashable {
        enum Status: Hashable {
            case completed
            case frozen
            case missed
            case noSpin
            case future
        }

        let id: Date
        let date: Date
        let status: Status
        let habitName: String?

        var isToday: Bool {
            Calendar.current.isDateInToday(date)
        }
    }

    private var days: [DayEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // End of the current week, then walk back 5 weeks (35 days) from the day AFTER end-of-week.
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return []
        }
        // `weekInterval.end` is the exclusive end (start of next week). Subtract 1s to get the last
        // day of the current week, then start-of-day to normalise.
        let endOfWeek = calendar.startOfDay(
            for: calendar.date(byAdding: .second, value: -1, to: weekInterval.end) ?? today
        )
        guard let start = calendar.date(byAdding: .day, value: -34, to: endOfWeek) else {
            return []
        }

        // Index results by day for O(1) lookup.
        var byDay: [Date: SpinResult] = [:]
        for result in results {
            let day = calendar.startOfDay(for: result.date)
            byDay[day] = result
        }
        let frozenByDay = Set(
            freezeDays.map { calendar.startOfDay(for: $0.date) }
        )

        return (0..<35).compactMap { offset -> DayEntry? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else {
                return nil
            }
            let day = calendar.startOfDay(for: date)

            if day > today {
                return DayEntry(id: day, date: day, status: .future, habitName: nil)
            }

            if let result = byDay[day] {
                return DayEntry(
                    id: day,
                    date: day,
                    status: result.isCompleted ? .completed : .missed,
                    habitName: result.habitName
                )
            } else if frozenByDay.contains(day) {
                return DayEntry(id: day, date: day, status: .frozen, habitName: nil)
            } else {
                return DayEntry(id: day, date: day, status: .noSpin, habitName: nil)
            }
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .tracking(0.5)
                        .foregroundStyle(Color(hex: AppConstants.Colors.textTertiary))
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(days.enumerated()), id: \.element.id) { index, entry in
                    Group {
                        if entry.status == .future {
                            futureCell()
                        } else {
                            Button {
                                selectedDay = entry
                            } label: {
                                cell(for: entry)
                            }
                            .buttonStyle(.plain)
                            .popover(
                                isPresented: Binding(
                                    get: { selectedDay == entry },
                                    set: { isPresented in
                                        if !isPresented { selectedDay = nil }
                                    }
                                )
                            ) {
                                popover(for: entry)
                            }
                        }
                    }
                    .scaleEffect(appeared || reduceMotion ? 1.0 : 0.5)
                    .opacity(appeared ? 1.0 : 0)
                    .animation(
                        reduceMotion
                            ? .easeOut(duration: 0.2)
                            : .spring(response: 0.35, dampingFraction: 0.65)
                                .delay(Double(index) * 0.018),
                        value: appeared
                    )
                }
            }
            .onAppear { revealIfNeeded() }
            .onChange(of: isActive) { _, _ in revealIfNeeded() }
        }
    }

    // MARK: - Cells

    @ViewBuilder
    private func cell(for entry: DayEntry) -> some View {
        ZStack {
            switch entry.status {
            case .completed:
                Circle()
                    .fill(Color(hex: AppConstants.Colors.successGreen))
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            case .frozen:
                Circle()
                    .fill(Color(hex: AppConstants.Colors.secondarySoft))
                Image(systemName: "snowflake")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Color(hex: AppConstants.Colors.secondaryTeal))
            case .missed:
                Circle()
                    .stroke(Color(hex: AppConstants.Colors.coral).opacity(0.55), lineWidth: 1.2)
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: AppConstants.Colors.coral).opacity(0.70))
            case .noSpin:
                // "Past empty" — stroke only, warm brown at 12%.
                Circle()
                    .stroke(Color(hex: AppConstants.Colors.textPrimary).opacity(0.12), lineWidth: 1)
            case .future:
                EmptyView()
            }

            if entry.isToday {
                Circle()
                    .stroke(Color(hex: AppConstants.Colors.primaryOrange), lineWidth: 1.8)
                    .padding(-2)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .shadow(
            color: shadowColor(for: entry.status),
            radius: 5, x: 0, y: 2
        )
        .accessibilityLabel(accessibilityLabel(for: entry))
    }

    /// Very faint dot for future days — visible structure without drawing attention.
    private func futureCell() -> some View {
        Circle()
            .fill(Color(hex: AppConstants.Colors.textPrimary).opacity(0.06))
            .frame(width: 3, height: 3)
            .frame(width: cellSize, height: cellSize)
            .accessibilityHidden(true)
    }

    // MARK: - Popover

    @ViewBuilder
    private func popover(for entry: DayEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.date.formatted(.dateTime.weekday(.wide).month().day()))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))

            switch entry.status {
            case .completed:
                Text(entry.habitName.map { "\($0) — completed" } ?? "Completed")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.successGreen))
            case .frozen:
                Text("Streak freeze used")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.secondaryTeal))
            case .missed:
                Text(entry.habitName.map { "\($0) — not done" } ?? "Spun but not completed")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
            case .noSpin:
                Text("No spin on this day")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
            case .future:
                EmptyView()
            }
        }
        .padding(12)
        .frame(minWidth: 180)
        .presentationCompactAdaptation(.popover)
    }

    private func accessibilityLabel(for entry: DayEntry) -> String {
        let date = entry.date.formatted(.dateTime.month().day())
        switch entry.status {
        case .completed: return "\(date), completed"
        case .frozen:    return "\(date), streak freeze"
        case .missed:    return "\(date), missed"
        case .noSpin:    return "\(date), no spin"
        case .future:    return ""
        }
    }

    private func shadowColor(for status: DayEntry.Status) -> Color {
        switch status {
        case .completed:
            return Color(hex: AppConstants.Colors.successGreen).opacity(0.30)
        case .frozen:
            return Color(hex: AppConstants.Colors.secondaryTeal).opacity(0.18)
        case .missed, .noSpin, .future:
            return .clear
        }
    }

    private func revealIfNeeded() {
        guard isActive, !appeared else { return }
        appeared = true
    }
}

#Preview {
    CalendarGridView(results: [], freezeDays: [])
        .padding()
        .background(Color(hex: AppConstants.Colors.backgroundTop))
}
