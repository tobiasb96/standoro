import SwiftUI

struct SidebarView: View {
    @Binding var selection: SettingsView.SidebarItem?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.settingsSidebar.ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    sidebarButton(item: .stats, label: "Stats", icon: "chart.bar.xaxis")
                    sidebarButton(item: .general, label: "General", icon: "gearshape")
                    sidebarButton(item: .standing, label: "Standing", icon: "figure.stand")
                    sidebarButton(item: .posture, label: "Posture", icon: "airpods")
                }
                .padding(.top, 24)
                .padding(.horizontal, 8)
                Spacer()
                Divider().background(Color.settingsSidebarDivider)
                VStack {
                    sidebarButton(item: .about, label: "About", icon: "info.circle")
                }
                .padding(.vertical, 12)
            }
        }
    }
    
    @ViewBuilder
    private func sidebarButton(item: SettingsView.SidebarItem, label: String, icon: String) -> some View {
        Button(action: { selection = item }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(item == selection ? .settingsAccentBlue : .settingsText)
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(item == selection ? .settingsAccentBlue : .settingsText)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(item == selection ? Color.settingsCard.opacity(0.7) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 