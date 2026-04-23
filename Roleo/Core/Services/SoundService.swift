import Foundation
import AudioToolbox

/// Low-latency audio effects for the spin wheel (peg ticks + final ding).
///
/// Uses iOS system sounds via `AudioServicesPlaySystemSound`:
/// - No bundled assets required.
/// - Respects the iOS ring/silent switch (users in silent mode stay silent).
/// - Cheap enough to fire 10–15 times per second during deceleration without
///   audible gaps or mix issues.
///
/// Gated by `AppConstants.UserDefaultsKeys.spinSoundsEnabled` so users can
/// keep the haptic-only experience if they prefer.
@MainActor
final class SoundService {
    static let shared = SoundService()

    private init() {}

    enum Effect {
        /// Subtle high tick — used mid-deceleration while the wheel is still quick.
        case tickLight
        /// Heavier, lower tock — used for the last 3 pegs before the wheel stops.
        case tickStrong
        /// Final "wheel stopped" chime, fires once on resolution.
        case success
        /// Habit-completion celebration cue — warmer, richer than `.success`.
        /// Fires when the user marks a habit done (paired with confetti + XP).
        case celebrate

        fileprivate var systemSoundID: SystemSoundID {
            switch self {
            case .tickLight:  return 1104 // Tink
            case .tickStrong: return 1103 // Tock
            case .success:    return 1025 // Positive chime (spin landing)
            case .celebrate:  return 1322 // Payment success — brighter two-note "ding-ding"
            }
        }
    }

    var isEnabled: Bool {
        // Default to ON — we register a default in RoleoApp.init.
        UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.spinSoundsEnabled)
    }

    func play(_ effect: Effect) {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(effect.systemSoundID)
    }
}
