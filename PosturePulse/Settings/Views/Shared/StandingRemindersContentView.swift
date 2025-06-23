import SwiftUI
import SwiftData

struct StandingRemindersContentView: View {
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
        VStack(alignment: .leading, spacing: 20) {
            SettingsCard(
                icon: "figure.stand",
                header: "Standing Goal",
                subheader: "How long would you like to stand for each session?",
                iconColor: .settingsAccentBlue,
                showDivider: true
            ) {
                IntervalSliderView(
                    label: "Minutes",
                    minutes: Binding(
                        get: { userPrefs.maxStandMinutes },
                        set: { 
                            userPrefs.maxStandMinutes = $0
                            scheduler.standingInterval = TimeInterval($0 * 60)
                            try? ctx.save()
                        }
                    ),
                    quickOptions: [5, 10, 15, 20],
                    context: ctx
                )
            }
            SettingsCard(
                icon: "chair",
                header: "Maximum Sitting Time",
                subheader: "How long can you sit before needing a break?",
                iconColor: .settingsAccentBlue,
                showDivider: true
            ) {
                IntervalSliderView(
                    label: "Minutes",
                    minutes: Binding(
                        get: { userPrefs.maxSitMinutes },
                        set: { 
                            userPrefs.maxSitMinutes = $0
                            scheduler.sittingInterval = TimeInterval($0 * 60)
                            try? ctx.save()
                        }
                    ),
                    quickOptions: [25, 45, 60, 90],
                    context: ctx
                )
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StandingRemindersContentView(
            userPrefs: UserPrefs(),
            scheduler: Scheduler(),
            ctx: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext,
            showExplanations: true
        )
        
        StandingRemindersContentView(
            userPrefs: UserPrefs(),
            scheduler: Scheduler(),
            ctx: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext,
            showExplanations: false
        )
    }
    .background(Color.settingsBackground)
    .padding()
} 