import SwiftUI
import SwiftData

struct GeneralSettingsContentView: View {
    let userPrefs: UserPrefs
    let calendarService: CalendarService
    let scheduler: Scheduler
    let ctx: ModelContext
    let showExplanations: Bool
    
    init(userPrefs: UserPrefs, calendarService: CalendarService, scheduler: Scheduler, ctx: ModelContext, showExplanations: Bool = false) {
        self.userPrefs = userPrefs
        self.calendarService = calendarService
        self.scheduler = scheduler
        self.ctx = ctx
        self.showExplanations = showExplanations
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Menu Bar Card
            SettingsCard(
                icon: "menubar.rectangle",
                header: "Menu Bar Timer",
                subheader: "Show the countdown timer in your menu bar for quick access to your current session status and remaining time.",
                iconColor: .settingsAccentGreen,
                trailing: AnyView(
                    Toggle("", isOn: Binding(
                        get: { userPrefs.showMenuBarCountdown },
                        set: { userPrefs.showMenuBarCountdown = $0; try? ctx.save() }
                    ))
                    .toggleStyle(CustomToggleStyle())
                )
            ) {
                EmptyView()
            }
            
            // Auto-Start Card
            SettingsCard(
                icon: "play.circle",
                header: "Auto-Start Sessions",
                subheader: "Automatically continue to the next phase when a session ends. When disabled, you'll need to manually start each phase, giving you more control over your workflow.",
                iconColor: .settingsAccentGreen,
                trailing: AnyView(
                    Toggle("", isOn: Binding(
                        get: { userPrefs.autoStartEnabledValue },
                        set: { 
                            userPrefs.autoStartEnabledValue = $0
                            try? ctx.save()
                        }
                    ))
                    .toggleStyle(CustomToggleStyle())
                )
            ) {
                EmptyView()
            }
            
            // Calendar Integration Card
            SettingsCard(
                icon: "calendar",
                header: "Calendar Integration",
                subheader: "Automatically mute alerts when you're in calendar meetings to avoid interruptions during important calls and presentations.",
                iconColor: .settingsAccentGreen,
                showDivider: userPrefs.calendarFilter,
                trailing: AnyView(
                    Toggle("", isOn: Binding(
                        get: { userPrefs.calendarFilter },
                        set: { newValue in
                            userPrefs.calendarFilter = newValue
                            try? ctx.save()
                            scheduler.setCalendarService(calendarService, shouldCheck: newValue)
                            if newValue && !calendarService.isAuthorized {
                                Task { await requestCalendarAccess() }
                            }
                        }
                    ))
                    .toggleStyle(CustomToggleStyle())
                )
            ) {
                if userPrefs.calendarFilter {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: calendarService.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(calendarService.isAuthorized ? .green : .orange)
                                .font(.caption)
                            Text(calendarService.isAuthorized ? "Calendar access granted" : "Calendar access required")
                                .font(.caption)
                                .foregroundColor(.settingsSubheader)
                            if !calendarService.isAuthorized {
                                Button("Grant Access") {
                                    Task { await requestCalendarAccess() }
                                }
                                .buttonStyle(.borderless)
                                .font(.caption)
                                .foregroundColor(.settingsAccentGreen)
                            }
                        }
                        if let errorMessage = calendarService.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 20)
                        }
                        if calendarService.isAuthorized {
                            HStack {
                                Image(systemName: calendarService.isInMeeting ? "bell.slash.fill" : "bell.fill")
                                    .foregroundColor(calendarService.isInMeeting ? .orange : .green)
                                    .font(.caption)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(calendarService.isInMeeting ? "Currently in a meeting - notifications muted" : "No current meetings - notifications active")
                                        .font(.caption)
                                        .foregroundColor(.settingsSubheader)
                                    if calendarService.isInMeeting, let eventDetails = calendarService.getCurrentEventDetails() {
                                        Text("Event: \"\(eventDetails.title)\"")
                                            .font(.caption)
                                            .foregroundColor(.settingsText)
                                            .fontWeight(.medium)
                                        Text("Ends at: \(eventDetails.endTime)")
                                            .font(.caption)
                                            .foregroundColor(.settingsSubheader)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            #if DEBUG
            SettingsCard(
                icon: "hammer",
                header: "Development",
                subheader: "Debug and development tools for testing and troubleshooting.",
                iconColor: .gray,
                trailing: AnyView(
                    Button("Reset Onboarding") {
                        UserDefaults.standard.set(false, forKey: "didOnboard")
                        NotificationCenter.default.post(name: NSNotification.Name("ResetOnboarding"), object: nil)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.orange)
                )
            ) {
                EmptyView()
            }
            #endif
        }
    }
    
    private func requestCalendarAccess() async {
        _ = await calendarService.requestAccess()
    }
}

#Preview {
    VStack(spacing: 20) {
        GeneralSettingsContentView(
            userPrefs: UserPrefs(),
            calendarService: CalendarService(),
            scheduler: Scheduler(),
            ctx: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext,
            showExplanations: true
        )
        
        GeneralSettingsContentView(
            userPrefs: UserPrefs(),
            calendarService: CalendarService(),
            scheduler: Scheduler(),
            ctx: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext,
            showExplanations: false
        )
    }
    .background(Color.settingsBackground)
    .padding()
} 