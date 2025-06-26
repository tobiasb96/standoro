import SwiftUI
import StoreKit

struct ProUpgradeView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Standoro Pro")
                        .font(.largeTitle)
                        .bold()
                    Text("One-time purchase, all future updates included")
                        .font(.headline)
                        .foregroundColor(.settingsSubheader)
                }
                .padding(.bottom, 8)
                
                // Feature comparison
                VStack(alignment: .leading, spacing: 12) {
                    Text("Free Features")
                        .font(.title2)
                        .bold()
                    featureRow(icon: "figure.stand", text: "Stand & focus sessions")
                    featureRow(icon: "figure.walk", text: "Movement challenges")
                    featureRow(icon: "bell.badge", text: "Posture nudges")
                }
                .padding(.bottom, 16)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pro Features")
                        .font(.title2)
                        .bold()
                    featureRow(icon: "chart.bar.xaxis", text: "Detailed stats & insights")
                    featureRow(icon: "airpods", text: "Posture monitoring with AirPods")
                    featureRow(icon: "calendar", text: "Calendar-aware notifications")
                    featureRow(icon: "sparkles", text: "All future Pro updates & improvements")
                    featureRow(icon: "heart", text: "Support a solo developer ❤️")
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                if purchaseManager.isProUnlocked {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Thank you for supporting Standoro!")
                            .font(.title2)
                            .bold()
                        Text("You have unlocked all Pro features. Enjoy!")
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    VStack(spacing: 12) {
                        if let price = purchaseManager.proProduct?.displayPrice {
                            Text("Unlock Standoro Pro for **\(price)**")
                                .font(.title2)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Unlock Standoro Pro for **$9.99**")
                                .font(.title2)
                                .multilineTextAlignment(.center)
                        }
                        Button(action: {
                            Task {
                                try? await purchaseManager.buyPro()
                            }
                        }) {
                            Text("Buy Now")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(purchaseManager.proProduct == nil)
                        
                        Button("Restore Purchase") {
                            Task { await purchaseManager.restore() }
                        }
                        .buttonStyle(.bordered)
                        
                        #if DEBUG
                        Divider()
                            .padding(.vertical, 8)
                        
                        VStack(spacing: 8) {
                            Text("Debug Controls")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                Button("Simulate Purchase") {
                                    purchaseManager.simulatePurchase()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button("Reset Purchase") {
                                    purchaseManager.resetPurchase()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding(.top, 8)
                        #endif
                    }
                }
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .onAppear {
            if purchaseManager.proProduct == nil {
                Task { await purchaseManager.restore() }
            }
        }
    }
    
    @ViewBuilder
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 20)
            Text(text)
            Spacer()
        }
        .font(.body)
    }
}

#Preview {
    ProUpgradeView()
        .environmentObject(PurchaseManager())
        .background(Color.settingsBackground)
} 