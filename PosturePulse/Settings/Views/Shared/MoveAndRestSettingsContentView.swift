import SwiftUI
import SwiftData

struct MoveAndRestSettingsContentView: View {
    let userPrefs: UserPrefs
    let ctx: ModelContext
    let showExplanations: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Move Challenges Card
            SettingsCard(
                icon: "figure.walk",
                header: "Move Challenges",
                subheader: "Take regular movement breaks with guided exercises and stretches. These challenges help you stay active and prevent stiffness during long work sessions.",
                iconColor: .settingsAccentBlue,
                trailing: AnyView(
                    Toggle("", isOn: Binding(
                        get: { userPrefs.moveChallengesEnabledValue },
                        set: { 
                            userPrefs.moveChallengesEnabledValue = $0
                            try? ctx.save()
                        }
                    ))
                    .toggleStyle(CustomToggleStyle())
                )
            ) {
                if userPrefs.moveChallengesEnabledValue && showExplanations {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Move challenges will include:")
                            .font(.subheadline)
                            .foregroundColor(.settingsHeader)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Balance exercises (standing on one leg, tree pose)")
                                .font(.caption)
                                .foregroundColor(.settingsSubheader)
                            Text("• Strength training (squats, wall push-ups)")
                                .font(.caption)
                                .foregroundColor(.settingsSubheader)
                            Text("• Flexibility stretches (shoulder stretches, cat-cow)")
                                .font(.caption)
                                .foregroundColor(.settingsSubheader)
                            Text("• Cardio exercises (jumping jacks, high knees)")
                                .font(.caption)
                                .foregroundColor(.settingsSubheader)
                            Text("• Mindfulness practices (deep breathing, body scan)")
                                .font(.caption)
                                .foregroundColor(.settingsSubheader)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
}

#Preview {
    MoveAndRestSettingsContentView(
        userPrefs: UserPrefs(),
        ctx: try! ModelContainer(for: UserPrefs.self).mainContext,
        showExplanations: true
    )
    .padding()
    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
} 