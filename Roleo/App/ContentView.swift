import SwiftUI
import SwiftData

@available(iOS 18.0, *)
struct ContentView: View {
    enum Tab: Int, Hashable, CaseIterable {
        case spin, habits, history, settings

        var title: String {
            switch self {
            case .spin:     return "Spin"
            case .habits:   return "Habits"
            case .history:  return "History"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .spin:     return AppConstants.SF.tabSpin
            case .habits:   return AppConstants.SF.tabHabits
            case .history:  return AppConstants.SF.tabHistory
            case .settings: return AppConstants.SF.tabSettings
            }
        }
    }

    @Environment(StoreService.self) private var storeService
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppConstants.UserDefaultsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @State private var selectedTab: Tab = .spin
    @State private var hideTabBar = false

    /// Shared spring used by both the page slide and the tab bar pill so the two
    /// motions feel like a single coordinated gesture.
    private static let pageSpring: Animation = .spring(response: 0.42, dampingFraction: 0.85)

    var body: some View {
        ZStack {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        TabPage(tab: tab, selected: selectedTab) {
                            viewForTab(tab)
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
                .offset(x: -CGFloat(selectedTab.rawValue) * geo.size.width)
                .animation(Self.pageSpring, value: selectedTab)
            }
            .clipped()
        }
        .warmBackground()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !hideTabBar {
                CustomTabBar(selected: $selectedTab, pageSpring: Self.pageSpring)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: hideTabBar)
        .tint(Color(hex: AppConstants.Colors.primaryOrange))
        .onPreferenceChange(HideCustomTabBarKey.self) { newValue in
            hideTabBar = newValue
        }
        .onAppear {
            seedDefaultHabitsIfNeeded(context: modelContext)
        }
        .fullScreenCover(isPresented: onboardingBinding) {
            OnboardingView()
        }
        .fullScreenCover(isPresented: paywallBinding) {
            PaywallView() // hard gate: no onClose
        }
    }

    @ViewBuilder
    private func viewForTab(_ tab: Tab) -> some View {
        switch tab {
        case .spin:     SpinView()
        case .habits:   HabitsView()
        case .history:  HistoryView()
        case .settings: SettingsView()
        }
    }

    private var onboardingBinding: Binding<Bool> {
        Binding(
            get: { !hasCompletedOnboarding },
            set: { newValue in
                if !newValue {
                    hasCompletedOnboarding = true
                }
            }
        )
    }

    private var paywallBinding: Binding<Bool> {
        Binding(
            get: { hasCompletedOnboarding && !storeService.isSubscribed && !storeService.isInTrial },
            set: { _ in }
        )
    }
}

// MARK: - TabPage

/// Holds a single tab's content alive in the hierarchy (preserving its state
/// across tab switches). Positioned inside the sliding carousel HStack, so
/// visibility is controlled by the parent's offset — not by opacity here.
///
/// Responsibilities:
/// - Disable hit testing on off-screen tabs so taps don't leak mid-animation.
/// - Strip `HideCustomTabBarKey` preferences from inactive tabs so their
///   internal state can't toggle the global bar visibility.
private struct TabPage<Content: View>: View {
    let tab: ContentView.Tab
    let selected: ContentView.Tab
    @ViewBuilder var content: () -> Content

    private var isActive: Bool { tab == selected }

    var body: some View {
        content()
            .allowsHitTesting(isActive)
            .transformPreference(HideCustomTabBarKey.self) { value in
                if !isActive { value = false }
            }
    }
}

// MARK: - Custom tab bar

/// iOS 18-style tab bar with a Capsule highlight around the selected item and
/// a label that only appears for the active tab (Apple Music / Mail pattern).
private struct CustomTabBar: View {
    @Binding var selected: ContentView.Tab
    let pageSpring: Animation
    @Namespace private var capsuleNamespace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(ContentView.Tab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            // Warm cream-to-amber gradient instead of cold glass — lands the
            // bar inside the Roleo palette instead of floating above it.
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#FFFAF1"),
                            Color(hex: "#FFEAC9")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color(hex: "#E8A36F").opacity(0.28), lineWidth: 1)
                )
                // Inner top highlight for a subtle "rim-lit" feel.
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.7), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            ),
                            lineWidth: 1
                        )
                        .blendMode(.overlay)
                )
                .shadow(
                    color: Color(hex: "#C8873A").opacity(0.18),
                    radius: 14, x: 0, y: 6
                )
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
        .sensoryFeedback(.selection, trigger: selected)
    }

    private func tabButton(for tab: ContentView.Tab) -> some View {
        let isActive = tab == selected
        let accent = Color(hex: AppConstants.Colors.primaryOrange)
        let inactive = Color(hex: AppConstants.Colors.textSecondary).opacity(0.75)
        let activeLabel = Color.white

        return Button {
            guard !isActive else { return }
            withAnimation(pageSpring) {
                selected = tab
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    // Bounce on selection so the icon acknowledges the tap.
                    .symbolEffect(.bounce, value: isActive)
                if isActive {
                    Text(tab.title)
                        .font(.system(.footnote, design: .rounded).weight(.bold))
                        .lineLimit(1)
                        .fixedSize()
                        .transition(
                            .scale(scale: 0.7, anchor: .leading)
                                .combined(with: .opacity)
                        )
                }
            }
            .foregroundStyle(isActive ? activeLabel : inactive)
            .padding(.horizontal, isActive ? 14 : 12)
            .padding(.vertical, 10)
            .background {
                if isActive {
                    // Orange-filled active pill with a soft glow — reads as
                    // the selected tab from across the room.
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    accent,
                                    accent.opacity(0.88)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: accent.opacity(0.4), radius: 8, x: 0, y: 4)
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                                .blendMode(.overlay)
                        )
                        .matchedGeometryEffect(id: "tabCapsule", in: capsuleNamespace)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(tab.title))
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}

// MARK: - Preference: hide the custom tab bar

struct HideCustomTabBarKey: PreferenceKey {
    static let defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension View {
    /// Requests that the custom tab bar hides itself (e.g. while a modal-like
    /// panel is expanding out of the `+` button). Propagated up the view tree
    /// via `HideCustomTabBarKey`.
    func hideCustomTabBar(_ hide: Bool) -> some View {
        preference(key: HideCustomTabBarKey.self, value: hide)
    }
}

// MARK: - Seeding

func seedDefaultHabitsIfNeeded(context: ModelContext) {
    guard !UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.hasSeededHabits)
    else { return }

    // Colors match the app icon's segment palette (CLAUDE.md spec).
    let defaults: [(name: String, icon: String, color: String)] = [
        ("Exercise",  "figure.run",           AppConstants.Colors.habitGreen),
        ("Meditate",  "figure.mind.and.body",  AppConstants.Colors.secondaryTeal),
        ("Read",      "book.fill",             AppConstants.Colors.habitBlue),
        ("Hydrate",   "drop.fill",             AppConstants.Colors.habitOlive),
        ("Gratitude", "heart.fill",            AppConstants.Colors.habitPink)
    ]

    for (index, habit) in defaults.enumerated() {
        context.insert(
            Habit(
                name: habit.name,
                iconName: habit.icon,
                colorHex: habit.color,
                sortOrder: index
            )
        )
    }

    try? context.save()
    UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.hasSeededHabits)
}

#Preview {
    ContentView()
        .environment(StoreService())
        .modelContainer(for: [Habit.self, SpinResult.self], inMemory: true)
}
