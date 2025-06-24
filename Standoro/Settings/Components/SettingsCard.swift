import SwiftUI

struct SettingsCard<Content: View>: View {
    let icon: String
    let header: String
    let subheader: String
    let iconColor: Color
    let content: Content
    let showDivider: Bool
    let trailing: AnyView?
    
    init(icon: String, header: String, subheader: String, iconColor: Color = .gray, showDivider: Bool = false, trailing: AnyView? = nil, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.header = header
        self.subheader = subheader
        self.iconColor = iconColor
        self.showDivider = showDivider
        self.trailing = trailing
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(iconColor)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(header)
                        .font(.headline)
                        .foregroundColor(.settingsHeader)
                    Text(subheader)
                        .font(.subheadline)
                        .foregroundColor(.settingsSubheader)
                }
                Spacer()
                if let trailing = trailing {
                    trailing
                }
            }
            if showDivider {
                Divider()
            }
            content
                .frame(alignment: .leading)
                .padding(.leading, 20)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.settingsCard))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.settingsCardBorder, lineWidth: 0.5)
        )
    }
}

struct SettingsCard_Previews: PreviewProvider {
    static var previews: some View {
        SettingsCard(icon: "gearshape", header: "General", subheader: "General app preferences.", iconColor: .settingsAccentGreen) {
            Toggle("Example Toggle", isOn: .constant(true))
        }
        .padding()
        .background(Color.settingsBackground)
    }
} 