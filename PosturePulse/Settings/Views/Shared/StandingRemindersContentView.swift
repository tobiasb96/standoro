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
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Standing Goal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if showExplanations {
                    Text("How long would you like to stand for each session?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
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
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Maximum Sitting Time")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if showExplanations {
                    Text("How long can you sit before needing a break?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
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
    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
    .padding()
} 