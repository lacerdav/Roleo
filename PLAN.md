# PLAN.md — Roleo

Roadmap vivo do projeto. Update at the end of every work session.
Last updated: April 2026

---

## Product overview

Roleo is a premium iOS habit app ($4.99/month or $29.99/year, 3-day free trial, no free tier).
Daily spin wheel mechanic: user creates habits → spins once per day → completes the selected habit → earns streak and XP.

**Design theme:** Warm creamy light — bright, tactile, rounded, celebratory.
Warm cream backgrounds (#FDF6EC → #FAF0DC), bold orange primary (#FF6B35),
warm teal secondary (#00A896), gold premium accents (#C9A84C), generous corner radii,
and warm shadows. Never dark, never cold.

---

## File placement — important

```
Roleo/                    ← place CLAUDE.md and PLAN.md HERE
├── CLAUDE.md
├── PLAN.md
├── Roleo/                ← Swift source code lives here
│   └── ...
└── Roleo.xcodeproj
```

Open the OUTER Roleo/ folder in Cursor, not the inner one.

---

## Decisions log

| Date | Decision | Reason |
|---|---|---|
| Apr 2026 | iOS 18.0 minimum | Modern APIs, no legacy fallback |
| Apr 2026 | Swift 6.0 strict concurrency | Safe, no race conditions |
| Apr 2026 | SwiftData over CoreData | Native SwiftUI integration |
| Apr 2026 | @Observable over ObservableObject | Less boilerplate, Swift 5.9+ |
| Apr 2026 | Warm light theme for v1.0 | More joyful, better fit for habit app category |
| Apr 2026 | Warm teal replaces violet as secondary accent | Better harmony with cream, orange, and gold brand system |
| Apr 2026 | Dark theme deferred to v1.1 | Ship light first, validate with users |
| Apr 2026 | Paid-only, no free tier | Committed users, lower churn |
| Apr 2026 | $4.99/month + $29.99/year | Internationally accessible, premium positioning |
| Apr 2026 | Widget in v1.0 MVP | Key differentiator vs competitors |
| Apr 2026 | App name: Roleo | Works in EN and PT-BR, memorable |

---

## v1.0 Status

| Phase | Description | Status |
|---|---|---|
| 1 | Setup and base structure | ✅ Done |
| 2 | SpinView — wheel mechanic | ✅ Done |
| 3 | HabitsView — CRUD | ✅ Done |
| 4 | HistoryView — calendar + stats | ✅ Done |
| 5 | SettingsView + notifications | ✅ Done |
| 6 | WidgetKit — small + medium | 🔲 Pending (deferred to just before submission) |
| 7 | Paywall + StoreKit 2 | ✅ Done |
| 8 | Onboarding — 3 screens | ✅ Done |
| 9 | Polish — animations, haptics, a11y | ✅ Done (covered by phases 11–16) |
| 10 | App Store submission | 🔲 Pending |
| 11 | Design system refinement | ✅ Done |
| 12 | Spin experience polish | ✅ Done |
| 13 | Habits refinement | ✅ Done |
| 14 | History refinement | ✅ Done |
| 15 | Onboarding, paywall, settings polish | ✅ Done |
| 16 | Accessibility + final QA | 🔲 Pending |

**Status note (April 2026):** All phases 1–9 are fully implemented. Phases 11–16 are
refinement passes.
- Phase 11: fixed two black shadows (SpinView hint capsule, HabitsView delete overlay), replaced violet/purple confetti colors with warm-palette equivalents.
- Phase 12: fixed black shadow on WheelView segment icons; added staggered spring entrance animations to SpinResultModalView (icon circle, habit name, toast text).
- Phase 13: removed pulsing orangeGlow from readiness pill; HabitFormView default color changed to secondaryTeal; violet (premiumWarmPurple) replaced by secondaryTeal in colorOptions; icon picker unselected cells now use cardElevated background; checkmark overlay added to selected color circle.
- Phase 14: CalendarGridView noSpin/future cell colors changed from Color.secondary to warm textPrimary tints; completed cells gain warm green shadow; staggered spring entrance animation added to all 35 cells.
- Phase 15: OnboardingView notifications page mascot changed to .happy (ritual invitation, not hesitation); "Your ritual time" label added inside the DatePicker card. PaywallView premiumWarmPurple replaced with secondaryTeal in hero angular gradient; unselected plan card shadow fixed from black to warm amber. SettingsView "Expired" status renamed "Trial ended"; expired-state footer copy added.

**Source of truth note:** If this roadmap and `CLAUDE.md` ever diverge on product rules,
visual system, or technical constraints, treat `CLAUDE.md` as authoritative and update
this file accordingly at the end of the session.

---

## Phase 1 — Setup and base structure

**Goal:** Project builds and runs on iPhone 16 Pro simulator with 4-tab navigation,
warm light background, SwiftData configured, 5 default habits seeded on first launch.

### Checklist
- [ ] Delete Xcode auto-generated `Item.swift`
- [ ] Create folder structure exactly as defined in CLAUDE.md
- [ ] `Core/Models/Habit.swift` — exact model from CLAUDE.md
- [ ] `Core/Models/SpinResult.swift` — exact model from CLAUDE.md
- [ ] `Core/Models/UserStats.swift` — exact struct from CLAUDE.md
- [ ] `Core/Resources/AppConstants.swift` — complete, exact values from CLAUDE.md
- [ ] `Core/Extensions/Color+Hex.swift` — Color init from hex string
- [ ] `Core/Extensions/Date+Extensions.swift` — startOfDay, isSameDay helpers
- [ ] `Core/Extensions/View+Extensions.swift` — WarmCard ViewModifier
- [ ] `Core/Services/StoreService.swift` — @Observable @MainActor skeleton
- [ ] `Core/Services/NotificationService.swift` — skeleton only
- [ ] `App/RoleoApp.swift` — exact implementation from CLAUDE.md
- [ ] `App/ContentView.swift` — TabView 4 tabs, warm gradient background
- [ ] Seed 5 default habits on first launch (exact function from CLAUDE.md)
- [ ] Build clean: zero errors, zero warnings on iPhone 16 Pro simulator

### Cursor prompt for Phase 1
```
Read CLAUDE.md and PLAN.md completely before writing any code.

We are building Phase 1 of Roleo. The Xcode project already exists.
Delete Item.swift if it exists — it was auto-generated and is not needed.

Create the complete folder structure and implement all base files
exactly as specified in CLAUDE.md.

Key requirements:
- Swift 6.0 strict concurrency enabled
- iOS 18.0 deployment target
- Warm light theme throughout — background gradient #FDF6EC to #FAF0DC
- WarmCard ViewModifier in View+Extensions.swift (defined in CLAUDE.md)
- ModelContainer with [Habit.self, SpinResult.self] in RoleoApp.swift
- StoreService injected via .environment() from RoleoApp
- ContentView: TabView with 4 tabs (Spin, Habits, History, Settings)
  Each tab shows a placeholder for now, warm gradient background applied
- Seed 5 default habits on first launch using exact function in CLAUDE.md
- Zero TODO comments — write real stub implementations
- Zero build errors or warnings

After completing, confirm which files were created and state
that the project should build cleanly.
```

---

## Phase 2 — SpinView (wheel mechanic)

**Goal:** Colorful animated spin wheel with warm light theme. Sorts one habit per day.
Animated result reveal. "Mark as done" with celebration.

### Checklist
- [ ] `WheelView.swift` — Canvas rendering:
  - 6 segments, each habit's colorHex at 60% opacity
  - Gold dividing lines between segments (0.5pt, warm gold #C9A84C)
  - SF Symbol icon centered in each segment (28pt, white)
  - Habit name in .caption below icon (white)
  - Center hub: white circle 60pt with small orange sparkle
  - Fixed pointer at TOP: small downward triangle in primary orange #FF6B35
  - Wheel sits on warm background with soft warm shadow beneath it
- [ ] `SpinViewModel.swift` — @Observable @MainActor:
  - `var wheelRotation: Double = 0`
  - `var selectedHabit: Habit? = nil`
  - `var isSpinning: Bool = false`
  - `var todayResult: SpinResult? = nil`
  - `var hasSpunToday: Bool` — computed from todayResult
  - `func spin(habits:context:)` — random habit selection, 4–7 full rotations + segment offset
  - `func markComplete(context:)` — set isCompleted, save, update widget
  - Rotation animation: `.interpolatingSpring(stiffness: 25, damping: 9)`
- [ ] `ResultCardView.swift` — slides up from bottom after spin:
  - White card, radius 20pt, warm shadow
  - Habit icon circle 52pt (colored) + name in Display Bold + "Today's habit" caption
  - "Mark as Done ✓" button — success green #2ECC8F, full width
  - "Completed ✓" badge state if already done
  - Entry: `.transition(.move(edge: .bottom).combined(with: .opacity))`
- [ ] `SpinView.swift` — main screen:
  - Top row: streak pill (🔥 + "12-day streak", orange pill) + XP amount right
  - Center: WheelView taking ~55% of screen height
  - SPIN button: exactly as specified in CLAUDE.md design system
  - Disabled state if hasSpunToday (replaced by ResultCardView)
  - `ContentUnavailableView` if zero active habits
- [ ] Confetti particle system: `TimelineView(.animation)` + `Canvas`
  - Warm colors: orange, teal, gold, green, pink
  - 80 particles, 2.5s duration
- [ ] Haptics per CLAUDE.md spec
- [ ] Update App Group UserDefaults after spin and after completing
- [ ] `WidgetCenter.shared.reloadAllTimelines()` after state changes

### Cursor prompt for Phase 2
```
Read CLAUDE.md completely before writing any code.
Build the complete Spin feature: WheelView, SpinViewModel, ResultCardView, SpinView.

Visual style: warm light theme — white card for ResultCardView with warm shadow,
orange SPIN button (#FF6B35), warm background throughout.
The wheel uses colorful segments on a warm cream background, NOT a dark background.

Follow CLAUDE.md exactly for:
- Canvas wheel rendering with gold dividing lines and SF Symbol icons
- Rotation calculation (4–7 full turns + segment offset to land correctly)
- Spring animation .interpolatingSpring(stiffness: 25, damping: 9)
- Confetti with warm color palette
- Haptics with .sensoryFeedback() only
- WarmCard modifier on ResultCardView

SpinViewModel must load today's SpinResult from SwiftData on appear
using #Predicate filtered to today's startOfDay.
Call WidgetCenter.shared.reloadAllTimelines() after spin and completion.
```

---

## Phase 3 — HabitsView (CRUD)

**Goal:** Clean list of habits with fast creation and editing. Warm card style.

### Checklist
- [ ] `HabitsViewModel.swift` — @Observable @MainActor:
  - `func addHabit(name:iconName:colorHex:context:)`
  - `func updateHabit(_:name:iconName:colorHex:isActive:context:)`
  - `func deleteHabit(_:context:)`
  - `func toggleActive(_:context:)`
  - `func reorder(habits:context:)`
- [ ] `HabitFormView.swift` — bottom sheet:
  - Text field: large 24pt input, warm placeholder, 30 char max, @FocusState
  - SF Symbol icon picker: LazyVGrid 4 columns, 18 icons
  - Color picker: row of 6 color dots from AppConstants.Colors habit colors
  - Live preview: mini slot item showing selected icon + color + name
  - Save button: orange #FF6B35, disabled when name empty or duplicate
- [ ] `HabitsView.swift`:
  - Large title "Habits" + "+" orange circle button top right
  - @Query(sort: \Habit.sortOrder) list
  - Each row: WarmCard with icon circle 40pt + name + streak caption + toggle
  - Inactive habits: row at 50% opacity
  - Swipe-to-delete: confirmationDialog before deleting
  - .onMove for drag reorder, updates sortOrder
  - Warning banner if active habits are below the confirmed minimum required to spin
  - ContentUnavailableView for empty state

### Cursor prompt for Phase 3
```
Read CLAUDE.md completely before writing any code.
Build the complete Habits feature: HabitsViewModel, HabitFormView, HabitsView.

Visual style: warm light theme throughout.
Habit rows are WarmCard style (white card, warm orange shadow).
The "+" button and Save button use primary orange #FF6B35.

HabitFormView must show a live preview of the habit icon + color combination.
Icon options: figure.run, book.fill, drop.fill, heart.fill, mind.and.body,
moon.fill, sun.max.fill, flame.fill, music.note, fork.knife, dumbbell.fill,
brain.head.profile, leaf.fill, star.fill, bolt.fill, cup.and.saucer.fill

Show warning banner when active habits are below the confirmed minimum required to spin.
Do not hardcode a threshold that conflicts with implementation or future product decisions.
```

---

## Phase 4 — HistoryView (calendar + stats)

**Goal:** Visual progress calendar + stat cards + scrollable history list.

### Checklist
- [ ] `HistoryViewModel.swift` — @Observable @MainActor:
  - `func calculateStats(from: [SpinResult]) -> UserStats` — exact logic from CLAUDE.md
  - `func groupByMonth(_ results: [SpinResult]) -> [(String, [SpinResult])]`
- [ ] `CalendarGridView.swift` — 30-day grid:
  - 7 columns, cells are 36pt circles
  - Completed: filled #2ECC8F (success green)
  - Missed: filled rgba warm brown at 15% — `Color(hex: "#1A1207").opacity(0.12)`
  - No spin: circle outline `Color(hex: "#1A1207").opacity(0.08)`, 0.5pt
  - Today: outline with 1.5pt orange border #FF6B35
  - Tap: popover with habit name + date
- [ ] `HistoryView.swift`:
  - Large title "History"
  - 3 stat cards in row (WarmCard style): 🔥 streak, total done, XP total
  - Month section header (caption uppercase, textTertiary)
  - CalendarGridView
  - LazyVStack history list grouped by month
  - Each row: WarmCard — icon 32pt + name + date + green checkmark or coral X
  - ContentUnavailableView if no history yet

### Cursor prompt for Phase 4
```
Read CLAUDE.md completely before writing any code.
Build History feature: HistoryViewModel, CalendarGridView, HistoryView.

Implement calculateStats() using the exact algorithm in CLAUDE.md.

CalendarGrid: warm light colors only.
Completed cells: #2ECC8F filled circles.
Today: orange border #FF6B35.
No dark colors anywhere.

Stat cards use WarmCard modifier, numbers in SF Pro Display Black.
History rows use WarmCard modifier with warm shadows.
```

---

## Phase 5 — SettingsView + Notifications

**Goal:** Notification time picker + subscription status + app info.

### Checklist
- [ ] `NotificationService.swift` — complete:
  - `func requestPermission() async -> Bool`
  - `func scheduleDailyNotification(hour: Int, minute: Int)`
  - `func cancelNotifications()`
  - Rotating notification texts from CLAUDE.md (5 strings, day-of-year index)
- [ ] `SettingsView.swift`:
  - List .insetGrouped on warm background
  - Section "Notifications": toggle + DatePicker when enabled
  - Section "Subscription": status text + Restore Purchases button (orange)
  - Section "App": version + Privacy Policy link
  - On appear: check UNUserNotificationCenter permission status

### Cursor prompt for Phase 5
```
Read CLAUDE.md completely before writing any code.
Build NotificationService and SettingsView.

Use UNCalendarNotificationTrigger, identifier "roleo.daily.reminder".
Rotate notification body text by day-of-year index (5 strings from CLAUDE.md).
Save hour/minute to UserDefaults keys in AppConstants.UserDefaultsKeys.

SettingsView: warm light background, List .insetGrouped style.
Orange accent color on toggles and interactive elements.
```

---

## Phase 6 — WidgetKit

**Goal:** Small and medium home screen widgets showing streak and today's habit.

### Checklist
- [ ] Enable App Groups in both app and widget targets: `group.com.seunome.roleo`
- [ ] `RoleoWidget.swift` — AppIntentTimelineProvider:
  - Read from `UserDefaults(suiteName: AppConstants.AppGroup.suiteName)`
  - Timeline: current entry + midnight entry
- [ ] `RoleoEntry.swift` — TimelineEntry with streak, habitName, habitIcon, isCompleted
- [ ] `SmallWidgetView.swift`:
  - Warm background gradient matching app
  - Large streak number SF Pro Display Black + 🔥 + "day streak" caption
- [ ] `MediumWidgetView.swift`:
  - Left: small widget layout
  - Right: today's habit card — icon circle + name + "Done ✓" or "Spin now →"
- [ ] Update App Group defaults in SpinViewModel after spin and completion
- [ ] `WidgetCenter.shared.reloadAllTimelines()` at every state change

### Cursor prompt for Phase 6
```
Read CLAUDE.md completely before writing any code.
Build RoleoWidget extension with AppIntentTimelineProvider.

Widget reads from UserDefaults(suiteName: "group.com.seunome.roleo").
Keys defined in AppConstants.AppGroup.

SmallWidgetView: warm cream background #FDF6EC, large streak number
centered, orange flame emoji, "day streak" caption in textSecondary.

MediumWidgetView: left column same as small, right column habit card
with colored icon circle + habit name + completion pill.
Completion pill: green "Done ✓" if completed, orange "Spin now →" if not.
```

---

## Phase 7 — Paywall + StoreKit 2

**Goal:** Beautiful paywall that converts. Full StoreKit 2 subscription logic.

### Checklist
- [ ] `StoreService.swift` — complete @Observable @MainActor:
  - `loadProducts()` — Product.products(for: allProductIDs)
  - `purchase(_ product:)` — handle .success, .userCancelled, .pending
  - `checkEntitlements()` — Transaction.currentEntitlements on launch
  - `restorePurchases()` — AppStore.sync()
  - `listenForTransactions()` — Task with AsyncStream from Transaction.updates
  - `var isSubscribed: Bool`, `var isInTrial: Bool`
- [ ] `PaywallView.swift` — full screen cover:
  - Warm background, large wheel icon/illustration at top
  - "Roleo Premium" title + "3 days free, cancel anytime" caption
  - 3 benefit rows: icon square (warm teal tinted) + description
  - 2 plan cards side by side (monthly + annual with "-50%" green badge)
  - "Start Free Trial" CTA — orange #FF6B35 button, full width, 60pt
  - "Restore Purchases" + "Privacy Policy" footer links
- [ ] ContentView gates: show PaywallView as .fullScreenCover when trial expired

### Cursor prompt for Phase 7
```
Read CLAUDE.md completely before writing any code.
Complete StoreService with full StoreKit 2 implementation.
Always call transaction.finish() after .success.
Handle all PurchaseResult cases explicitly.

PaywallView: warm light theme, orange CTA button #FF6B35.
Annual plan card: selected by default, green "-50%" badge.
Monthly plan: standard card, not selected by default.
Benefits icons: warm teal tinted square chips #00A896.
```

---

## Phase 8 — Onboarding

**Goal:** 3-screen intro shown once on first launch. Sets up notifications.

### Checklist
- [ ] `OnboardingView.swift` — TabView(.page):
  - Screen 1: large warm orb illustration + "Welcome to Roleo" + tagline + "Get Started"
  - Screen 2: live slow-scrolling slot machine preview + "One habit. Every day." + benefits row
  - Screen 3: notification bell + time picker + "Allow Notifications" button + "Skip"
  - "Get Started" on last screen: sets hasCompletedOnboarding = true, dismisses
- [ ] ContentView: show OnboardingView as .fullScreenCover on first launch

### Cursor prompt for Phase 8
```
Read CLAUDE.md completely before writing any code.
Build OnboardingView with TabView(.page), 3 screens.

All screens: warm light background, orange primary buttons.
Screen 1: centered orange glowing orb (SwiftUI Circle with orange gradient + shadow)
Screen 2: static preview of slot machine frame showing 3 habits
Screen 3: DatePicker + NotificationService.requestPermission() call

On "Get Started": UserDefaults set hasCompletedOnboarding = true.
ContentView shows OnboardingView .fullScreenCover when !hasCompletedOnboarding.
```

---

## Phase 9 — Polish

**Goal:** App Store ready. Every animation perfect. Every empty state designed.

### Checklist
- [ ] Milestone streak modals (7/30/100 days) — specs in CLAUDE.md
- [ ] All empty states using ContentUnavailableView with warm illustrations
- [ ] PhaseAnimator on result card reveal
- [ ] Slow animation mode for wheel (Settings debug toggle, remove before ship)
- [ ] VoiceOver labels on all interactive elements
- [ ] Dynamic Type: test at max font size on every screen
- [ ] Haptic audit: every tap has correct feedback
- [ ] App Icon 1024×1024 added to Assets.xcassets
- [ ] Launch screen configured
- [ ] Test on: iPhone SE (3rd gen), iPhone 16, iPhone 16 Pro Max

---

## Phase 10 — App Store submission

### Checklist
- [ ] Apple Developer account active ($99/year)
- [ ] Bundle ID `com.seunome.roleo` registered
- [ ] Capabilities: Push Notifications, StoreKit, App Groups
- [ ] Subscription products created in App Store Connect (sandbox first)
- [ ] RocketSim screenshots: all required sizes with device bezels
- [ ] App preview video: shows spin animation (30s max)
- [ ] App Store description EN (primary) + PT-BR (localized)
- [ ] Keywords: habits, daily, spin wheel, routine, streak
- [ ] Privacy Policy URL live (GitHub Pages or Notion)
- [ ] TestFlight beta: 5–10 users, collect feedback
- [ ] Submit for review

---

## Phase 11 — UI Direction and design system refinement

**Goal:** Lock Roleo into one cohesive visual direction and remove drift between the
warm premium identity in CLAUDE.md and the more playful/game-like UI patterns that
emerged during implementation.

### Checklist
- [ ] Treat `CLAUDE.md` as source of truth for the app's visual DNA
- [ ] Replace any conflicting visual language that feels cartoon, arcade, or too game-like
- [ ] Standardize typography hierarchy across all screens
- [ ] Standardize spacing rhythm, section gaps, and card padding across the app
- [ ] Audit corner radius usage and keep surfaces within the defined rounded system
- [ ] Audit color roles: orange = primary action, teal = secondary/progress, gold = premium/reward, green = completion
- [ ] Audit elevation and warm-shadow usage so surfaces read as intentional layers
- [ ] Consolidate repeated UI styling into reusable, reviewable component patterns

---

## Phase 12 — Spin experience polish

**Goal:** Refine the core spin journey so the wheel, result reveal, and completion
celebration feel like one premium signature experience.

### Checklist
- [ ] Rework the visual hierarchy of `SpinView` so the wheel is the undisputed focal point
- [ ] Align `WheelView` styling with Roleo's warm cream + gold premium direction
- [ ] Simplify header badges so they support the hero moment instead of competing with it
- [ ] Refine the spin result reveal into a stronger, more theatrical transition
- [ ] Unify the result presentation so there is one clear visual pattern for "today's habit"
- [ ] Reduce overlapping visual noise during spin, reveal, and celebration states
- [ ] Make the completion celebration feel rewarding without becoming visually chaotic
- [ ] Validate the full spin flow on smaller devices for balance, readability, and comfort

---

## Phase 13 — Habits and forms refinement

**Goal:** Make habit creation and management feel calmer, more native, and more premium.

### Checklist
- [ ] Refine `HabitsView` row hierarchy: icon, title, status, and controls
- [ ] Make list rows feel clearly tappable and easier to scan
- [ ] Soften the warning state when there are not enough active habits
- [ ] Refine the add/edit flow so it feels integrated rather than interruptive
- [ ] Improve `HabitFormView` grouping, spacing, and visual breathing room
- [ ] Strengthen selected states for icon and color pickers
- [ ] Elevate the live preview so it feels like a payoff, not just another row
- [ ] Validate the habit form with long names, large text, and one-handed use

---

## Phase 14 — History and progress delight

**Goal:** Turn the history area into a motivating progress surface instead of a passive log.

### Checklist
- [ ] Refine stat cards so they feel more premium and less generic
- [ ] Improve the visual rhythm between header, stats, calendar, and grouped history rows
- [ ] Make the 30-day calendar feel more intentional and celebratory on completion days
- [ ] Improve distinction between completed, missed, and no-spin states without relying on color alone
- [ ] Make month grouping easier to scan at a glance
- [ ] Review empty-state design so it still feels warm and encouraging
- [ ] Validate scroll performance and readability as history grows

---

## Phase 15 — Onboarding, paywall, and settings polish

**Goal:** Polish the supporting flows so first impression, monetization, and settings all
feel consistent with the core product quality.

### Checklist
- [ ] Sharpen onboarding narrative: aspiration, mechanic, then reminder setup
- [ ] Make onboarding page-to-page progression feel more distinct and emotionally clear
- [ ] Refine the notification setup step so it feels like a ritual choice, not permission plumbing
- [ ] Design a full premium `PaywallView` aligned with Roleo's visual identity
- [ ] Ensure the paywall sells the product feeling, not only the subscription terms
- [ ] Keep `SettingsView` lighter and more native than feature screens
- [ ] Refine settings sections for notifications, subscription, and app information
- [ ] Review trust signals across onboarding, paywall, and settings copy/layout

---

## Phase 16 — Accessibility, motion, and final UX QA

**Goal:** Complete the quality pass that makes the app feel finished, inclusive, and
ready for broad real-world use.

### Checklist
- [ ] Audit Dynamic Type on every major screen at larger accessibility sizes
- [ ] Add VoiceOver labels, hints, and grouping to all major interactive elements
- [ ] Review custom overlays and sheets for focus behavior and dismissal clarity
- [ ] Respect Reduce Motion with calmer fallback transitions where needed
- [ ] Review information currently communicated by color only and add secondary cues
- [ ] Add final micro-interactions: numeric transitions, press states, subtle tab polish, and symbol effects
- [ ] Validate consistency of haptics, motion timing, and feedback across all major flows
- [ ] Run a final UI/UX review pass on iPhone SE, standard iPhone, and Max-size devices

---

## Post-launch roadmap

### v1.1 (60 days after launch)
- Multiple wheels (morning / afternoon / evening)
- Apple Watch app
- Dark mode theme

### v1.2 (6 months)
- Accountability partner / shared streaks
- Weekly insights
- Price increase to $5.99/month with Watch app justifying it

---

## Known issues

- `PLAN.md` historically drifted from `CLAUDE.md` on visual system details; use `CLAUDE.md`
  as source of truth whenever they conflict.
- Older roadmap language referenced violet as the secondary accent; v1.0 direction is now
  warm teal + gold premium accents.
- The minimum active-habit threshold required to spin should be treated as a product rule
  that must stay consistent across roadmap, implementation, and UX copy.
- The phase status table may lag the actual codebase because later features already have
  partial implementations.

---

## Next session

Resume from the highest-priority incomplete phase based on the actual codebase, not only
the table above. Confirm `CLAUDE.md` and `PLAN.md` are still aligned before starting.

---

## Session Notes - April 2026 Quality Adjustments

- Replaced paywall benefit copy that promised the pending widget with shipped reminder-focused value.
- Warmed onboarding and habits copy so setup feels like a ritual, not an unlock mechanic.
- Added a small History progress reflection to make completed spins feel more personal and motivating.
- Improved accessibility labels for the Spin CTA and History rows/reflection.
- Hardened `HabitsViewModel` SwiftData saves with rollback on failure instead of silent `try?` writes.
