import SwiftUI
import StoreKit

/// Phase 7 paywall.
///
/// Presented in two ways:
/// 1. **Hard gate** — from `ContentView.paywallBinding` once the local 3-day
///    trial has expired and the user is not subscribed. `onClose` is `nil`, so
///    the close button is hidden. The sheet will self-dismiss automatically
///    when `StoreService.isSubscribed` flips to `true` (the binding's getter
///    returns `false`).
/// 2. **From Settings** — presented as a sheet with `onClose` wired to
///    `dismiss()` so the user can back out.
///
/// During local testing the `Roleo.storekit` configuration file (referenced by
/// the Run scheme) supplies the two products — no Apple Developer account is
/// required. In production (or after a TestFlight upload) the same product IDs
/// must exist in App Store Connect.
struct PaywallView: View {
    @Environment(StoreService.self) private var storeService
    @Environment(\.dismiss) private var dismiss

    /// When non-nil, the close button calls this. When nil, the view acts as a
    /// hard gate (no close button).
    var onClose: (() -> Void)? = nil

    @State private var selectedProductID: String = AppConstants.Store.annualProductID
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var animateBenefits = false
    @State private var loadFailed = false

    var body: some View {
        content
            .warmBackground()
        .interactiveDismissDisabled(onClose == nil)
        .task {
            loadFailed = false
            if storeService.products.isEmpty {
                await storeService.loadProducts()
                if storeService.products.isEmpty {
                    loadFailed = true
                }
            }
            await storeService.checkEntitlements()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.78).delay(0.1)) {
                animateBenefits = true
            }
        }
        .alert("Purchase failed", isPresented: errorBinding) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Layout

    private var content: some View {
        VStack(spacing: 0) {
            if let onClose {
                closeBar(onClose: onClose)
            } else {
                Spacer().frame(height: 12)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    hero
                    benefits
                    plans
                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .padding(.bottom, 20)
            }

            footer
        }
    }

    private func closeBar(onClose: @escaping () -> Void) -> some View {
        HStack {
            Spacer()
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                    .padding(10)
                    .background(
                        Circle().fill(Color(hex: AppConstants.Colors.cardSurface))
                    )
                    .overlay(
                        Circle().strokeBorder(
                            Color(hex: AppConstants.Colors.textPrimary).opacity(0.06),
                            lineWidth: 1
                        )
                    )
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 14) {
            ZStack {
                // Premium angular glow behind the mascot.
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                Color(hex: AppConstants.Colors.premiumCoralRed),
                                Color(hex: AppConstants.Colors.premiumSunsetOrange),
                                Color(hex: AppConstants.Colors.premiumGolden),
                                Color(hex: AppConstants.Colors.premiumEmerald),
                                Color(hex: AppConstants.Colors.premiumSkyBlue),
                                Color(hex: AppConstants.Colors.secondaryTeal),
                                Color(hex: AppConstants.Colors.premiumRosePink),
                                Color(hex: AppConstants.Colors.premiumCoralRed)
                            ],
                            center: .center
                        )
                    )
                    .opacity(0.28)
                    .blur(radius: 20)
                    .frame(width: 180, height: 180)

                RoleoMascot(expression: .excited, size: 140)

                // Small crown cue so the premium story still reads.
                Image(systemName: "crown.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(hex: AppConstants.Colors.goldBright))
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color(hex: AppConstants.Colors.cardSurface))
                            .shadow(color: Color(hex: "#C8873A").opacity(0.3), radius: 6, y: 3)
                    )
                    .offset(x: 50, y: -50)
            }

            Text(AppCopy.Paywall.heroTitle)
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                .multilineTextAlignment(.center)

            Text(AppCopy.Paywall.heroSubtitle)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 4)
    }

    // MARK: - Benefits

    private var benefits: some View {
        VStack(spacing: 12) {
            benefitRow(
                icon: "circle.dotted.circle",
                tint: AppConstants.Colors.primaryOrange,
                title: "Daily spin ritual",
                subtitle: "One habit, chosen by the wheel every day. No decisions, no guilt.",
                index: 0
            )
            benefitRow(
                icon: "flame.fill",
                tint: AppConstants.Colors.coral,
                title: "Streak & XP tracking",
                subtitle: "Build momentum, level up, and watch your consistency grow.",
                index: 1
            )
            benefitRow(
                icon: "bell.badge.fill",
                tint: AppConstants.Colors.secondaryTeal,
                title: "Gentle daily reminders",
                subtitle: "Choose your ritual time and get one warm nudge to spin.",
                index: 2
            )
        }
    }

    private func benefitRow(icon: String, tint: String, title: String, subtitle: String, index: Int = 0) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: tint).opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color(hex: tint))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                Text(subtitle)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: AppConstants.Colors.cardSurface))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    Color(hex: AppConstants.Colors.textPrimary).opacity(0.06),
                    lineWidth: 1
                )
        )
        .opacity(animateBenefits ? 1 : 0)
        .offset(y: animateBenefits ? 0 : 16)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.82)
                .delay(Double(index) * 0.08),
            value: animateBenefits
        )
    }

    // MARK: - Plans

    private var plans: some View {
        VStack(spacing: 12) {
            if storeService.isLoading && storeService.products.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if loadFailed {
                Text("Couldn't load plans. Tap Retry below.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Color(hex: AppConstants.Colors.coral))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                if let annual = storeService.annualProduct {
                    planCard(
                        product: annual,
                        periodLabel: "per year",
                        perUnitLabel: perMonthLabel(for: annual),
                        savingsBadge: savingsBadge()
                    )
                }
                if let monthly = storeService.monthlyProduct {
                    planCard(
                        product: monthly,
                        periodLabel: "per month",
                        perUnitLabel: nil,
                        savingsBadge: nil
                    )
                }
            }
        }
    }

    private func planCard(product: Product,
                          periodLabel: String,
                          perUnitLabel: String?,
                          savingsBadge: String?) -> some View {
        let isSelected = product.id == selectedProductID
        let accent = Color(hex: AppConstants.Colors.primaryOrange)

        return Button {
            selectedProductID = product.id
        } label: {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? accent : Color(hex: AppConstants.Colors.textPrimary).opacity(0.18),
                            lineWidth: 2
                        )
                        .background(
                            Circle().fill(isSelected ? accent : .clear)
                        )
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(planDisplayName(for: product))
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                        if let savingsBadge {
                            Text(savingsBadge)
                                .font(.system(.caption2, design: .rounded).weight(.heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(Color(hex: AppConstants.Colors.successGreen))
                                )
                        }
                    }
                    if let perUnitLabel {
                        Text(perUnitLabel)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                    }
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 0) {
                    Text(product.displayPrice)
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundStyle(Color(hex: AppConstants.Colors.textPrimary))
                    Text(periodLabel)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: AppConstants.Colors.cardSurface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        isSelected ? accent : Color(hex: AppConstants.Colors.textPrimary).opacity(0.06),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected
                    ? accent.opacity(0.18)
                    : Color(hex: "#C8873A").opacity(0.06),
                radius: isSelected ? 12 : 4,
                x: 0,
                y: isSelected ? 6 : 2
            )
        }
        .buttonStyle(.pressable(scale: 0.98, haptic: false))
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func planDisplayName(for product: Product) -> String {
        switch product.id {
        case AppConstants.Store.annualProductID:  return "Annual"
        case AppConstants.Store.monthlyProductID: return "Monthly"
        default: return product.displayName
        }
    }

    private func perMonthLabel(for annual: Product) -> String? {
        let perMonthDecimal = annual.price / 12
        let format = annual.priceFormatStyle
        let rounded = NSDecimalNumber(decimal: perMonthDecimal)
            .rounding(accordingToBehavior: NSDecimalNumberHandler(
                roundingMode: .plain,
                scale: 2,
                raiseOnExactness: false,
                raiseOnOverflow: false,
                raiseOnUnderflow: false,
                raiseOnDivideByZero: false
            )).decimalValue
        return "\(rounded.formatted(format)) / month"
    }

    private func savingsBadge() -> String? {
        guard let monthly = storeService.monthlyProduct,
              let annual = storeService.annualProduct else { return nil }
        let twelveMonths = monthly.price * 12
        guard twelveMonths > 0 else { return nil }
        let savings = (twelveMonths - annual.price) / twelveMonths
        let percent = (NSDecimalNumber(decimal: savings).doubleValue * 100).rounded()
        guard percent > 0 else { return nil }
        return "SAVE \(Int(percent))%"
    }

    // MARK: - Footer (CTA + fine print + legal)

    private var footer: some View {
        VStack(spacing: 10) {
            Button(action: purchase) {
                HStack(spacing: 8) {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                    Text(ctaTitle)
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .tracking(0.5)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(hex: AppConstants.Colors.primaryOrange))
                )
                .shadow(
                    color: Color(hex: AppConstants.Colors.primaryOrange).opacity(0.35),
                    radius: 12, x: 0, y: 6
                )
            }
            .buttonStyle(.pressable)
            .disabled(!loadFailed && (storeService.monthlyProduct == nil
                      || storeService.annualProduct == nil
                      || isPurchasing))

            Text(finePrint)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            HStack(spacing: 18) {
                Button("Restore") {
                    Task {
                        await storeService.restorePurchases()
                        if let msg = storeService.purchaseError {
                            errorMessage = msg
                        }
                    }
                }
                legalLink("Terms", url: URL(string: "https://roleo.app/terms"))
                legalLink("Privacy", url: URL(string: "https://roleo.app/privacy"))
            }
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundStyle(Color(hex: AppConstants.Colors.textSecondary))
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: AppConstants.Colors.backgroundBottom).opacity(0),
                    Color(hex: AppConstants.Colors.backgroundBottom)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private var ctaTitle: String {
        if loadFailed { return "Retry" }
        if storeService.monthlyProduct == nil && storeService.annualProduct == nil {
            return "Loading..."
        }
        return "Start 3-Day Free Trial"
    }

    private var finePrint: String {
        guard let selected = selectedProduct else {
            return "3 days free, then billed on a recurring basis. Cancel anytime."
        }
        let period = selected.id == AppConstants.Store.annualProductID ? "year" : "month"
        return "3 days free, then \(selected.displayPrice) per \(period). Cancel anytime in Settings."
    }

    private var selectedProduct: Product? {
        storeService.products.first { $0.id == selectedProductID }
    }

    @ViewBuilder
    private func legalLink(_ title: String, url: URL?) -> some View {
        if let url {
            Link(title, destination: url)
        } else {
            Text(title)
        }
    }

    // MARK: - Actions

    private func purchase() {
        if loadFailed {
            loadFailed = false
            Task {
                await storeService.loadProducts()
                if storeService.products.isEmpty { loadFailed = true }
            }
            return
        }
        guard let product = selectedProduct else { return }
        isPurchasing = true
        Task {
            let outcome = await storeService.purchase(product)
            isPurchasing = false
            switch outcome {
            case .success:
                // PaywallView will auto-dismiss via ContentView's binding
                // (isSubscribed == true). If manually presented, trigger close.
                onClose?()
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Your purchase is pending approval."
            case .failed(let message):
                errorMessage = message
            }
        }
    }

    // MARK: - Bindings

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }
}

#Preview {
    PaywallView(onClose: {})
        .environment(StoreService())
}
