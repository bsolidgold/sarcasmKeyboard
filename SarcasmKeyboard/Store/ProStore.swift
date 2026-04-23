import Foundation
import StoreKit
import SarcasmKit

@Observable
@MainActor
final class ProStore {
    static let productID = "com.sarcasmkeyboard.app.pro.unlock"

    private(set) var product: Product?
    private(set) var isPro: Bool = SharedDefaults.isPro
    private(set) var purchaseInFlight: Bool = false
    var lastError: String?

    init() {
        // ProStore is app-lifetime (owned by @main via @State), so we start
        // a long-running listener and don't bother canceling. Weak self
        // ensures the listener becomes a no-op if we're ever torn down.
        Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
    }

    func bootstrap() async {
        await loadProduct()
        await refreshEntitlement()
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            self.product = products.first
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    func refreshEntitlement() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.productID == Self.productID, tx.revocationDate == nil {
                unlocked = true
            }
        }
        setPro(unlocked)
    }

    func purchase() async -> Bool {
        guard let product else {
            lastError = "Product unavailable. Try again in a moment."
            return false
        }
        purchaseInFlight = true
        defer { purchaseInFlight = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let tx) = verification {
                    await tx.finish()
                    setPro(true)
                    return true
                }
                lastError = "Purchase could not be verified."
                return false
            case .userCancelled:
                return false
            case .pending:
                lastError = "Purchase pending approval."
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func restore() async -> Bool {
        purchaseInFlight = true
        defer { purchaseInFlight = false }
        do {
            try await AppStore.sync()
        } catch {
            lastError = error.localizedDescription
            return false
        }
        await refreshEntitlement()
        return isPro
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let tx) = result, tx.productID == Self.productID else { return }
        await tx.finish()
        await refreshEntitlement()
    }

    private func setPro(_ value: Bool) {
        isPro = value
        SharedDefaults.isPro = value
    }
}
