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
                header: "Movement Challenges",
                subheader: "Take regular movement breaks with guided exercises and stretches to keep your body active and prevent stiffness.",
                iconColor: .settingsAccentGreen,
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
            
            // Audio Feedback Card - only show when Move Challenges are enabled
            if userPrefs.moveChallengesEnabledValue {
                SettingsCard(
                    icon: "speaker.wave.2",
                    header: "Challenge Audio Feedback",
                    subheader: "Enable sound effects for challenge events to provide audio feedback when challenges appear or are completed.",
                    iconColor: .settingsAccentGreen,
                    trailing: AnyView(
                        Toggle("", isOn: Binding(
                            get: { userPrefs.challengeAudioFeedbackEnabledValue },
                            set: { 
                                userPrefs.challengeAudioFeedbackEnabledValue = $0
                                try? ctx.save()
                            }
                        ))
                        .toggleStyle(CustomToggleStyle())
                    )
                ) {
                    if userPrefs.challengeAudioFeedbackEnabledValue && showExplanations {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Audio feedback includes:")
                                .font(.subheadline)
                                .foregroundColor(.settingsHeader)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("• Notification sound when a challenge appears")
                                    .font(.caption)
                                    .foregroundColor(.settingsSubheader)
                                Text("• Success sound when you complete a challenge")
                                    .font(.caption)
                                    .foregroundColor(.settingsSubheader)
                                Text("• Cancel sound when you discard a challenge")
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
}

#Preview {
    do {
        let container = try ModelContainer(for: UserPrefs.self)
        return MoveAndRestSettingsContentView(
            userPrefs: UserPrefs(),
            ctx: container.mainContext,
            showExplanations: true
        )
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
            .padding()
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
    }
} 