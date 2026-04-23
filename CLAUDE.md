---
description: 
globs: /Users/viniciuslacerda/Library/Mobile\ Documents/com\~apple\~CloudDocs/Projects/Roleo
alwaysApply: false
---

---
description: 
alwaysApply: false
---

# CLAUDE.md — Roleo

This file is read automatically by Claude Code and Cursor at the start of every session.
Never remove or rename it. Never modify it unless explicitly instructed by the developer.
Always read this file completely before writing any code, creating any file, or making
any design decision. When in doubt, this file is the source of truth.

---

## What is Roleo

Roleo is a premium iOS habit app built around a daily spin wheel mechanic.
The user creates personal habits, spins a wheel once per day, and the app randomly
selects one habit to focus on. After completing the habit, the user marks it as done
and earns streak points. The experience is intentionally frictionless — one decision
per day, beautifully presented.

One **streak freeze** is granted per calendar week. If the user misses a day, the freeze
auto-applies on next app launch, saving the streak. Frozen days appear as ❄️ in the
history calendar. Every Sunday, a **weekly digest** notification celebrates the past
week's completions with warm, human copy.

**Monetization:** Paid-only subscription. No free tier. No feature gating.
The app is fully usable during the 3-day free trial. After trial expiry, a paywall
blocks access until the user subscribes.
- Monthly: $4.99 USD — product ID `com.seunome.roleo.premium.monthly`
- Annual: $29.99 USD — product ID `com.seunome.roleo.premium.annual`

---

## App icon — visual identity reference

The Roleo app icon is a colorful prize wheel on a warm cream squircle background.
The wheel has 6 segments in distinct vivid colors (green, olive, blue, orange, red/pink,
dark red), separated by warm gold dividing lines and enclosed in a gold ring border.
Each segment contains a simple white-gold icon (running shoe, leaf, book, fist,
dumbbell, lightbulb). The center is a raised gold dome with a white 4-pointed sparkle.
A small gold arrow pointer anchors at the top of the gold ring, pointing down into
the wheel — indicating the selected habit.

This icon defines the visual DNA of the app:
- Warm cream backgrounds
- Vivid saturated segment colors
- Gold as the premium accent metal
- Clean white icons on colored surfaces
- Soft rounded everything

All UI decisions should feel consistent with this icon's warmth and character.

---

## File placement

Both CLAUDE.md and PLAN.md live at the ROOT of the Xcode project folder:

```
Roleo/                          ← Xcode project root — files go HERE
├── CLAUDE.md
├── PLAN.md
├── Roleo/                      ← Swift source files
│   ├── RoleoApp.swift
│   └── ...
└── Roleo.xcodeproj
```

Open the OUTER Roleo/ folder in Cursor, not the inner Swift source folder.

---

## Platform and deployment targets

- **Minimum deployment target:** iOS 18.0
- **Primary device:** iPhone (portrait orientation only for v1.0)
- **Swift version:** Swift 6.0 — strict concurrency checking ENABLED
- **Xcode version:** Xcode 16.3 or later
- **SwiftUI:** SwiftUI 6 (iOS 18 APIs used throughout)
- **SwiftData:** SwiftData with iOS 18 schema versioning APIs
- **WidgetKit:** AppIntentTimelineProvider (iOS 17+ API)
- **Swift Skills:** All installed Swift agent skills must be applied —
  especially SwiftUI motion, transitions, and animation skills.

---

## Architecture — MVVM strict rules

Pattern is always: **Model → Service/ViewModel → View**. No exceptions.

### ViewModels
- Use `@Observable` macro — NEVER `ObservableObject`, `@StateObject`, or `@ObservedObject`
- Annotate every ViewModel class with `@MainActor`
- Inject ViewModels from root via `.environment(viewModel)` — never instantiate inside child View
- Access in child views with `@Environment(SpinViewModel.self) var vm`
- ViewModels contain all business logic — views are declarative UI only

### Views
- All views are `struct` conforming to `View`
- `@State` only for local ephemeral UI state (sheet, focus, animation trigger)
- `@Environment(\.modelContext)` for SwiftData context
- `@Query` with `SortDescriptor` and `#Predicate` for all SwiftData fetches
- Extract subviews when body exceeds 80 lines
- `@ViewBuilder` for conditional composition helpers

### Models
- Persistent: `@Model` macro (SwiftData)
- Non-persistent: `struct` — never `class`
- Model files never import SwiftUI

---

## Tech stack — exact APIs to use

### SwiftData
- `@Model` on all persistent classes
- `ModelContainer(for: [Habit.self, SpinResult.self])` in `RoleoApp.swift`
- `@Query(sort: \Habit.sortOrder)` for habit lists
- `#Predicate<SpinResult>` for filtered queries
- Always explicit `try modelContext.save()` — never rely on autosave
- UserDefaults ONLY for: notification time, onboarding flag, seed flag
- Never CoreData. Never Realm. Never Firebase.

### SwiftUI (iOS 18)
- `NavigationStack` with typed `NavigationPath` — never `NavigationView`
- `TabView` with `.tabViewStyle(.automatic)`
- `@Environment(\.dismiss)` for sheets — never `presentationMode`
- `ContentUnavailableView` for all empty states
- `PhaseAnimator` for multi-phase sequential animations
- `KeyframeAnimator` for complex keyframe sequences
- `.symbolEffect(.bounce, value:)` for SF Symbol micro-animations
- `.sensoryFeedback()` for all haptics — never UIKit haptic classes
- `TimelineView(.animation)` + `Canvas` for particle systems
- `Canvas { context, size in }` for the spin wheel
- `List` with `.listStyle(.insetGrouped)` for habits and settings
- `@FocusState` for keyboard focus management
- `.matchedGeometryEffect` for shared element transitions between views
- `.navigationTransition(.zoom(sourceID:in:))` for zoom transitions (iOS 18)

### Concurrency (Swift 6 strict)
- All async work uses `async/await` — never DispatchQueue
- `Task { }` for fire-and-forget in synchronous contexts
- `@MainActor` on all ViewModels and UI-touching classes
- `AsyncStream` for `Transaction.updates`
- Never `DispatchQueue.main.async` — use `await MainActor.run { }`

### StoreKit 2
- `Product.products(for: AppConstants.Store.allProductIDs)` at launch
- Handle ALL `PurchaseResult` cases: `.success`, `.userCancelled`, `.pending`
- Always call `transaction.finish()` after `.success`
- `Transaction.currentEntitlements` on every launch
- `AppStore.sync()` for restore purchases
- `StoreService` is `@Observable @MainActor`

### WidgetKit
- Extension: `RoleoWidget`
- `AppIntentTimelineProvider` — never legacy `TimelineProvider`
- App Group: `group.com.seunome.roleo`
- `WidgetCenter.shared.reloadAllTimelines()` after spin, completion, new day

### Notifications
- `UNUserNotificationCenter` — request permission during onboarding step 3
- `UNCalendarNotificationTrigger` with `repeats: true`
- Identifier: `"roleo.daily.reminder"`
- Body strings (rotate by day-of-year index):
  - "Time to spin your wheel! 🎡"
  - "Your habit is waiting. Let's go!"
  - "One spin. One habit. One step forward. 🌀"
  - "Keep your streak alive today."
  - "Spin the wheel. Build the life. ✨"

#### Weekly digest notification
- Identifier: `"roleo.weekly.digest"`
- Trigger: `UNCalendarNotificationTrigger` — Sunday (weekday 1), hour 10, minute 0, `repeats: true`
- Title: `"Weekly recap 🎡"`
- Body: scheduled dynamically from `NotificationService.scheduleWeeklyDigest(completedThisWeek: Int)`.
  Called each time the scene becomes `.active` (in `ContentView.onChange(of: scenePhase)`).
- Body variants by `completedThisWeek`:
  - `0`: "A fresh week starts today. Spin your wheel and build the momentum."
  - `1–2`: "You completed \(n) habit(s) last week. Good start — keep building!"
  - `3–4`: "Solid week — \(n) habits done. You're building something real. 🔥"
  - `5–6`: "Incredible week — \(n) habits! You're on fire. ✨"
  - `7+`: "Perfect week — \(n) habits done! You're unstoppable. 🏆"

### Haptics — sensoryFeedback only
```swift
.sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: spinStarted)
.sensoryFeedback(.impact(weight: .heavy), trigger: spinCompleted)
.sensoryFeedback(.success, trigger: habitCompleted)
.sensoryFeedback(.notification(.warning), trigger: streakMilestone)
```

---

## Transitions and motion — MANDATORY, not optional

This is a premium app. Every navigation action, every state change, every screen
appearance must have a deliberate, polished animation. Motion is not decorative —
it is part of the product experience. Agents must implement transitions on every
screen and component they build. Never leave a transition as the default system fade.

### Navigation transitions
```swift
// Tab switching — custom spring cross-fade
// Each tab content uses .transition(.opacity.combined(with: .scale(0.97)))
// applied with .animation(.spring(response: 0.35, dampingFraction: 0.8))

// Sheet presentation — always interactive, spring-driven
// .presentationDetents and .presentationDragIndicator(.visible) on all sheets

// NavigationStack push — zoom transition where possible
// .navigationTransition(.zoom(sourceID: habit.id, in: namespace))
// For standard push: default NavigationStack slide is acceptable
```

### View appearance animations
Every new view that appears must animate its content in. Use staggered delays:
```swift
// Pattern: each major element enters with a slight delay
// Element 1: .offset(y: 20).opacity(0) → .offset(y: 0).opacity(1), delay: 0.0s
// Element 2: same, delay: 0.08s
// Element 3: same, delay: 0.16s
// Spring: response 0.45, dampingFraction 0.75
// Trigger: @State var appeared = false, set to true in .onAppear
```

### List and card animations
```swift
// Habit rows appearing: staggered scale + fade
// Each row: .scaleEffect(appeared ? 1 : 0.92).opacity(appeared ? 1 : 0)
// Delay: index * 0.05 seconds
// Spring: response 0.4, dampingFraction 0.7

// Card tap feedback: .scaleEffect(isPressed ? 0.96 : 1.0)
// Duration: 0.1s on press, spring release

// Row insertion (new habit): height animation 0 → full + opacity 0 → 1
// .animation(.spring(response: 0.4, dampingFraction: 0.7))

// Row deletion: slide out to trailing + fade
// .transition(.asymmetric(insertion: .push(from: .trailing),
//                         removal: .push(from: .leading).combined(with: .opacity)))
```

### Spin wheel animation — physical feel
```swift
// Phase 1 (0.0–0.4s): slow start, like heavy drum being pulled
// Phase 2 (0.4–1.8s): full speed, motion blur on segments
// Phase 3 (1.8–2.8s): deceleration with mechanical resistance
//   — 3 diminishing micro-bounces as it slows
// Phase 4 (2.8–3.0s): final landing
//   — overshoots 6pt, snaps back with spring(response: 0.3, dampingFraction: 0.85)
//   — heavy haptic at exact landing moment
//   — gold ring flashes: opacity 0.4 → 1.0 → 0.4 in 0.15s
// Implementation: use interpolatingSpring(stiffness: 25, damping: 9)
// on wheelRotation state variable
```

### Result reveal animation
```swift
// Wheel: scale 1.0 → 0.82, opacity 1.0 → 0.35 (0.3s ease out)
// Habit hero circle: scale 0 → 1.06 → 1.0
//   spring(response: 0.45, dampingFraction: 0.68)
// Concentric rings: staggered expand, delay 0.12s each, 0.6s each
// Habit name text: .opacity(0) → .opacity(1), delay 0.25s, 0.4s duration
// Result card: .offset(y: 280) → .offset(y: 0)
//   spring(response: 0.5, dampingFraction: 0.78)
```

### Completion celebration
```swift
// Button: color morphs orange → green over 0.3s
// Checkmark: stroke draws itself, 0.4s, easeInOut
// Particle burst: 80 particles, warm palette, 2.5s, TimelineView + Canvas
// "+10 XP": .offset(y: 0) → .offset(y: -64), opacity 1 → 0, 0.9s easeOut
// XP counter in header: digit roll animation, 0.4s
// Habit icon: .scaleEffect(1.0 → 1.18 → 1.0), spring
// Heavy success haptic at completion moment
```

### Sheet and modal animations
```swift
// All sheets: .presentationDetents([.medium, .large])
// HabitFormView: .presentationDetents([.fraction(0.72)])
// Milestone modals: custom overlay, not system sheet
//   entry: .scaleEffect(0.7 → 1.02 → 1.0) + backdrop .opacity(0 → 1)
//   spring(response: 0.5, dampingFraction: 0.7)
//   dismiss: reverse, 0.25s ease in

// Paywall: .fullScreenCover with custom transition
//   entry: .move(edge: .bottom) + .opacity
//   spring(response: 0.5, dampingFraction: 0.85)
```

### Calendar grid animation (History screen)
```swift
// Cells fill in staggered on appear:
// Each cell: .scaleEffect(0.5 → 1.0) + .opacity(0 → 1)
// Delay: (row * 7 + column) * 0.018 seconds
// Spring: response 0.35, dampingFraction 0.65
// Total animation duration: ~0.8s for full grid
```

### Milestone streak modals
```swift
// Entry: scale 0.7 → 1.02 → 1.0, spring(response: 0.5, dampingFraction: 0.7)
// Backdrop: opacity 0 → 0.6, 0.25s ease
// Internal elements stagger: title delay 0.1s, stats delay 0.2s, button delay 0.3s
// 7-day: gold glow pulses in and out after entry (scale 1.0 → 1.08 → 1.0, 2s loop)
// 100-day: additional particle burst on entry, 3 colors (orange, green, gold)
```

### Tab bar icon animation
```swift
// Active tab icon: .scaleEffect(1.0 → 1.15 → 1.0)
//   spring(response: 0.3, dampingFraction: 0.6) on selection
// Color transition: inactive → active tint over 0.2s
```

---

## Visual design system — Warm Creamy Light Theme

### Design philosophy
Roleo's visual language is warm, creamy, joyful, and physically grounded.
Every surface should feel like high-quality paper or warm porcelain — not cold glass,
not flat digital. The app has weight, warmth, and softness.

Key qualities to achieve in every screen:
- **Creamy, not white:** backgrounds are warm ivory and cream — never pure white,
  never cool gray. Think warm morning light on a surface.
- **Shadows everywhere:** every card, every button, every floating element has a
  visible warm shadow. Depth is created through layering and shadow, not color blocking.
  Shadows are always warm-tinted (orange or amber tinted), never black or gray.
- **Gold as the premium metal:** gold (#C9A84C) is used for dividers, borders on
  special elements, milestone moments, and XP rewards. It connects to the app icon's
  gold ring and gives Roleo a distinct premium identity.
- **Vivid colors on cream:** the 6 habit colors (green, olive, blue, orange, red, pink)
  are vivid and saturated. They pop dramatically against the warm cream background —
  like colored tiles on ivory stone.
- **Rounded and soft:** all corners are generously rounded. Nothing sharp or angular.
  The UI feels friendly and tactile, as if you could reach in and spin the wheel.
- **Celebratory moments:** XP gains, streak milestones, and completions are treated
  as genuine celebrations — particles, bounces, color bursts, sound + haptics.

### Global background — creamy gradient, always
```swift
// Apply in ContentView as the outermost ZStack background layer
LinearGradient(
    colors: [
        Color(hex: "#FDF6EC"),  // warm ivory top
        Color(hex: "#FAF0DC")   // deeper warm cream bottom
    ],
    startPoint: .top,
    endPoint: .bottom
)
.ignoresSafeArea()
```

### Shadow system — warm, layered, present everywhere
```swift
// LEVEL 1 — Default card (habits list rows, stat cards, small components)
.shadow(color: Color(hex: "#C8873A").opacity(0.10), radius: 12, x: 0, y: 4)
.shadow(color: Color(hex: "#C8873A").opacity(0.05), radius: 4,  x: 0, y: 1)

// LEVEL 2 — Elevated card (result card, habit form, main panels)
.shadow(color: Color(hex: "#C8873A").opacity(0.15), radius: 20, x: 0, y: 6)
.shadow(color: Color(hex: "#C8873A").opacity(0.07), radius: 6,  x: 0, y: 2)

// LEVEL 3 — Floating element (SPIN button, CTA buttons, FAB)
.shadow(color: Color(hex: "#FF6B35").opacity(0.28), radius: 20, x: 0, y: 8)
.shadow(color: Color(hex: "#FF6B35").opacity(0.12), radius: 6,  x: 0, y: 3)

// LEVEL 4 — Modal / milestone overlay
.shadow(color: Color(hex: "#C8873A").opacity(0.20), radius: 40, x: 0, y: 16)

// RULE: Never use black shadows. Never use gray shadows.
// Always use warm amber/orange tinted shadows.
// Apply at least LEVEL 1 to every card-like element in the app.
```

### WarmCard ViewModifier — use on all card surfaces
```swift
// In View+Extensions.swift — usage: .warmCard(radius: 20)
struct WarmCard: ViewModifier {
    var radius: CGFloat = 20
    var level: Int = 1  // 1 or 2

    func body(content: Content) -> some View {
        content
            .background(Color(hex: "#FFFFFF"), in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Color(hex: "#1A1207").opacity(0.05), lineWidth: 0.5)
            )
            .shadow(
                color: Color(hex: "#C8873A").opacity(level == 1 ? 0.10 : 0.15),
                radius: level == 1 ? 12 : 20,
                x: 0, y: level == 1 ? 4 : 6
            )
            .shadow(
                color: Color(hex: "#C8873A").opacity(level == 1 ? 0.05 : 0.07),
                radius: level == 1 ? 4 : 6,
                x: 0, y: level == 1 ? 1 : 2
            )
    }
}

extension View {
    func warmCard(radius: CGFloat = 20, level: Int = 1) -> some View {
        modifier(WarmCard(radius: radius, level: level))
    }
}
```

### Color palette — always use AppConstants.Colors, never hardcode

**Backgrounds:**
- Page top: `#FDF6EC` — warm ivory
- Page bottom: `#FAF0DC` — warm cream
- Card surface: `#FFFFFF` — pure white (pops against cream background)
- Card elevated / selected: `#FFF8F0` — warm white, slightly tinted

**Primary brand color:**
- Orange: `#FF6B35` — SPIN button, primary CTAs, active tab, key actions
- Orange soft: `#FFF0E8` — orange-tinted chip backgrounds, badges

**Secondary brand color — Warm Teal (replaces violet):**
- Teal: `#00A896` — streaks, XP display, level system, secondary actions
- Teal soft: `#E0F5F3` — teal-tinted backgrounds
- NOTE: This is a warm teal, not cool cyan. It harmonizes with the cream and orange
  palette without competing with it. Confident and fresh.

**Success:**
- Green: `#2ECC8F` — completion checkmarks, done states, calendar completed days
- Green soft: `#E3F9F0`

**Gold — premium metal accent:**
- Gold: `#C9A84C` — wheel dividers, XP rewards, milestone moments, icon borders
- Gold bright: `#FFB800` — XP counter text, streak milestones, gold badges
- Gold soft: `#FFF8E0`

**Status:**
- Coral/warning: `#FF6B6B` — missed days, at-risk streak
- Coral soft: `#FFF0F0`

**Text:**
- Primary: `#1A1207` — very dark warm brown, never cold black
- Secondary: `#7A6652` — warm mid-brown
- Tertiary: `#B8A898` — warm light brown, captions
- On colored surfaces: always `#FFFFFF`

**Habit segment colors (match app icon):**
- Segment 1: `#4CAF50` — vivid green (exercise/run)
- Segment 2: `#7B8B3E` — olive green (nature/growth)
- Segment 3: `#64B5F6` — sky blue (reading)
- Segment 4: `#FF7043` — deep orange (strength)
- Segment 5: `#E91E63` — vivid pink-red (dumbbell)
- Segment 6: `#C62828` — deep red (lightbulb/ideas)

### Corner radii — rounded everywhere, always
- XL: 28pt — modals, paywall card, milestone cards
- L: 20pt — main habit cards, result card, HabitFormView
- M: 16pt — buttons, input fields, smaller cards, stat chips
- S: 12pt — inner elements, badges, small components
- Pill: 99pt — fully rounded chips, toggles, pills
- **Absolute rule: no corner radius below 12pt anywhere in the app**

### Typography — SF Pro, warm hierarchy
- Display XL: SF Pro Display Black, 40pt+ — streak number hero, celebration
- Display L: SF Pro Display Bold, 28–32pt — spin result habit name
- Title: SF Pro Display Semibold, 20–22pt — screen headers
- Body Large: SF Pro Text Semibold, 17pt — habit names, primary content
- Body: SF Pro Text Regular, 15pt — supporting content
- Caption: SF Pro Text Medium, 12pt — labels, dates, metadata
- Micro: SF Pro Text Regular, 11pt — legal, footer
- Text primary: `#1A1207` on light backgrounds
- White text: only on colored/orange buttons and filled colored surfaces

### SPIN button — hero of the app
```swift
// Style spec:
// Width: screen width minus 40pt (20pt horizontal padding each side)
// Height: 64pt
// Corner radius: 22pt
// Fill: Color(hex: "#FF6B35")
// Text: "SPIN" — SF Pro Display Black, 22pt, white, letter-spacing 0.06em
// Shadow: Level 3 (floating element shadow from shadow system above)
// Left icon: SF Symbol "arrow.clockwise", 20pt, white
// On press: .scaleEffect(0.95), spring return, light haptic
// Subtle inner highlight: top edge 1pt white at 15% opacity (3D lift)
```

### Tab bar
```swift
// tint: Color(hex: "#FF6B35")   — active tab
// unselectedItemTintColor: Color(hex: "#B8A898")  — inactive
// Background: white with very soft warm shadow above
// Use .toolbarBackground(.visible, for: .tabBar)
```

### Streak pill / XP chip components
```swift
// Streak pill: HStack with 🔥 emoji + "12-day streak" text
// Background: Color(hex: "#FFF0E8"), radius 99pt
// Border: Color(hex: "#FF6B35").opacity(0.2), 0.5pt
// Text: Color(hex: "#FF6B35"), SF Pro Text Semibold 13pt
// Shadow: Level 1

// XP chip: similar pattern with teal color (#00A896 tint)
```

---

## Data models — exact Swift definitions

```swift
// Core/Models/Habit.swift
import SwiftData
import Foundation

@Model
final class Habit {
    var id: UUID
    var name: String
    var iconName: String      // Valid SF Symbol name
    var colorHex: String      // Format: "#RRGGBB"
    var isActive: Bool
    var sortOrder: Int
    var createdAt: Date

    init(name: String, iconName: String, colorHex: String,
         isActive: Bool = true, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}

// Core/Models/SpinResult.swift
import SwiftData
import Foundation

@Model
final class SpinResult {
    var id: UUID
    var date: Date            // Always startOfDay normalized
    var habitID: UUID
    var habitName: String     // Denormalized — survives habit deletion
    var habitIconName: String
    var habitColorHex: String
    var isCompleted: Bool
    var completedAt: Date?

    init(date: Date, habit: Habit) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.habitID = habit.id
        self.habitName = habit.name
        self.habitIconName = habit.iconName
        self.habitColorHex = habit.colorHex
        self.isCompleted = false
        self.completedAt = nil
    }
}

// Core/Models/UserStats.swift
import Foundation

struct UserStats: Equatable {
    var currentStreak: Int
    var longestStreak: Int
    var totalCompleted: Int
    var totalPoints: Int
    var completionRate: Double  // 0.0 to 1.0
    static let empty = UserStats(currentStreak: 0, longestStreak: 0,
                                  totalCompleted: 0, totalPoints: 0, completionRate: 0.0)
}
```

---

## Default habits — seed on first launch

```swift
func seedDefaultHabitsIfNeeded(context: ModelContext) {
    guard !UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.hasSeededHabits)
    else { return }

    let defaults: [(name: String, icon: String, color: String)] = [
        ("Exercise",  "figure.run",    "#4CAF50"),
        ("Meditate",  "mind.and.body", "#00A896"),
        ("Read",      "book.fill",     "#64B5F6"),
        ("Hydrate",   "drop.fill",     "#7B8B3E"),
        ("Gratitude", "heart.fill",    "#E91E63")
    ]

    for (index, habit) in defaults.enumerated() {
        context.insert(Habit(name: habit.name, iconName: habit.icon,
                             colorHex: habit.color, sortOrder: index))
    }
    try? context.save()
    UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.hasSeededHabits)
}
```

---

## Streak calculation — exact logic

```swift
func calculateStats(from results: [SpinResult]) -> UserStats {
    let completed = results.filter { $0.isCompleted }
    let sortedDays = results.map { $0.date }.sorted(by: >)

    var streak = 0
    var checkDate = Calendar.current.startOfDay(for: Date())
    for day in sortedDays {
        if Calendar.current.isDate(day, inSameDayAs: checkDate) {
            if completed.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
            } else { break }
        }
    }

    var points = completed.count * AppConstants.Points.perCompletion
    if streak >= 7   { points += AppConstants.Points.streakBonus7 }
    if streak >= 30  { points += AppConstants.Points.streakBonus30 }
    if streak >= 100 { points += AppConstants.Points.streakBonus100 }

    return UserStats(currentStreak: streak, longestStreak: streak,
                     totalCompleted: completed.count, totalPoints: points,
                     completionRate: results.isEmpty ? 0 : Double(completed.count) / Double(results.count))
}
```

---

## AppConstants.swift — complete

```swift
import Foundation

enum AppConstants {
    enum Store {
        static let monthlyProductID = "com.seunome.roleo.premium.monthly"
        static let annualProductID  = "com.seunome.roleo.premium.annual"
        static let allProductIDs    = [monthlyProductID, annualProductID]
    }

    enum AppGroup {
        static let suiteName            = "group.com.seunome.roleo"
        static let widgetStreak         = "widget.streak"
        static let widgetTodayHabitName = "widget.todayHabitName"
        static let widgetTodayHabitIcon = "widget.todayHabitIcon"
        static let widgetTodayCompleted = "widget.todayCompleted"
    }

    enum UserDefaultsKeys {
        static let hasSeededHabits        = "hasSeededHabits"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let notificationHour       = "notificationHour"
        static let notificationMinute     = "notificationMinute"
        static let notificationsEnabled   = "notificationsEnabled"
    }

    enum Points {
        static let perCompletion  = 10
        static let streakBonus7   = 50
        static let streakBonus30  = 200
        static let streakBonus100 = 1000
    }

    enum Colors {
        // Backgrounds
        static let backgroundTop    = "#FDF6EC"
        static let backgroundBottom = "#FAF0DC"
        static let cardSurface      = "#FFFFFF"
        static let cardElevated     = "#FFF8F0"

        // Brand
        static let primaryOrange    = "#FF6B35"
        static let primarySoft      = "#FFF0E8"
        static let secondaryTeal    = "#00A896"   // warm teal — replaces violet
        static let secondarySoft    = "#E0F5F3"
        static let successGreen     = "#2ECC8F"
        static let successSoft      = "#E3F9F0"
        static let gold             = "#C9A84C"   // premium metal accent
        static let goldBright       = "#FFB800"   // XP, milestones
        static let goldSoft         = "#FFF8E0"
        static let coral            = "#FF6B6B"   // warning, missed
        static let coralSoft        = "#FFF0F0"

        // Text
        static let textPrimary   = "#1A1207"
        static let textSecondary = "#7A6652"
        static let textTertiary  = "#B8A898"

        // Habit segment colors (match app icon)
        static let habitGreen    = "#4CAF50"
        static let habitOlive    = "#7B8B3E"
        static let habitBlue     = "#64B5F6"
        static let habitOrange   = "#FF7043"
        static let habitPink     = "#E91E63"
        static let habitRed      = "#C62828"
    }

    enum SF {
        static let tabSpin     = "circle.dotted.circle"
        static let tabHabits   = "list.bullet.circle"
        static let tabHistory  = "calendar.circle"
        static let tabSettings = "gearshape.circle"
    }
}
```

---

## RoleoApp.swift — exact setup

```swift
import SwiftUI
import SwiftData

@main
struct RoleoApp: App {
    @State private var storeService = StoreService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeService)
                .modelContainer(for: [Habit.self, SpinResult.self])
                .task {
                    await storeService.loadProducts()
                    await storeService.checkEntitlements()
                }
        }
    }
}
```

---

## Complete folder structure

```
Roleo/                              ← project root
├── CLAUDE.md
├── PLAN.md
├── Roleo/                          ← Swift source files
│   ├── App/
│   │   ├── RoleoApp.swift
│   │   └── ContentView.swift
│   ├── Features/
│   │   ├── Spin/
│   │   │   ├── SpinView.swift
│   │   │   ├── SpinViewModel.swift
│   │   │   ├── WheelView.swift
│   │   │   └── ResultCardView.swift
│   │   ├── Habits/
│   │   │   ├── HabitsView.swift
│   │   │   ├── HabitsViewModel.swift
│   │   │   └── HabitFormView.swift
│   │   ├── History/
│   │   │   ├── HistoryView.swift
│   │   │   ├── HistoryViewModel.swift
│   │   │   └── CalendarGridView.swift
│   │   ├── Paywall/
│   │   │   └── PaywallView.swift
│   │   ├── Onboarding/
│   │   │   └── OnboardingView.swift
│   │   └── Settings/
│   │       └── SettingsView.swift
│   └── Core/
│       ├── Models/
│       │   ├── Habit.swift
│       │   ├── SpinResult.swift
│       │   └── UserStats.swift
│       ├── Services/
│       │   ├── StoreService.swift
│       │   └── NotificationService.swift
│       ├── Extensions/
│       │   ├── Color+Hex.swift
│       │   ├── Date+Extensions.swift
│       │   └── View+Extensions.swift
│       └── Resources/
│           └── AppConstants.swift
├── RoleoWidget/
│   ├── RoleoWidget.swift
│   ├── SmallWidgetView.swift
│   └── MediumWidgetView.swift
└── Roleo.xcodeproj
```

---

## Absolute rules — never break

```
❌ NavigationView              → ✅ NavigationStack
❌ ObservableObject            → ✅ @Observable
❌ @StateObject                → ✅ @State (for @Observable ViewModels)
❌ @ObservedObject             → ✅ @Environment(ViewModel.self)
❌ CoreData                    → ✅ SwiftData
❌ DispatchQueue.main.async    → ✅ @MainActor or await MainActor.run {}
❌ UIImpactFeedbackGenerator   → ✅ .sensoryFeedback() modifier
❌ Hardcoded colors in View    → ✅ AppConstants.Colors + Color(hex:)
❌ Logic inside View body      → ✅ ViewModel methods only
❌ Force unwrap (!) anywhere   → ✅ guard let / if let / ?? default
❌ try! anywhere               → ✅ do { try } catch {}
❌ TODO comments               → ✅ Write real implementation
❌ Third-party packages        → ✅ Ask developer first, prefer native APIs
❌ UserDefaults for models     → ✅ SwiftData @Model
❌ Dark backgrounds            → ✅ Warm creamy light theme only in v1.0
❌ Cool white (#FFFFFF alone)  → ✅ Always on warm cream background
❌ Gray or black shadows       → ✅ Always warm amber/orange tinted shadows
❌ No shadow on cards          → ✅ Every card has at minimum Level 1 shadow
❌ Sharp corners (<12pt)       → ✅ Always rounded, minimum 12pt radius
❌ No transition on new screen → ✅ Every view appearance has spring animation
❌ Default system transitions  → ✅ Custom spring transitions on all views
❌ Violet/purple accent        → ✅ Warm teal #00A896 as secondary color
❌ iOS 16 deprecated APIs      → ✅ iOS 18 equivalents always
❌ Fixed pixel text sizes      → ✅ Dynamic Type compatible relative sizes
```

---

## Session Notes - April 2026 Quality Adjustments

- Paywall benefit copy now avoids promising the pending WidgetKit feature before it ships.
- Onboarding and habits copy now frame reminders and habit setup as a warmer daily ritual.
- History includes a small progress reflection so progress feels more personal than a passive log.
- Spin CTA and History rows have clearer accessibility labels.
- Habit writes now roll back on SwiftData save failure instead of silently ignoring failed saves.
