import SwiftUI
import SwiftData

struct FocusSettingsContentView: View {
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
            // Timer Mode Selection
            SettingsCard(
                icon: "timer",
                header: "Timer Mode",
                subheader: "Choose between simple posture reminders or structured Pomodoro sessions.",
                iconColor: .settingsAccentBlue,
                showDivider: true
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
                                    .font(.system(size: 16))
                                Text("Posture Timer")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(userPrefs.pomodoroModeEnabledValue ? .settingsSubheader : .settingsAccentBlue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(userPrefs.pomodoroModeEnabledValue ? Color.clear : Color.settingsAccentBlue.opacity(0.2))
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
                                    .font(.system(size: 16))
                                Text("Pomodoro Timer")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(userPrefs.pomodoroModeEnabledValue ? .settingsAccentBlue : .settingsSubheader)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(userPrefs.pomodoroModeEnabledValue ? Color.settingsAccentBlue.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                    }
                    
                    if showExplanations {
                        Text(userPrefs.pomodoroModeEnabledValue ? 
                             "Pomodoro mode uses structured work sessions with regular breaks to improve focus and productivity." :
                             "Posture timer alternates between sitting and standing to promote healthy movement throughout your day.")
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
                subheader: "How long should each focus session be?",
                iconColor: .settingsAccentBlue,
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
                subheader: "How long should short breaks be?",
                iconColor: .settingsAccentBlue,
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
                subheader: "How long should long breaks be?",
                iconColor: .settingsAccentBlue,
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
                subheader: "How many focus sessions before a long break?",
                iconColor: .settingsAccentBlue,
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
                subheader: "How long would you like to stand for each session?",
                iconColor: .settingsAccentBlue,
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
                subheader: "How long can you sit before needing a break?",
                iconColor: .settingsAccentBlue,
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
    VStack(spacing: 20) {
        FocusSettingsContentView(
            userPrefs: UserPrefs(),
            scheduler: Scheduler(),
            ctx: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext,
            showExplanations: true
        )
        
        FocusSettingsContentView(
            userPrefs: UserPrefs(pomodoroModeEnabled: true),
            scheduler: Scheduler(),
            ctx: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext,
            showExplanations: false
        )
    }
    .background(Color.settingsBackground)
    .padding()
} 