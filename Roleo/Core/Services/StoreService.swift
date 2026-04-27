import Foundation
import Observation
import StoreKit

/// Outcome surfaced to the paywall UI after a purchase attempt.
enum PurchaseOutcome: Equatable {
    case success
    case userCancelled
    case pending
    case failed(String)
}

/// Wraps all StoreKit 2 access for Roleo.
///
/// Behavior:
/// - `loadProducts()` fetches the lifetime unlock declared in `AppConstants.Store`.
///   In DEBUG with the `Roleo.storekit` configuration attached to the Run scheme,
///   these resolve locally (no Apple Developer account required).
/// - `listenForTransactions()` starts an unstructured task that drains
///   `Transaction.updates` for the app lifetime and re-runs `checkEntitlements()`
///   so the UI reflects external changes (purchase outside the app, refund,
///   family sharing update, etc.).
/// - `checkEntitlements()` walks `Transaction.currentEntitlements` and unlocks
///   the app iff the lifetime non-consumable entitlement is currently active.
/// - `isInTrial` is an **app-level** 3-day grace window (so new users don't hit
///   the paywall immediately). Trial start is persisted in UserDefaults so it
///   survives relaunches.
@Observable
@MainActor
final class StoreService {
    // MARK: - Observable state

    var products: [Product] = []
    var isUnlocked = false
    var activeProduct: Product?
    var purchaseError: String?
    var isLoading = false

    // MARK: - Private

    private var updatesTask: Task<Void, Never>?

    private static let trialLengthDays = 3

    // MARK: - Init / teardown

    init() {
        listenForTransactions()
    }

    // No `deinit` cleanup: `StoreService` is owned by `RoleoApp` as `@State` and
    // lives for the app's entire lifetime. `Transaction.updates` holds `self`
    // weakly through our `[weak self]` capture, so no retain cycle forms, and
    // the underlying task is torn down automatically on app termination.

    // MARK: - Computed

    /// App-level grace window (3 days from first launch). Independent from any
    /// StoreKit introductory offer.
    var isInTrial: Bool {
        trialRemaining() > 0
    }

    /// Days left in the local trial window (0 once expired).
    func trialRemaining() -> Int {
        let now = Date()
        let start = trialStartedAt ?? now
        // Cache the start date the first time we read it.
        if trialStartedAt == nil {
            trialStartedAt = start
        }
        let elapsed = now.timeIntervalSince(start)
        let total = TimeInterval(Self.trialLengthDays) * 86_400
        let remainingSeconds = max(0, total - elapsed)
        return Int(ceil(remainingSeconds / 86_400))
    }

    var isSubscribed: Bool {
        isUnlocked
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == AppConstants.Store.lifetimeProductID }
    }

    // MARK: - Public API

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            #if DEBUG
            print("[StoreService] loadProducts requesting: \(AppConstants.Store.allProductIDs)")
            #endif
            let fetched = try await Product.products(for: AppConstants.Store.allProductIDs)
            #if DEBUG
            print("[StoreService] loadProducts received \(fetched.count) products: \(fetched.map(\.id))")
            #endif
            products = fetched
        } catch {
            #if DEBUG
            print("[StoreService] loadProducts ERROR: \(error)")
            #endif
            purchaseError = "Couldn't load products: \(error.localizedDescription)"
        }
    }

    @discardableResult
    func purchase(_ product: Product) async -> PurchaseOutcome {
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await checkEntitlements()
                return .success

            case .userCancelled:
                return .userCancelled

            case .pending:
                return .pending

            @unknown default:
                return .failed("Unknown purchase result")
            }
        } catch {
            let message = error.localizedDescription
            purchaseError = message
            return .failed(message)
        }
    }

    func checkEntitlements() async {
        var foundActive: (Product, Transaction)?

        for await verification in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(verification) else { continue }
            guard AppConstants.Store.allProductIDs.contains(transaction.productID) else { continue }

            // `currentEntitlements` only yields currently valid transactions,
            // but still ignore revoked lifetime purchases.
            if transaction.revocationDate != nil { continue }

            let product = products.first { $0.id == transaction.productID }
            guard let product else { continue }

            if let existing = foundActive {
                // Prefer the most recently purchased entitlement.
                if transaction.purchaseDate > existing.1.purchaseDate {
                    foundActive = (product, transaction)
                }
            } else {
                foundActive = (product, transaction)
            }
        }

        if let (product, _) = foundActive {
            activeProduct = product
            isUnlocked = true
        } else {
            activeProduct = nil
            isUnlocked = false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            purchaseError = "Restore failed: \(error.localizedDescription)"
        }
    }

    func listenForTransactions() {
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            for await verification in Transaction.updates {
                guard let self else { return }
                do {
                    let transaction = try self.checkVerified(verification)
                    await transaction.finish()
                    await self.checkEntitlements()
                } catch {
                    // Drop unverified transactions silently; we never unlock on them.
                }
            }
        }
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    private var trialStartedAt: Date? {
        get {
            let interval = UserDefaults.standard.double(forKey: AppConstants.UserDefaultsKeys.trialStartedAt)
            return interval > 0 ? Date(timeIntervalSince1970: interval) : nil
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: AppConstants.UserDefaultsKeys.trialStartedAt)
            } else {
                UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.trialStartedAt)
            }
        }
    }
}
