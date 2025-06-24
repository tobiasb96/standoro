import SwiftUI

struct AsyncPermissionCard: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isGranted: Bool
    let onRequest: () async -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isGranted ? .green : .orange)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else {
                Button("Grant") {
                    Task {
                        await onRequest()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(16)
        .background(Color(red: 0.16, green: 0.16, blue: 0.18))
        .cornerRadius(12)
    }
}

#Preview {
    AsyncPermissionCard(
        title: "Motion Access",
        description: "Access AirPods motion data for posture detection",
        icon: "figure.stand",
        isGranted: .constant(false),
        onRequest: { }
    )
    .background(Color(red: 0.0, green: 0.2, blue: 0.6))
    .padding()
} 