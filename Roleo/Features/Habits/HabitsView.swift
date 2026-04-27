import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    var isActive = true

    @State private var viewModel = HabitsViewModel()
    @State private var showingAddHabit = false
    @State private var editingHabit: Habit?
    @State private var habitPendingDelete: Habit?
    @State private var showingDeleteDialog = false
    @State private var newHabitSparkleTick = 0
    @State private var newHabitRowID: UUID?
    @State private var newHabitCelebration: NewHabitCelebration?
    @State private var appeared = false

    private let requiredActive = 4

    private var activeHabitsCount: Int {
        habits.filter(\.isActive).count
    }

    private var isReadyToSpin: Bool {
        activeHabitsCount >= requiredActive
    }

    var body: some View {
        ZStack {
            mainContent
                .opacity(showingAddHabit ? 0.18 : 1)
                .allowsHitTesting(!showingAddHabit)

            if showingAddHabit {
                backdrop
                addPanel
            }
        }
        .warmBackground()
        .toolbar(showingAddHabit ? .hidden : .visible, for: .tabBar)
        .hideCustomTabBar(showingAddHabit)
        .sheet(item: $editingHabit) { habit in
            editSheet(for: habit)
        }
        .sensoryFeedback(.success, trigger: newHabitSparkleTick)
        .sensoryFeedback(.warning, trigger: showingDeleteDialog) { _, isShown in isShown }
        .overlay {
            if showingDeleteDialog {
                deleteConfirmOverlay
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.92)),
                            removal: .opacity
                        )
                    )
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if let newHabitCelebration, isActive, !showingAddHabit, !showingDeleteDialog {
                newHabitMascotCelebration(newHabitCelebration)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 22)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing)
                                .combined(with: .scale(scale: 0.82, anchor: .bottomTrailing))
                                .combined(with: .opacity),
                            removal: .move(edge: .bottom)
                                .combined(with: .opacity)
                        )
                    )
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            revealRowsIfNeeded()
        }
        .onChange(of: isActive) { _, _ in
            revealRowsIfNeeded()
        }
    }

    // MARK: - Subviews

    private var mainContent: some View {
        VStack(spacing: 10) {
            header

            readinessPill
                .padding(.horizontal, 20)
                .padding(.top, 2)

            if habits.isEmpty {
                emptyState
                    .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                        habitRow(habit, index: index)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    habitPendingDelete = habit
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                                        showingDeleteDialog = true
                                    }
                                } label: {
                                    Label(AppCopy.Habits.deleteConfirm, systemImage: "trash")
                                }
                            }
                    }
                    .onMove(perform: moveHabits)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
        }
    }

    private var header: some View {
        ZStack {
            Text("Habits")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                .kerning(0.3)

            HStack {
                Spacer()

                Button {
                    openAddPanel()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(Color(hex: AppConstants.Colors.cardSurface))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color(hex: AppConstants.Colors.primaryOrange)))
                        .shadow(
                            color: Color(hex: AppConstants.Colors.primaryOrange).opacity(0.32),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                        .scaleEffect(showingAddHabit ? 0.6 : 1)
                        .opacity(showingAddHabit ? 0 : 1)
                }
                .buttonStyle(.pressable)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            RoleoMascot(expression: .curious, size: 140, active: isActive)

            VStack(spacing: 8) {
                Text(AppCopy.Empty.habitsTitle)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                    .multilineTextAlignment(.center)

                Text(AppCopy.Empty.habitsMessage)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                openAddPanel()
            } label: {
                Label(AppCopy.Habits.addFirstCTA, systemImage: "plus")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.cardSurface))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule().fill(Color(hex: AppConstants.Colors.primaryOrange))
                    )
                    .shadow(
                        color: Color(hex: AppConstants.Colors.primaryOrange).opacity(0.28),
                        radius: 12, x: 0, y: 6
                    )
            }
            .buttonStyle(.pressable)
        }
        .padding(.horizontal, 20)
    }

    /// Always-visible readiness indicator. Reads as a warm nudge while the
    /// user builds up to 4 active habits, then flips to a celebratory "all
    /// set" state once the wheel can actually spin.
    private var readinessPill: some View {
        let filled = min(activeHabitsCount, requiredActive)
        let accent = isReadyToSpin
            ? Color(hex: AppConstants.Colors.secondaryTeal)
            : Color(hex: AppConstants.Colors.primaryOrange)

        return HStack(spacing: 12) {
            RoleoMascot(
                expression: isReadyToSpin ? .excited : .curious,
                size: 42,
                breathing: !reduceMotion,
                active: isActive
            )
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(isReadyToSpin
                    ? AppCopy.Habits.readinessReady(active: activeHabitsCount)
                    : AppCopy.Habits.readinessBuilding(active: activeHabitsCount, needed: requiredActive)
                )
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                .contentTransition(.opacity)

                HStack(spacing: 6) {
                    ForEach(0..<requiredActive, id: \.self) { index in
                        Capsule()
                            .fill(
                                index < filled
                                    ? accent
                                    : Color(hex: AppConstants.Colors.textSecondary).opacity(0.18)
                            )
                            .frame(width: index < filled ? 18 : 14, height: 4)
                            .animation(
                                .spring(response: 0.45, dampingFraction: 0.68)
                                    .delay(Double(index) * 0.03),
                                value: filled
                            )
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(accent.opacity(0.12))
        )
        .warmCard(radius: 14, level: 1)
        .animation(.spring(response: 0.5, dampingFraction: 0.78), value: isReadyToSpin)
        .accessibilityElement(children: .combine)
    }

    private var backdrop: some View {
        Color.black.opacity(0.32)
            .ignoresSafeArea()
            .onTapGesture { closeAddPanel() }
            .transition(.opacity)
    }

    private var addPanel: some View {
        HabitFormView(
            existingHabits: habits,
            habitToEdit: nil,
            onSave: handleAddSave,
            onClose: closeAddPanel
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: AppConstants.Colors.backgroundTop),
                            Color(hex: AppConstants.Colors.backgroundBottom)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(
                    color: Color(hex: AppConstants.Colors.primaryOrange).opacity(0.22),
                    radius: 28,
                    x: 0,
                    y: 14
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .padding(.horizontal, 12)
        .padding(.top, 56)
        .padding(.bottom, 24)
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.02, anchor: .topTrailing)
                    .combined(with: .opacity),
                removal: .scale(scale: 0.02, anchor: .topTrailing)
                    .combined(with: .opacity)
            )
        )
    }

    private func habitRow(_ habit: Habit, index: Int) -> some View {
        let isNew = newHabitRowID == habit.id
        // Stagger only plays on the initial appear. Rows revealed later by
        // scrolling are already past the `appeared` flag and animate in
        // without delay — no flicker.
        let staggerDelay = min(Double(index) * 0.045, 0.35)

        return ZStack {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: habit.colorHex))
                    .frame(width: 40, height: 40)
                    .overlay(
                        HabitIconView(
                            iconName: habit.iconName,
                            size: 18,
                            foreground: Color(hex: AppConstants.Colors.cardSurface)
                        )
                        .symbolEffect(.bounce, value: habit.isActive)
                    )
                    .scaleEffect(habit.isActive ? 1.0 : 0.92)
                    .animation(.spring(response: 0.42, dampingFraction: 0.6), value: habit.isActive)

                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                    Text(habit.isActive ? AppCopy.Habits.readyLabel : AppCopy.Habits.restingLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                        .contentTransition(.opacity)
                }

                Spacer()

                // Subtle grip hint — `.onMove` on the List already enables
                // long-press drag-to-reorder without edit mode, but users
                // don't discover it unless there's a visual affordance.
                // Only shown when reordering is actually meaningful.
                if habits.count > 1 {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(
                            Color(hex: AppConstants.Colors.textSecondary).opacity(0.45)
                        )
                        .padding(.trailing, 2)
                        .accessibilityHidden(true)
                }

                Toggle("", isOn: Binding(
                    get: { habit.isActive },
                    set: { _ in viewModel.toggleActive(habit, context: modelContext) }
                ))
                .labelsHidden()
                .tint(Color(hex: AppConstants.Colors.primaryOrange))
                .sensoryFeedback(.selection, trigger: habit.isActive)
            }
            .padding(14)
            .warmCard(radius: 20, level: 1)
            .opacity(habit.isActive ? 1.0 : 0.5)
            .animation(.easeInOut(duration: 0.22), value: habit.isActive)

            if isNew {
                SparkleBurst(trigger: newHabitSparkleTick)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editingHabit = habit
        }
        .opacity(appeared || reduceMotion ? 1 : 0)
        .offset(y: appeared || reduceMotion ? 0 : 18)
        .animation(
            reduceMotion
                ? .easeOut(duration: 0.2)
                : .spring(response: 0.5, dampingFraction: 0.78).delay(staggerDelay),
            value: appeared
        )
    }

    private func editSheet(for habit: Habit) -> some View {
        HabitFormView(
            existingHabits: habits,
            habitToEdit: habit,
            onSave: { name, iconName, colorHex, isActive in
                viewModel.updateHabit(
                    habit,
                    name: name,
                    iconName: iconName,
                    colorHex: colorHex,
                    isActive: isActive,
                    context: modelContext
                )
            }
        )
        .warmBackground()
        .presentationDetents([.fraction(0.72), .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Delete Confirmation (custom, on-brand)

    /// Warm delete confirmation — replaces the default iOS action sheet so
    /// the destructive moment still feels like Roleo. Reassuring mascot,
    /// human copy, and a primary "Keep it" (the safe choice) above the
    /// muted destructive action.
    private var deleteConfirmOverlay: some View {
        ZStack {
            Color.black.opacity(0.36)
                .ignoresSafeArea()
                .onTapGesture { dismissDeleteConfirm() }

            VStack(spacing: 18) {
                RoleoMascot(expression: .thinking, size: 72, breathing: !reduceMotion, active: isActive)

                VStack(spacing: 8) {
                    Text(AppCopy.Habits.deleteTitle)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                        .multilineTextAlignment(.center)

                    Text(AppCopy.Habits.deleteMessage)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 8)

                VStack(spacing: 10) {
                    Button {
                        dismissDeleteConfirm()
                    } label: {
                        Text(AppCopy.Habits.deleteCancel)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: AppConstants.Colors.cardSurface))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color(hex: AppConstants.Colors.primaryOrange))
                            )
                            .shadow(
                                color: Color(hex: AppConstants.Colors.primaryOrange).opacity(0.32),
                                radius: 10, x: 0, y: 5
                            )
                    }
                    .buttonStyle(.pressable)

                    Button {
                        confirmDelete()
                    } label: {
                        Text(AppCopy.Habits.deleteConfirm)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(destructiveRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.pressable)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 18)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(hex: AppConstants.Colors.cardSurface))
            )
            .warmCard(radius: 28, level: 2)
            .shadow(
                color: Color(hex: "#C8873A").opacity(0.20),
                radius: 40, x: 0, y: 16
            )
            .padding(.horizontal, 32)
        }
    }

    /// Warm destructive tint — noticeably red so users can't miss the
    /// irreversible action, but muted enough not to clash with Roleo's
    /// cream + orange palette.
    private var destructiveRed: Color {
        Color(red: 0.78, green: 0.31, blue: 0.27)
    }

    private func newHabitMascotCelebration(_ celebration: NewHabitCelebration) -> some View {
        NewHabitMascotCelebrationView(
            habitName: celebration.name,
            habitColor: Color(hex: celebration.colorHex),
            trigger: celebration.trigger,
            active: isActive
        )
    }

    private func confirmDelete() {
        let habit = habitPendingDelete
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            showingDeleteDialog = false
        }
        habitPendingDelete = nil
        if let habit {
            viewModel.deleteHabit(habit, context: modelContext)
        }
    }

    private func dismissDeleteConfirm() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            showingDeleteDialog = false
        }
        habitPendingDelete = nil
    }

    private func revealRowsIfNeeded() {
        guard isActive, !appeared else { return }
        // Tiny delay lets the List render before we flip the flag,
        // so the staggered spring reads cleanly instead of popping.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(60))
            guard isActive, !appeared else { return }
            withAnimation { appeared = true }
        }
    }

    // MARK: - Actions

    private func openAddPanel() {
        withAnimation(.addPanelSpring) {
            showingAddHabit = true
        }
    }

    private func closeAddPanel() {
        withAnimation(.addPanelSpring) {
            showingAddHabit = false
        }
    }

    private func handleAddSave(name: String, iconName: String, colorHex: String, isActive: Bool) {
        guard let newHabit = viewModel.addHabit(
            name: name, iconName: iconName, colorHex: colorHex, isActive: isActive, context: modelContext
        ) else { return }

        newHabitRowID = newHabit.id
        newHabitSparkleTick += 1
        let celebration = NewHabitCelebration(
            id: newHabit.id,
            name: newHabit.name,
            colorHex: newHabit.colorHex,
            trigger: newHabitSparkleTick
        )

        withAnimation(.spring(response: 0.54, dampingFraction: 0.74)) {
            newHabitCelebration = celebration
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            if newHabitRowID == newHabit.id {
                newHabitRowID = nil
            }

            try? await Task.sleep(for: .seconds(1.1))
            if newHabitCelebration?.id == celebration.id {
                withAnimation(.easeInOut(duration: 0.28)) {
                    newHabitCelebration = nil
                }
            }
        }
    }

    private func moveHabits(from source: IndexSet, to destination: Int) {
        var reordered = habits
        reordered.move(fromOffsets: source, toOffset: destination)
        viewModel.reorder(habits: reordered, context: modelContext)
    }
}

private struct NewHabitCelebration: Identifiable, Equatable {
    let id: UUID
    let name: String
    let colorHex: String
    let trigger: Int
}

private struct NewHabitMascotCelebrationView: View {
    let habitName: String
    let habitColor: Color
    let trigger: Int
    let active: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var floatUp = false
    @State private var sparkleTrigger = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ZStack {
                RoleoMascot(
                    expression: .cheering,
                    size: 86,
                    active: active
                )
                .scaleEffect(appeared ? 1 : 0.62)
                .rotationEffect(.degrees(appeared && !reduceMotion ? -4 : 0))
                .offset(y: floatUp && !reduceMotion ? -5 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.58), value: appeared)
                .animation(
                    reduceMotion
                        ? .easeOut(duration: 0.2)
                        : .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                    value: floatUp
                )

                SparkleBurst(
                    trigger: sparkleTrigger,
                    palette: [
                        habitColor,
                        Color(hex: AppConstants.Colors.goldBright),
                        Color(hex: AppConstants.Colors.primaryOrange)
                    ],
                    particleCount: 10,
                    duration: 0.8
                )
                .frame(width: 112, height: 112)
            }
            .frame(width: 88, height: 94)
            .zIndex(1)

            VStack(alignment: .leading, spacing: 5) {
                Text("ROLEO CHEERS")
                    .font(.system(.caption2, design: .rounded).weight(.black))
                    .tracking(1.2)
                    .foregroundStyle(habitColor)

                Text("\"\(habitName)\" joined the ritual.")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                Text("Tiny step. Real momentum.")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
            }
            .padding(.leading, 28)
            .padding(.trailing, 15)
            .padding(.vertical, 13)
            .frame(maxWidth: 260, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: AppConstants.Colors.cardSurface),
                                habitColor.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(habitColor.opacity(0.20), lineWidth: 1)
            )
            .shadow(color: habitColor.opacity(0.18), radius: 18, x: 0, y: 10)
            .offset(x: -18, y: -4)
        }
        .scaleEffect(appeared ? 1 : 0.9, anchor: .bottomTrailing)
        .opacity(appeared ? 1 : 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Roleo cheers. \(habitName) joined the ritual. Tiny step. Real momentum.")
        .onAppear {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.72)) {
                appeared = true
            }
            sparkleTrigger = trigger
            guard !reduceMotion else { return }
            floatUp = true
        }
    }
}

#Preview {
    HabitsView()
        .modelContainer(for: [Habit.self, SpinResult.self, FreezeDay.self], inMemory: true)
}
