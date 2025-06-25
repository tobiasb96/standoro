import SwiftUI

struct AboutView: View {
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(spacing: 24) {
            // App Icon and Name
            VStack(spacing: 16) {
                Image("Text hinzufügen 512x512")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .cornerRadius(16)
                
                VStack(spacing: 4) {
                    Text("Standoro")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.settingsHeader)
                    
                    Text("Your intelligent companion for maintaining health and productivity")
                        .font(.subheadline)
                        .foregroundColor(.settingsSubheader)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Version Info
            VStack(spacing: 8) {
                Text("Version 1.0")
                    .font(.caption)
                    .foregroundColor(.settingsSubheader)
                
                Text("Build 1")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Features Overview
            VStack(spacing: 16) {
                Text("Features")
                    .font(.headline)
                    .foregroundColor(.settingsHeader)
                
                VStack(spacing: 12) {
                    FeatureRow(icon: "figure.stand", title: "Stand + Focus", description: "Alternate between sitting and standing with structured focus sessions")
                    FeatureRow(icon: "figure.walk", title: "Move + Rest", description: "Take regular movement breaks with guided exercises")
                    FeatureRow(icon: "airpods", title: "Keep Posture", description: "Monitor your sitting posture using AirPods motion sensors")
                }
            }
            
            // Privacy Policy Link (Optional)
            VStack(spacing: 12) {
                Button("Privacy Policy") {
                    // This can link to App Store Connect privacy policy URL
                    // For now, we'll just show an alert or leave it as a placeholder
                }
                .buttonStyle(.borderless)
                .foregroundColor(.settingsAccentGreen)
            }
            
            // Copyright
            VStack(spacing: 4) {
                Text("© 2025 Standoro")
                    .font(.caption)
                    .foregroundColor(.settingsSubheader)
                
                Text("All rights reserved")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.settingsAccentGreen)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.settingsHeader)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.settingsSubheader)
            }
            
            Spacer()
        }
    }
}

#Preview {
    AboutView()
        .background(Color.settingsBackground)
} 