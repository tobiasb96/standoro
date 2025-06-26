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
        #if DEBUG
        // Enable StoreKit testing in debug builds
        Task {
            try? await AppStore.sync()
        }
        #endif
        
        Task {
            await fetchProduct()
            await updatePurchasedStatus()
            observeTransactionUpdates()
        }
    }
    
    // MARK: - Public API
    func buyPro() async throws {
        guard let product = proProduct else { 
            #if DEBUG
            print("PurchaseManager: No product available for purchase")
            #endif
            return 
        }
        
        #if DEBUG
        print("PurchaseManager: Attempting to purchase product: \(product.id)")
        #endif
        
        let result = try await product.purchase()
        switch result {
        case .success(let verificationResult):
            if case .verified(_) = verificationResult {
                isProUnlocked = true
                #if DEBUG
                print("PurchaseManager: Purchase successful and verified")
                #endif
            } else {
                #if DEBUG
                print("PurchaseManager: Purchase successful but verification failed")
                #endif
            }
        case .userCancelled:
            #if DEBUG
            print("PurchaseManager: Purchase cancelled by user")
            #endif
        case .pending:
            #if DEBUG
            print("PurchaseManager: Purchase pending approval")
            #endif
        @unknown default:
            #if DEBUG
            print("PurchaseManager: Unknown purchase result")
            #endif
        }
    }
    
    func restore() async {
        do {
            try await AppStore.sync()
            await updatePurchasedStatus()
            #if DEBUG
            print("PurchaseManager: Restore completed")
            #endif
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
            #if DEBUG
            if let product = proProduct {
                print("PurchaseManager: Product fetched successfully - \(product.displayName) (\(product.displayPrice))")
            } else {
                print("PurchaseManager: No product found for ID: \(proProductId)")
            }
            #endif
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
                #if DEBUG
                print("PurchaseManager: Found valid entitlement for Pro")
                #endif
                return
            default:
                continue
            }
        }
        // No entitlement found – user has not purchased
        isProUnlocked = false
        #if DEBUG
        print("PurchaseManager: No valid entitlements found")
        #endif
    }
    
    private func observeTransactionUpdates() {
        // Listen for future transactions
        Task.detached(operation: {
            for await update in Transaction.updates {
                if case .verified(let transaction) = update, transaction.productID == self.proProductId {
                    await MainActor.run {
                        self.isProUnlocked = true
                        #if DEBUG
                        print("PurchaseManager: Transaction update - Pro unlocked")
                        #endif
                    }
                }
            }
        })
    }
    
    #if DEBUG
    // MARK: - Debug helpers for testing
    func simulatePurchase() {
        isProUnlocked = true
        print("PurchaseManager: Simulated purchase - Pro unlocked")
    }
    
    func resetPurchase() {
        isProUnlocked = false
        print("PurchaseManager: Reset purchase - Pro locked")
    }
    #endif
} 