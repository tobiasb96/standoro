import SwiftUI
import SwiftData
import Combine

struct PostureTabView: View {
    let userPrefs: UserPrefs
    let motionService: MotionService
    let ctx: ModelContext
    
    var body: some View {
        ScrollView {
            PostureSettingsContentView(
                userPrefs: userPrefs,
                motionService: motionService,
                ctx: ctx,
                showExplanations: false
            )
            .padding()
        }
    }
}

#Preview {
    PostureTabView(
        userPrefs: UserPrefs(),
        motionService: MotionService(),
        ctx: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext
    )
    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
} 