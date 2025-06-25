import SwiftUI
import SwiftData

struct StandAndFocusSettingsContentView: View {
    let userPrefs: UserPrefs
    let scheduler: Scheduler
    let ctx: ModelContext
    let showExplanations: Bool
    
    init(userPrefs: UserPrefs, scheduler: Scheduler, ctx: ModelContext, showExplanations: Bool = false) {
        self.userPrefs = userPrefs
        self.scheduler = scheduler
        self.ctx = ctx
        self.showExplanations = showExplanations
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Work Mode Selection
            SettingsCard(
                icon: "timer",
                header: "Work Mode",
                subheader: "Choose between simple alternating phases or structured Pomodoro sessions to boost your productivity while staying active.",
                iconColor: .settingsAccentGreen,
            ) {
                VStack(spacing: 12) {
                    HStack {
                        Button(action: {
                            userPrefs.pomodoroModeEnabledValue = false
                            scheduler.setPomodoroMode(false)
                            try? ctx.save()
                        }) {
                            HStack {
                                Image(systemName: "figure.stand")
                                    .font(.system(size: 15))
                                Text("Simple Mode")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(userPrefs.pomodoroModeEnabledValue ? .settingsSubheader : .settingsAccentGreen)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(userPrefs.pomodoroModeEnabledValue ? Color.clear : Color.settingsAccentGreen.opacity(0.2))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            userPrefs.pomodoroModeEnabledValue = true
                            scheduler.setPomodoroMode(true)
                            try? ctx.save()
                        }) {
                            HStack {
                                Image(systemName: "timer")
                                    .font(.system(size: 15))
                                Text("Pomodoro Mode")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(userPrefs.pomodoroModeEnabledValue ? .settingsAccentGreen : .settingsSubheader)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(userPrefs.pomodoroModeEnabledValue ? Color.settingsAccentGreen.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                    }
                    
                    if showExplanations {
                        Text(userPrefs.pomodoroModeEnabledValue ? 
                             "Pomodoro mode uses structured work sessions with regular breaks to improve focus and productivity. Each session includes focused work time followed by short and long breaks." :
                             "Simple mode alternates between sitting and standing to promote healthy movement throughout your day. This straightforward approach helps reduce sedentary time and keeps you active.")
                            .font(.system(size: 12))
                            .foregroundColor(.settingsSubheader)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            if userPrefs.pomodoroModeEnabledValue {
                // Pomodoro Settings
                pomodoroSettings
            } else {
                // Posture Timer Settings
                postureTimerSettings
            }
        }
    }
    
    @ViewBuilder
    private var pomodoroSettings: some View {
        VStack(spacing: 16) {
            // Focus Interval
            SettingsCard(
                icon: "brain.head.profile",
                header: "Focus Interval",
                subheader: "How long should each focused work session be? Longer sessions allow for deeper work, while shorter sessions help maintain concentration.",
                iconColor: .settingsAccentGreen,
                showDivider: true
            ) {
                IntervalSliderView(
                    label: "Minutes",
                    value: Binding(
                        get: { userPrefs.focusIntervalMinutesValue },
                        set: { 
                            userPrefs.focusIntervalMinutesValue = $0
                            scheduler.focusInterval = TimeInterval($0 * 60)
                            try? ctx.save()
                        }
                    ),
                    range: 5...90,
                    unit: "min",
                    quickOptions: [20, 25, 30, 45],
                    context: ctx
                )
            }
            
            // Short Break
            SettingsCard(
                icon: "cup.and.saucer",
                header: "Short Break",
                subheader: "How long should short breaks be? Use this time to stand up, stretch, or take a quick walk to refresh your mind and body.",
                iconColor: .settingsAccentGreen,
                showDivider: true
            ) {
                IntervalSliderView(
                    label: "Minutes",
                    value: Binding(
                        get: { userPrefs.shortBreakMinutesValue },
                        set: { 
                            userPrefs.shortBreakMinutesValue = $0
                            scheduler.shortBreakInterval = TimeInterval($0 * 60)
                            try? ctx.save()
                        }
                    ),
                    range: 3...30,
                    unit: "min",
                    quickOptions: [3, 5, 7, 10],
                    context: ctx
                )
            }
            
            // Long Break
            SettingsCard(
                icon: "bed.double",
                header: "Long Break",
                subheader: "How long should long breaks be? Longer breaks allow for more substantial rest and recovery between focus sessions.",
                iconColor: .settingsAccentGreen,
                showDivider: true
            ) {
                IntervalSliderView(
                    label: "Minutes",
                    value: Binding(
                        get: { userPrefs.longBreakMinutesValue },
                        set: { 
                            userPrefs.longBreakMinutesValue = $0
                            scheduler.longBreakInterval = TimeInterval($0 * 60)
                            try? ctx.save()
                        }
                    ),
                    range: 5...60,
                    unit: "min",
                    quickOptions: [10, 15, 20, 30],
                    context: ctx
                )
            }
            
            // Intervals Before Long Break
            SettingsCard(
                icon: "number.circle",
                header: "Long Break Frequency",
                subheader: "How many focus sessions before a long break? This helps maintain a sustainable rhythm of work and rest.",
                iconColor: .settingsAccentGreen,
                showDivider: true
            ) {
                IntervalSliderView(
                    label: "Sessions",
                    value: Binding(
                        get: { userPrefs.intervalsBeforeLongBreakValue },
                        set: { 
                            userPrefs.intervalsBeforeLongBreakValue = $0
                            scheduler.intervalsBeforeLongBreak = $0
                            try? ctx.save()
                        }
                    ),
                    range: 2...8,
                    unit: "sessions",
                    quickOptions: [3, 4, 5, 6],
                    context: ctx
                )
            }
        }
    }
    
    @ViewBuilder
    private var postureTimerSettings: some View {
        VStack(spacing: 16) {
            // Standing Goal
            SettingsCard(
                icon: "figure.stand",
                header: "Standing Goal",
                subheader: "How long would you like to stand for each session? Standing helps improve circulation, reduce back pain, and increase energy levels.",
                iconColor: .settingsAccentGreen,
                showDivider: true
            ) {
                IntervalSliderView(
                    label: "Minutes",
                    value: Binding(
                        get: { userPrefs.maxStandMinutes },
                        set: { 
                            userPrefs.maxStandMinutes = $0
                            scheduler.standingInterval = TimeInterval($0 * 60)
                            try? ctx.save()
                        }
                    ),
                    range: 5...60,
                    unit: "min",
                    quickOptions: [5, 10, 15, 20],
                    context: ctx
                )
            }
            
            // Maximum Sitting Time
            SettingsCard(
                icon: "chair",
                header: "Maximum Sitting Time",
                subheader: "How long can you sit before needing a break? Regular movement helps prevent stiffness and maintains your energy throughout the day.",
                iconColor: .settingsAccentGreen,
                showDivider: true
            ) {
                IntervalSliderView(
                    label: "Minutes",
                    value: Binding(
                        get: { userPrefs.maxSitMinutes },
                        set: { 
                            userPrefs.maxSitMinutes = $0
                            scheduler.sittingInterval = TimeInterval($0 * 60)
                            try? ctx.save()
                        }
                    ),
                    range: 15...120,
                    unit: "min",
                    quickOptions: [25, 45, 60, 90],
                    context: ctx
                )
            }
        }
    }
}

#Preview {
    do {
        let container1 = try ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let container2 = try ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        return VStack(spacing: 20) {
            StandAndFocusSettingsContentView(
                userPrefs: UserPrefs(),
                scheduler: Scheduler(),
                ctx: container1.mainContext,
                showExplanations: true
            )
            
            StandAndFocusSettingsContentView(
                userPrefs: UserPrefs(pomodoroModeEnabled: true),
                scheduler: Scheduler(),
                ctx: container2.mainContext,
                showExplanations: false
            )
        }
        .background(Color.settingsBackground)
        .padding()
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
            .background(Color.settingsBackground)
            .padding()
    }
} 