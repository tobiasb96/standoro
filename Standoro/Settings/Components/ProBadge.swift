import SwiftUI

struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .foregroundColor(.white)
            .background(Color.settingsAccentGreen)
            .cornerRadius(3)
    }
}

#Preview {
    ProBadge()
} 