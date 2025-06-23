import SwiftUI
import SwiftData

struct GeneralTabView: View {
    let userPrefs: UserPrefs
    let calendarService: CalendarService
    let scheduler: Scheduler
    let ctx: ModelContext
    
    var body: some View {
        ScrollView {
            GeneralSettingsContentView(
                userPrefs: userPrefs,
                calendarService: calendarService,
                scheduler: scheduler,
                ctx: ctx,
                showExplanations: false
            )
            .padding()
        }
    }
}

#Preview {
    GeneralTabView(
        userPrefs: UserPrefs(),
        calendarService: CalendarService(),
        scheduler: Scheduler(),
        ctx: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext
    )
    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
} 