import SwiftUI

struct SensitivityButton: View {
    let title: String
    let degrees: Double
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(Int(degrees))°")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color(red: 0.4, green: 0.6, blue: 0.4) : Color(red: 0.16, green: 0.16, blue: 0.18))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .white : .secondary)
    }
}

#Preview {
    HStack {
        SensitivityButton(title: "Low", degrees: 20.0, isSelected: false) { }
        SensitivityButton(title: "Medium", degrees: 14.0, isSelected: true) { }
        SensitivityButton(title: "High", degrees: 8.0, isSelected: false) { }
    }
    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
    .padding()
} 