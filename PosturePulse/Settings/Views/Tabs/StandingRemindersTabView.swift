import SwiftUI
import SwiftData

struct StandingRemindersTabView: View {
    let userPrefs: UserPrefs
    let scheduler: Scheduler
    let ctx: ModelContext
    
    var body: some View {
        ScrollView {
            StandingRemindersContentView(
                userPrefs: userPrefs,
                scheduler: scheduler,
                ctx: ctx,
                showExplanations: false
            )
            .padding()
        }
    }
}

#Preview {
    StandingRemindersTabView(
        userPrefs: UserPrefs(),
        scheduler: Scheduler(),
        ctx: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext
    )
    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
} 