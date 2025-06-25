import SwiftUI
import SwiftData
import Combine

struct MenuBarView: View {
    @Environment(\.modelContext) private var ctx
    let userPrefs: UserPrefs
    let scheduler: Scheduler
    let motionService: MotionService
    let calendarService: CalendarService
    let statsService: StatsService
    
    @State private var showChallenge = false
    @State private var currentChallenge: Challenge?
    @State private var lastSessionType: String = ""
    @State private var lastPhase: String = ""
    @State private var audioService = AudioService()
    
    private var timeDisplay: String {
        let time = scheduler.timeRemaining
        if scheduler.pomodoroModeEnabled {
            return formatTime(time)
        } else {
            return formatTime(time)
        }
    }
    
    private var shouldShowPosture: Bool {
        return motionService.isMonitoring && 
               motionService.currentPosture != .unknown &&
               motionService.currentPosture != .good
    }
    
    private var postureEmoji: String {
        switch motionService.currentPosture {
        case .poor:
            return "⚠️"
        case .unknown:
            return ""
        case .good:
            return ""
        case .calibrating:
            return "🎯"
        case .noData:
            return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with current status
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentPhaseTitle)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(currentPhaseDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(timeDisplay)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if shouldShowPosture && !postureEmoji.isEmpty {
                            Text(postureEmoji)
                                .font(.title3)
                        }
                    }
                }
                
                // Progress bar
                ProgressView(value: progressValue, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                    .scaleEffect(y: 2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
            
            // Control buttons
            HStack(spacing: 16) {
                Button(action: {
                    if scheduler.isRunning {
                        scheduler.pause()
                    } else {
                        scheduler.resume()
                    }
                }) {
                    Image(systemName: playPauseIcon)
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    scheduler.stop()
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .disabled(!scheduler.isRunning)
                
                Button(action: {
                    scheduler.skip()
                }) {
                    Image(systemName: "forward.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .disabled(!scheduler.isRunning)
                
                Spacer()
                
                Button(action: {
                    showChallenge = true
                }) {
                    Image(systemName: "figure.walk.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
                .disabled(!userPrefs.moveChallengesEnabledValue)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            Divider()
            
            // Quick settings
            VStack(spacing: 8) {
                Button("Settings") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }
            .padding(.vertical, 8)
        }
        .frame(width: 300)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            setupInitialState()
            setupChallengeTriggers()
        }
        .onReceive(scheduler.$currentSessionType) { newValue in
            checkForChallengeTransition()
        }
        .onReceive(scheduler.$currentPhase) { newValue in
            checkForChallengeTransition()
        }
        .sheet(isPresented: $showChallenge) {
            if let challenge = currentChallenge {
                PopupChallengeCard(challenge: challenge) { completed in
                    handleChallengeResult(completed: completed)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentPhaseTitle: String {
        if scheduler.pomodoroModeEnabled {
            switch scheduler.currentSessionType {
            case .focus:
                return "Focus Session"
            case .shortBreak:
                return "Short Break"
            case .longBreak:
                return "Long Break"
            }
        } else {
            return scheduler.currentPhase == .sitting ? "Sitting" : "Standing"
        }
    }
    
    private var currentPhaseDescription: String {
        if scheduler.pomodoroModeEnabled {
            switch scheduler.currentSessionType {
            case .focus:
                return "Session \(scheduler.completedFocusSessions + 1)"
            case .shortBreak:
                return "Take a short break"
            case .longBreak:
                return "Take a longer break"
            }
        } else {
            return scheduler.currentPhase == .sitting ? "Time to sit" : "Time to stand"
        }
    }
    
    private var progressValue: Double {
        let total = scheduler.pomodoroModeEnabled ? 
            (scheduler.currentSessionType == .focus ? scheduler.focusInterval : 
             scheduler.currentSessionType == .shortBreak ? scheduler.shortBreakInterval : scheduler.longBreakInterval) :
            (scheduler.currentPhase == .sitting ? scheduler.sittingInterval : scheduler.standingInterval)
        
        let elapsed = total - scheduler.timeRemaining
        return max(0, min(1, elapsed / total))
    }
    
    private var progressColor: Color {
        if scheduler.pomodoroModeEnabled {
            switch scheduler.currentSessionType {
            case .focus:
                return .blue
            case .shortBreak, .longBreak:
                return .green
            }
        } else {
            return scheduler.currentPhase == .sitting ? .orange : .green
        }
    }
    
    private var playPauseIcon: String {
        return scheduler.isRunning && !scheduler.isPaused ? "pause.circle.fill" : "play.circle.fill"
    }
    
    // MARK: - Challenge System
    
    private func setupChallengeTriggers() {
        // Monitor for phase transitions
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                checkForChallengeTransition()
            }
            .store(in: &cancellables)
    }
    
    private func checkForChallengeTransition() {
        guard userPrefs.moveChallengesEnabledValue,
              !showChallenge else { return }
        
        // Check for Pomodoro break transitions
        if scheduler.pomodoroModeEnabled && 
           scheduler.currentSessionType != lastSessionType &&
           (scheduler.currentSessionType == .shortBreak || scheduler.currentSessionType == .longBreak) {
            
            showRandomChallenge()
        }
        
        // Check for sitting->standing transitions in simple mode
        if !scheduler.pomodoroModeEnabled && 
           scheduler.currentPhase != lastPhase &&
           scheduler.currentPhase == .standing {
            
            showRandomChallenge()
        }
        
        lastSessionType = scheduler.currentSessionType.rawValue
        lastPhase = scheduler.currentPhase.rawValue
    }
    
    private func showRandomChallenge() {
        guard !challenges.isEmpty else { return }
        
        currentChallenge = challenges.randomElement()
        
        if userPrefs.challengeAudioFeedbackEnabledValue {
            audioService.playSound(.challengeAppear)
        }
        
        showChallenge = true
    }
    
    private func handleChallengeResult(completed: Bool) {
        if completed {
            statsService.recordChallengeAction(completed: true)
            
            if userPrefs.challengeAudioFeedbackEnabledValue {
                audioService.playSound(.challengeComplete)
            }
        } else {
            statsService.recordChallengeAction(completed: false)
            
            if userPrefs.challengeAudioFeedbackEnabledValue {
                audioService.playSound(.challengeDiscard)
            }
        }
        
        currentChallenge = nil
        showChallenge = false
    }
    
    // MARK: - Initialization
    
    private func setupInitialState() {
        lastSessionType = scheduler.currentSessionType.rawValue
        lastPhase = scheduler.currentPhase.rawValue
    }
    
    // MARK: - Challenge Data
    
    private var challenges: [Challenge] {
        return [
            Challenge(
                title: "Standing Balance",
                instructions: "Stand on one leg for 30 seconds, then switch legs",
                duration: 60,
                category: .balance
            ),
            Challenge(
                title: "Wall Push-ups",
                instructions: "Do 10 wall push-ups with proper form",
                duration: 45,
                category: .strength
            ),
            Challenge(
                title: "Shoulder Stretches",
                instructions: "Roll your shoulders back 10 times, then forward 10 times",
                duration: 30,
                category: .flexibility
            ),
            Challenge(
                title: "Deep Breathing",
                instructions: "Take 5 deep breaths, inhaling for 4 counts and exhaling for 6",
                duration: 60,
                category: .mindfulness
            ),
            Challenge(
                title: "Mini Squats",
                instructions: "Do 10 mini squats, keeping your back straight",
                duration: 45,
                category: .strength
            ),
            Challenge(
                title: "Neck Stretches",
                instructions: "Gently tilt your head to each side and hold for 10 seconds",
                duration: 40,
                category: .flexibility
            )
        ]
    }
}

// MARK: - Supporting Types

struct Challenge {
    let title: String
    let instructions: String
    let duration: TimeInterval
    let category: ChallengeCategory
}

enum ChallengeCategory {
    case balance
    case strength
    case flexibility
    case cardio
    case mindfulness
}

// MARK: - Extensions

extension MenuBarView {
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Combine Support

extension MenuBarView {
    private var cancellables: Set<AnyCancellable> {
        get { Set<AnyCancellable>() }
        set { }
    }
} 
