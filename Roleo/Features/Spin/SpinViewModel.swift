import Foundation
import Observation
import SwiftData
import SwiftUI
import UIKit
import WidgetKit

@Observable
@MainActor
final class SpinViewModel {
    // MARK: - Wheel state
    var wheelRotation: Double = 0
    var selectedHabit: Habit?
    var isSpinning = false
    var todayResult: SpinResult?
    var didStartSpin = false
    var didCompleteSpin = false
    var didCompleteHabit = false

    var hasSpunToday: Bool { todayResult != nil }

    // MARK: - Derived stats (updated via updateDerivedStats)
    // Keeping these in the ViewModel satisfies MVVM: the View passes its
    // @Query results here once, and all consumers read from one source of truth.

    private(set) var currentStreak: Int = 0
    private(set) var completedTasksCount: Int = 0
    private(set) var progression: XPProgressionState = XPProgressionState.fromCompletedTasks(0)

    var currentLevel: Int          { progression.level }
    var xpForNextLevel: Int        { progression.xpNeededForNextLevel }
    var xpProgressInLevel: Int     { progression.xpIntoCurrentLevel }
    var xpProgress: Double         { progression.progress }
    var levelAccent: Color         { progression.tier.accent }
    var levelSoft: Color           { progression.tier.soft }

    /// Called from SpinView's result-signature observer and `.onAppear` so the
    /// ViewModel always reflects the latest SwiftData stats source.
    func updateDerivedStats(results: [SpinResult]) {
        let stats = UserStatsCalculator.calculate(from: results)
        currentStreak = stats.currentStreak
        completedTasksCount = stats.totalCompleted
        progression = XPProgressionState.fromCompletedTasks(completedTasksCount)
    }

    func loadTodayResult(context: ModelContext) {
        let today = Date().startOfDay
        let predicate = #Predicate<SpinResult> { result in
            result.date == today
        }

        var descriptor = FetchDescriptor<SpinResult>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        todayResult = try? context.fetch(descriptor).first
    }

    func spin(habits: [Habit], context: ModelContext, allowMultipleSpins: Bool = false) {
        guard !isSpinning, (!hasSpunToday || allowMultipleSpins), !habits.isEmpty else { return }

        isSpinning = true
        didStartSpin.toggle()

        let sortedHabits = habits.sorted { $0.sortOrder < $1.sortOrder }
        guard let targetHabit = sortedHabits.randomElement(),
              let plannedIndex = sortedHabits.firstIndex(where: { $0.id == targetHabit.id })
        else {
            isSpinning = false
            return
        }

        let segmentCount = max(sortedHabits.count, 1)
        let segmentAngle = 360.0 / Double(segmentCount)

        // Cancel any lingering implicit animation by writing `wheelRotation` inside a disabled
        // transaction AND normalizing it to [0, 360). This prevents a previous animation from
        // interfering with the new spin and keeps the accumulated rotation value small.
        writeRotationImmediately(normalizeRotation(wheelRotation))

        // Plan a final rotation that lands the planned segment under the pointer.
        // In our coord system, segment 0 starts at the top (-π/2). Pointer sits at the top.
        // So the wheel needs to rotate by `360 - (index + 0.5) * segAngle` (mod 360) plus N full turns.
        let normalizedCurrent = normalizeRotation(wheelRotation)
        let plannedRestAngle = 360.0 - ((Double(plannedIndex) + 0.5) * segmentAngle)
        let turns = Double(Int.random(in: 6...9))
        var delta = plannedRestAngle - normalizedCurrent
        if delta < 0 { delta += 360.0 }
        let plannedFinalRotation = wheelRotation + (turns * 360.0) + delta

        selectedHabit = targetHabit

        Task {
            // Run the 3-phase physical simulation + final spring snap.
            await runPhysicalSpinSimulation(
                from: wheelRotation,
                to: plannedFinalRotation,
                segmentCount: segmentCount
            )

            // ── SAFETY NET ─────────────────────────────────────────────────
            // Derive winner from the ACTUAL rotation. This guarantees wheel
            // and result card are always in sync, even if math drifts.
            let winningIndex = segmentIndex(
                forRotation: wheelRotation,
                segmentCount: segmentCount
            )
            let winner = sortedHabits[winningIndex]

            // Snap wheel to the EXACT center of the winning segment.
            await snapToSegmentCenter(
                index: winningIndex,
                segmentAngle: segmentAngle
            )

            #if DEBUG
            let normalized = normalizeRotation(wheelRotation)
            let angleAtPointer = (360.0 - normalized).truncatingRemainder(dividingBy: 360.0)
            print("🎯 Spin debug — totalRotation=\(wheelRotation), normalized=\(normalized), angleAtPointer=\(angleAtPointer), winningIndex=\(winningIndex), winner=\(winner.name), planned=\(plannedIndex)/\(targetHabit.name)")
            #endif

            if allowMultipleSpins {
                let today = Date().startOfDay
                let predicate = #Predicate<SpinResult> { result in
                    result.date == today
                }
                let descriptor = FetchDescriptor<SpinResult>(predicate: predicate)
                if let existingToday = try? context.fetch(descriptor) {
                    for item in existingToday {
                        context.delete(item)
                    }
                }
            }

            let result = SpinResult(date: Date(), habit: winner)
            context.insert(result)
            do {
                try context.save()
                todayResult = result
                selectedHabit = winner
                updateAppGroup(with: result)
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                context.delete(result)
                selectedHabit = nil
            }
            isSpinning = false
            didCompleteSpin.toggle()
        }
    }

    // MARK: - Rotation math helpers

    /// Writes `wheelRotation` with all implicit animations suppressed, so no ambient
    /// `withAnimation` / `.animation(_:value:)` modifier can retro-animate the change.
    private func writeRotationImmediately(_ value: Double) {
        var txn = Transaction()
        txn.disablesAnimations = true
        withTransaction(txn) {
            wheelRotation = value
        }
    }

    private func normalizeRotation(_ rotation: Double) -> Double {
        let r = rotation.truncatingRemainder(dividingBy: 360.0)
        return r < 0 ? r + 360.0 : r
    }

    /// Which segment currently sits under the fixed top pointer for a given wheel rotation.
    /// Segment 0 is drawn starting at the top, so angleUnderPointer = (360 − normalizedRotation) mod 360
    /// and segmentIndex = floor(angleUnderPointer / segAngle).
    private func segmentIndex(forRotation rotation: Double, segmentCount: Int) -> Int {
        let segCount = max(segmentCount, 1)
        let segmentAngle = 360.0 / Double(segCount)
        let normalized = normalizeRotation(rotation)
        var angleUnderPointer = (360.0 - normalized).truncatingRemainder(dividingBy: 360.0)
        if angleUnderPointer < 0 { angleUnderPointer += 360.0 }
        // Guard against floating-point landing exactly on a boundary.
        let idx = Int(floor(angleUnderPointer / segmentAngle))
        return ((idx % segCount) + segCount) % segCount
    }

    /// Final micro-adjustment so the pointer sits dead-center on the winning segment.
    /// For planned spins the correction is exactly 0° — we skip animation entirely and
    /// just wait for the next pipeline step. When a correction is needed (e.g. from a
    /// drifted planned target) we use a slow spring so it reads as a natural settle,
    /// never a "jump", and always take the shortest path (|rotationDelta| ≤ segAngle/2).
    private func snapToSegmentCenter(index: Int, segmentAngle: Double) async {
        let normalized = normalizeRotation(wheelRotation)
        var angleUnderPointer = (360.0 - normalized).truncatingRemainder(dividingBy: 360.0)
        if angleUnderPointer < 0 { angleUnderPointer += 360.0 }
        let desiredAngle = (Double(index) + 0.5) * segmentAngle

        // The rotation delta that aligns the pointer with `desiredAngle`:
        //   newNormalized = 360 − desiredAngle
        //   delta         = newNormalized − normalized = angleUnderPointer − desiredAngle
        var rotationDelta = angleUnderPointer - desiredAngle
        // Shortest-path normalization: always the minimum rotation to center the pointer.
        if rotationDelta > segmentAngle / 2 { rotationDelta -= segmentAngle }
        if rotationDelta < -segmentAngle / 2 { rotationDelta += segmentAngle }

        // Skip any visible movement below 0.5° — imperceptible and dodges stray animation.
        guard abs(rotationDelta) > 0.5 else {
            writeRotationImmediately(wheelRotation + rotationDelta)
            try? await Task.sleep(for: .milliseconds(80))
            return
        }

        withAnimation(.interpolatingSpring(stiffness: 55, damping: 14, initialVelocity: 0)) {
            wheelRotation += rotationDelta
        }
        try? await Task.sleep(for: .milliseconds(500))
    }

    func markComplete(context: ModelContext, results: [SpinResult]) {
        guard let result = todayResult, !result.isCompleted else { return }

        result.isCompleted = true
        result.completedAt = Date()

        do {
            try context.save()
            // Eagerly update the header stats so the Spin tab stays in sync with History.
            // The @Query notification can arrive after the completion animation starts.
            let statsSource = results.contains(where: { $0.id == result.id })
                ? results
                : [result] + results
            updateDerivedStats(results: statsSource)
            updateAppGroup(with: result)
            WidgetCenter.shared.reloadAllTimelines()
            didCompleteHabit.toggle()
        } catch {
            result.isCompleted = false
            result.completedAt = nil
        }
    }

    private func updateAppGroup(with result: SpinResult) {
        guard let defaults = UserDefaults(suiteName: AppConstants.AppGroup.suiteName) else { return }
        defaults.set(result.habitName, forKey: AppConstants.AppGroup.widgetTodayHabitName)
        defaults.set(result.habitIconName, forKey: AppConstants.AppGroup.widgetTodayHabitIcon)
        defaults.set(result.isCompleted, forKey: AppConstants.AppGroup.widgetTodayCompleted)
    }

    /// Single-phase spin driven by an ease-out cubic over the whole duration.
    /// Physics lands EXACTLY at `target` and velocity decays to zero smoothly — no visible
    /// "crawl then re-move" artefact. Peg-synchronized haptics fire as the wheel crosses
    /// segment boundaries; success haptic fires on final stop.
    private func runPhysicalSpinSimulation(from start: Double, to target: Double, segmentCount: Int) async {
        let light = UIImpactFeedbackGenerator(style: .light)
        let medium = UIImpactFeedbackGenerator(style: .medium)
        let success = UINotificationFeedbackGenerator()
        light.prepare()
        medium.prepare()
        success.prepare()

        let segmentAngle = 360.0 / Double(max(segmentCount, 1))
        let totalDistance = max(target - start, 0)
        let duration: Double = Double.random(in: 3.4...3.9)
        let frameRate: Double = 60.0
        let totalFrames = max(1, Int(duration * frameRate))
        let dt = 1.0 / frameRate

        let startPegIndex = Int(floor(start / segmentAngle))
        let endPegIndex = Int(floor(target / segmentAngle))
        let mediumThreshold = 3 // last 3 pegs hit harder

        var lastPegIndex = startPegIndex
        // Throttle sound to ~25 ticks/sec max. During the full-speed phase the wheel
        // crosses multiple pegs per frame; firing a system sound for each would turn
        // into white noise. As the wheel decelerates, ticks naturally space out to
        // 1:1 with pegs. Tracked in frames instead of wall-clock time because the
        // simulation is already frame-driven and deterministic.
        let minSoundFrameGap = max(1, Int((0.04 * frameRate).rounded()))
        var lastSoundFrame = -minSoundFrameGap

        for frame in 0...totalFrames {
            let t = Double(frame) / Double(totalFrames)
            let progress = progressCurve(t: t)
            let position = start + progress * totalDistance
            // Every frame write is wrapped in a disabled transaction so SwiftUI never
            // retro-animates a single frame into a spring.
            writeRotationImmediately(position)

            let pegIndex = Int(floor(position / segmentAngle))
            if pegIndex != lastPegIndex {
                let crossings = pegIndex - lastPegIndex
                for _ in 0..<crossings {
                    lastPegIndex += 1
                    let remaining = max(0, endPegIndex - lastPegIndex)
                    let isFinalPeg = remaining <= mediumThreshold

                    // Haptics: gated past the full-speed phase to avoid chattering.
                    if t >= 0.55 {
                        if isFinalPeg {
                            medium.impactOccurred(intensity: 1.0)
                            medium.prepare()
                        } else {
                            let intensity = t < 0.85 ? 0.6 : 0.85
                            light.impactOccurred(intensity: intensity)
                            light.prepare()
                        }
                    }

                    // Sound: plays from the start of the spin, throttled. Final pegs
                    // bypass the throttle so the closing ticks always land.
                    if isFinalPeg || frame - lastSoundFrame >= minSoundFrameGap {
                        SoundService.shared.play(isFinalPeg ? .tickStrong : .tickLight)
                        lastSoundFrame = frame
                    }
                }
            }

            try? await Task.sleep(for: .seconds(dt))
        }

        // Guarantee the binding value equals `target` exactly (no leftover micro-gap).
        writeRotationImmediately(target)
        success.notificationOccurred(.success)
        SoundService.shared.play(.success)
    }

    /// Single ease-out cubic over the whole spin. Smooth, natural deceleration to zero velocity.
    /// Guarantees `progressCurve(0) == 0` and `progressCurve(1) == 1` exactly.
    private func progressCurve(t: Double) -> Double {
        let inv = 1 - t
        return 1 - inv * inv * inv
    }
}
