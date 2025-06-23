import SwiftUI

struct TabButton: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void
    
    init(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack {
            TabButton(title: "General", icon: "gearshape", isSelected: true) { }
            TabButton(title: "Standing", icon: "figure.stand", isSelected: false) { }
            TabButton(title: "Posture", icon: "airpods", isSelected: false) { }
        }
        
        HStack {
            TabButton(title: "Intervals", isSelected: true) { }
            TabButton(title: "Permissions", isSelected: false) { }
            TabButton(title: "Posture", isSelected: false) { }
        }
    }
    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
    .padding()
} 