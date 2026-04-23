import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class HabitsViewModel {
    @discardableResult
    func addHabit(name: String, iconName: String, colorHex: String, isActive: Bool = true, context: ModelContext) -> Habit? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])
        let count = (try? context.fetch(descriptor).count) ?? 0
        let habit = Habit(name: trimmed, iconName: iconName, colorHex: colorHex, isActive: isActive, sortOrder: count)
        context.insert(habit)
        do {
            try context.save()
            return habit
        } catch {
            context.rollback()
            return nil
        }
    }

    func updateHabit(_ habit: Habit, name: String, iconName: String, colorHex: String, isActive: Bool, context: ModelContext) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        habit.name = trimmed
        habit.iconName = iconName
        habit.colorHex = colorHex
        habit.isActive = isActive
        saveOrRollback(context)
    }

    func deleteHabit(_ habit: Habit, context: ModelContext) {
        context.delete(habit)
        saveOrRollback(context)
    }

    func toggleActive(_ habit: Habit, context: ModelContext) {
        habit.isActive.toggle()
        saveOrRollback(context)
    }

    func reorder(habits: [Habit], context: ModelContext) {
        for (index, habit) in habits.enumerated() {
            habit.sortOrder = index
        }
        saveOrRollback(context)
    }

    private func saveOrRollback(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }
}
