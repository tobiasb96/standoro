import SwiftUI

struct SidebarView: View {
    @Binding var selection: SettingsView.SidebarItem?
    let isProUnlocked: Bool
    @State private var hoveredItem: SettingsView.SidebarItem?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.settingsSidebar.ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    sidebarButton(item: .stats, label: "Stats", icon: "chart.bar.xaxis")
                    Text("Features")
                        .font(.system(size: 12))
                        .foregroundColor(.settingsSubheader)
                        .padding(.top, 18)
                        .padding(.bottom, 2)
                        .padding(.leading, 4)
                    sidebarButton(item: .standAndFocus, label: "Stand + Focus", icon: "figure.stand")
                    sidebarButton(item: .moveAndRest, label: "Move + Rest", icon: "figure.walk")
                    sidebarButton(item: .keepPosture, label: "Keep Posture", icon: "airpods")
                    Text("Settings")
                        .font(.system(size: 12))
                        .foregroundColor(.settingsSubheader)
                        .padding(.top, 18)
                        .padding(.bottom, 2)
                        .padding(.leading, 4)
                    sidebarButton(item: .general, label: "General", icon: "gearshape")
                    if !isProUnlocked {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade")
                                .font(.system(size: 12))
                                .foregroundColor(.settingsSubheader)
                                .padding(.top, 18)
                                .padding(.bottom, 2)
                                .padding(.leading, 4)
                            sidebarButton(item: .upgrade, label: "Get Pro", icon: "star.fill")
                        }
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 8)
                Spacer()
                VStack {
                    Button(action: { selection = .about }) {
                        Text("About")
                            .font(.system(size: 13))
                            .foregroundColor(.settingsSubheader)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
            }
        }
    }
    
    @ViewBuilder
    private func sidebarButton(item: SettingsView.SidebarItem, label: String, icon: String) -> some View {
        Button(action: { selection = item }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(item == selection ? .settingsAccentGreen : .settingsText)
                    .frame(width: 22, alignment: .center)
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(item == selection ? .settingsAccentGreen : .settingsText)
                    .frame(alignment: .leading)
                Spacer()
                if item == .stats && !isProUnlocked {
                    ProBadge()
                }
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 8)
            .background(
                Group {
                    if item == selection {
                        Color.settingsCard.opacity(0.7)
                    } else if hoveredItem == item {
                        Color.settingsCard.opacity(0.3)
                    } else {
                        Color.clear
                    }
                }
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered in
            hoveredItem = isHovered ? item : nil
        }
    }
} 