import Foundation
import StoreKit
import SwiftUI
import Combine

@MainActor
class PurchaseManager: ObservableObject {
    @Published var isProUnlocked: Bool = false
    @Published var proProduct: Product?
    
    // Replace with your actual product identifier in App Store Connect
    private let proProductId = "com.standoro.pro"
    
    init() {
        Task {
            await fetchProduct()
            await updatePurchasedStatus()
            observeTransactionUpdates()
        }
    }
    
    // MARK: - Public API
    func buyPro() async throws {
        guard let product = proProduct else { return }
        let result = try await product.purchase()
        switch result {
        case .success(let verificationResult):
            if case .verified(_) = verificationResult {
                isProUnlocked = true
            }
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }
    
    func restore() async {
        do {
            try await AppStore.sync()
            await updatePurchasedStatus()
        } catch {
            #if DEBUG
            print("PurchaseManager: Restore failed – \(error)")
            #endif
        }
    }
    
    // MARK: - Private helpers
    private func fetchProduct() async {
        do {
            proProduct = try await Product.products(for: [proProductId]).first
        } catch {
            #if DEBUG
            print("PurchaseManager: Failed to fetch product – \(error)")
            #endif
        }
    }
    
    private func updatePurchasedStatus() async {
        for await entitlement in Transaction.currentEntitlements {
            switch entitlement {
            case .verified(let transaction) where transaction.productID == proProductId:
                isProUnlocked = true
                return
            default:
                continue
            }
        }
        // No entitlement found – user has not purchased
        isProUnlocked = false
    }
    
    private func observeTransactionUpdates() {
        // Listen for future transactions
        Task.detached(operation: {
            for await update in Transaction.updates {
                if case .verified(let transaction) = update, transaction.productID == self.proProductId {
                    await MainActor.run {
                        self.isProUnlocked = true
                    }
                }
            }
        })
    }
} 