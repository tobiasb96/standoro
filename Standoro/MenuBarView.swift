import SwiftUI
import SwiftData
import Combine

struct MenuBarView: View {
    @Environment(\.modelContext) private var ctx
    let userPrefs: UserPrefs
    @ObservedObject var scheduler: Scheduler
    @ObservedObject var motionService: MotionService
    @ObservedObject var calendarService: CalendarService
    @ObservedObject var statsService: StatsService
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    @State private var updateCounter = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @StateObject private var audioService = AudioService()

    // Challenge state
    @State private var currentChallenge: Challenge?
    @State private var showChallenge: Bool = false
    @State private var lastPhaseTransition: Date = Date()
    @State private var lastSessionType: SessionType = .focus
    @State private var lastPhase: PosturePhase = .sitting
    
    private var displayTime: TimeInterval {
        if scheduler.isRunning {
            let _ = updateCounter
            // Use the scheduler's currentRemainingTime which handles pause state correctly
            return scheduler.currentRemainingTime
        } else {
            // When not running, show the current setting from preferences
            if scheduler.pomodoroModeEnabled {
                let time = TimeInterval(userPrefs.focusIntervalMinutesValue * 60)
                return time
            } else {
                let time = TimeInterval(userPrefs.maxSitMinutes * 60)
                return time
            }
        }
    }
    
    private var phaseText: String {
        if scheduler.isRunning {
            if scheduler.pomodoroModeEnabled {
                switch scheduler.currentSessionType {
                case .focus:
                    return "Focus"
                case .shortBreak:
                    return "Short Break"
                case .longBreak:
                    return "Long Break"
                }
            } else {
                switch scheduler.currentPhase {
                case .sitting:
                    return "Sitting"
                case .standing:
                    return "Standing"
                }
            }
        } else {
            // When not running, show based on current settings
            if userPrefs.pomodoroModeEnabledValue {
                return "Focus"
            } else {
                return "Sitting"
            }
        }
    }

    private var phaseIcon: String {
        if scheduler.isRunning {
            if scheduler.pomodoroModeEnabled {
                switch scheduler.currentSessionType {
                case .focus:
                    return scheduler.currentPhase == .sitting ? "chair" : "figure.stand"
                case .shortBreak:
                    return "cup.and.saucer"
                case .longBreak:
                    return "bed.double"
                }
            } else {
                switch scheduler.currentPhase {
                case .sitting:
                    return "chair"
                case .standing:
                    return "figure.stand"
                }
            }
        } else {
            // When not running, show based on current settings
            if userPrefs.pomodoroModeEnabledValue {
                return "chair" // Focus sessions typically start with sitting
            } else {
                return "chair"
            }
        }
    }

    private var phaseBackgroundColor: Color {
        if !scheduler.isRunning {
            // When not running, show based on current settings
            if userPrefs.pomodoroModeEnabledValue {
                return Color.settingsAccentGreen.opacity(0.3) // Focus session color - muted green
            } else {
                return Color.gray.opacity(0.3)
            }
        } else if scheduler.isPaused {
            return Color.gray.opacity(0.3) // Gray for pause
        } else {
            if scheduler.pomodoroModeEnabled {
                switch scheduler.currentSessionType {
                case .focus:
                    return Color.settingsAccentGreen.opacity(0.3) // Green for focus
                case .shortBreak, .longBreak:
                    return Color(red: 0.7, green: 0.3, blue: 0.3).opacity(0.3) // Muted red for breaks
                }
            } else {
                return Color.settingsAccentGreen.opacity(0.3) // Green for focus
            }
        }
    }

    private var phaseIconColor: Color {
        if !scheduler.isRunning {
            // When not running, show based on current settings
            if userPrefs.pomodoroModeEnabledValue {
                return Color.settingsAccentGreen // Focus session color - muted green
            } else {
                return Color.gray
            }
        } else if scheduler.isPaused {
            return Color.gray // Gray for pause
        } else {
            if scheduler.pomodoroModeEnabled {
                switch scheduler.currentSessionType {
                case .focus:
                    return Color.settingsAccentGreen // Green for focus
                case .shortBreak, .longBreak:
                    return Color(red: 0.7, green: 0.3, blue: 0.3) // Muted red for breaks
                }
            } else {
                return Color.settingsAccentGreen // Green for focus
            }
        }
    }

    private var playPauseIcon: String {
        return scheduler.isRunning && !scheduler.isPaused ? "pause.circle.fill" : "play.circle.fill"
    }
    
    private var playPauseTooltip: String {
        if !scheduler.isRunning {
            return "Start timer"
        } else if scheduler.isPaused {
            return "Resume timer"
        } else {
            return "Pause timer"
        }
    }
    
    private var shouldShowCalendarMute: Bool {
        return userPrefs.calendarFilter && calendarService.isAuthorized && calendarService.isInMeeting
    }

    private var calendarMuteTooltip: String {
        if let eventDetails = calendarService.getCurrentEventDetails() {
            return "Notifications paused until \(eventDetails.endTime) after your event \"\(eventDetails.title)\""
        } else {
            return "Notifications muted - you're currently in a meeting"
        }
    }

    private var sessionProgressText: String? {
        guard userPrefs.pomodoroModeEnabledValue else { return nil }
        
        if scheduler.isRunning {
            switch scheduler.currentSessionType {
            case .focus:
                let completed = scheduler.completedFocusSessions
                let total = scheduler.intervalsBeforeLongBreak
                let currentSession = (completed % total) + 1
                return "Session \(currentSession) of \(total)"
            case .shortBreak:
                let completed = scheduler.completedFocusSessions
                let total = scheduler.intervalsBeforeLongBreak
                let currentSession = (completed % total)
                return "Break after session \(currentSession) of \(total)"
            case .longBreak:
                let completed = scheduler.completedFocusSessions
                let total = scheduler.intervalsBeforeLongBreak
                let completedSessions = completed - (completed % total)
                return "Long break after \(completedSessions) sessions"
            }
        } else {
            // When not running, show "Session 1 of X" for the first session
            let total = userPrefs.intervalsBeforeLongBreakValue
            return "Session 1 of \(total)"
        }
    }

    private var sessionProgressColor: Color {
        guard userPrefs.pomodoroModeEnabledValue else { return .clear }
        
        if scheduler.isRunning {
            switch scheduler.currentSessionType {
            case .focus:
                return Color.settingsAccentGreen.opacity(0.2) // Green for focus
            case .shortBreak:
                return Color(red: 0.7, green: 0.3, blue: 0.3).opacity(0.2) // Muted red for breaks
            case .longBreak:
                return Color(red: 0.7, green: 0.3, blue: 0.3).opacity(0.2) // Muted red for breaks
            }
        } else {
            // When not running, show focus session color
            return Color.settingsAccentGreen.opacity(0.2) // Green for focus
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with posture indicator and calendar mute
            HStack {
                // Posture indicator in top left
                if userPrefs.postureMonitoringEnabledValue {
                    postureIndicator
                }

                Spacer()
                
                // Calendar mute indicator in top right
                if shouldShowCalendarMute {
                    Image(systemName: "bell.slash.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                        .help(calendarMuteTooltip)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Main content area
            VStack {
                Spacer(minLength: 20)

                // Phase indicator with icon (no background)
                HStack(spacing: 12) {
                    Image(systemName: phaseIcon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(phaseIconColor)
                    
                    Text(phaseText)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }

                // Session progress indicator for Pomodoro mode
                if let progressText = sessionProgressText {
                    Text(progressText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 2)
                }

                Text(formatTime(displayTime))
                    .font(.system(size: 64, weight: .light, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.top, 8)

                HStack(spacing: 40) {
                    Button(action: handleRestart) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20))
                            .foregroundColor(scheduler.isRunning ? .white : .gray)
                    }
                    .buttonStyle(.plain)
                    .disabled(!scheduler.isRunning)
                    .help("Restart timer")

                    Button(action: handlePlayPause) {
                        Image(systemName: playPauseIcon)
                            .font(.system(size: 40, weight: .thin))
                            .foregroundColor(scheduler.isRunning && scheduler.isPaused ? .gray : .white)
                    }
                    .buttonStyle(.plain)
                    .help(playPauseTooltip)
                    
                    Button(action: handleSkipPhase) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 20))
                            .foregroundColor(scheduler.isRunning ? .white : .gray)
                    }
                    .buttonStyle(.plain)
                    .disabled(!scheduler.isRunning)
                    .help("Skip to next phase")
                }

                Spacer(minLength: 20)
            }

            // Bottom toolbar with smaller, monochrome buttons
            HStack {
                Button(action: openStats) {
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundColor(.white.opacity(0.7))
                }.buttonStyle(.plain)
                .help("View statistics")

                Spacer()

                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.white.opacity(0.7))
                }.buttonStyle(.plain)
                .help("Open settings")

                Spacer()

                Button(action: onQuit) {
                    Image(systemName: "power")
                        .foregroundColor(.white.opacity(0.7))
                }.buttonStyle(.plain)
                .help("Quit application")
            }
            .font(.system(size: 16))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.2))
        }
        .frame(width: 300, height: 300)
        .background(phaseBackgroundColor)
        .foregroundColor(.white)
        .overlay(
            // Challenge overlay as a proper popup
            Group {
                if showChallenge, let challenge = currentChallenge {
                    ZStack {
                        // Semi-transparent backdrop
                        Color.black.opacity(0.7)
                        
                        // Challenge content
                        VStack(spacing: 16) {
                            Text("Time for a Challenge!")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.top, 8)
                            
                            PopupChallengeCard(
                                challenge: challenge,
                                onComplete: completeChallenge,
                                onDiscard: discardChallenge
                            )
                            .padding(.horizontal, 16)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                }
            }
        )
        .onAppear(perform: setupInitialState)
        .onReceive(timer) { _ in
            // Force UI update every second when popup is open
            // This ensures posture emoji and other UI elements update regularly
            updateCounter += 1
            
            // Check for phase transitions to show challenges
            checkForChallengeOpportunity()
        }
        .onChange(of: userPrefs.pomodoroModeEnabledValue) { _, newValue in
            scheduler.sittingInterval = TimeInterval(userPrefs.maxSitMinutes * 60)
            scheduler.standingInterval = TimeInterval(userPrefs.maxStandMinutes * 60)
            
            // Update Pomodoro settings
            scheduler.setPomodoroMode(userPrefs.pomodoroModeEnabledValue)
            scheduler.focusInterval = TimeInterval(userPrefs.focusIntervalMinutesValue * 60)
            scheduler.shortBreakInterval = TimeInterval(userPrefs.shortBreakMinutesValue * 60)
            scheduler.longBreakInterval = TimeInterval(userPrefs.longBreakMinutesValue * 60)
            scheduler.intervalsBeforeLongBreak = userPrefs.intervalsBeforeLongBreakValue

            // Update auto-start setting
            scheduler.setAutoStartEnabled(userPrefs.autoStartEnabledValue)

            // Update motion service settings (but don't start/stop monitoring)
            if userPrefs.postureMonitoringEnabledValue {
                motionService.setPostureThresholds(pitch: userPrefs.postureSensitivityDegreesValue, roll: userPrefs.postureSensitivityDegreesValue, duration: TimeInterval(userPrefs.poorPostureThresholdSecondsValue))
            }
            
            // Update calendar service integration
            scheduler.setCalendarService(calendarService, shouldCheck: userPrefs.calendarFilter)
            motionService.setCalendarService(calendarService, shouldCheck: userPrefs.calendarFilter)
            
            // Force UI update to reflect the new setting
            updateCounter += 1
        }
        .onChange(of: userPrefs.focusIntervalMinutesValue) { _, _ in
            scheduler.focusInterval = TimeInterval(userPrefs.focusIntervalMinutesValue * 60)
            updateCounter += 1
        }
        .onChange(of: userPrefs.maxSitMinutes) { _, _ in
            scheduler.sittingInterval = TimeInterval(userPrefs.maxSitMinutes * 60)
            updateCounter += 1
        }
        .onChange(of: userPrefs.maxStandMinutes) { _, _ in
            scheduler.standingInterval = TimeInterval(userPrefs.maxStandMinutes * 60)
            updateCounter += 1
        }
        .onChange(of: userPrefs.postureNudgesEnabledValue) { _, newValue in
            scheduler.setPostureNudgesEnabled(newValue)
            updateCounter += 1
        }
        .onAppear {
            // Enable high frequency mode when popup is opened
            if userPrefs.postureMonitoringEnabledValue && motionService.isAuthorized {
                motionService.enablePostureHighFrequencyMode()
            }
            
            // Set up calendar service integration
            scheduler.setCalendarService(calendarService, shouldCheck: userPrefs.calendarFilter)
            motionService.setCalendarService(calendarService, shouldCheck: userPrefs.calendarFilter)
            scheduler.setAutoStartEnabled(userPrefs.autoStartEnabledValue)
        }
        .onDisappear {
            // Disable high frequency mode when popup is closed
            if userPrefs.postureMonitoringEnabledValue && motionService.isAuthorized {
                motionService.disablePostureHighFrequencyMode()
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
    
    private var shouldShowPosture: Bool {
        return motionService.isMonitoring && 
               motionService.currentPosture != .unknown &&
               motionService.currentPosture != .good
    }
    
    private var postureEmoji: String {
        // Check device status first
        if !motionService.isDeviceConnected {
            return "🎧"
        }
        
        if !motionService.isDeviceReceivingData {
            return "⚠️"
        }
        
        switch motionService.currentPosture {
        case .good:
            return "😊"
        case .poor:
            return "😟"
        case .calibrating:
            return "⏳"
        case .unknown, .noData:
            return ""
        }
    }
    
    // MARK: - Challenge System
    
    private func showRandomChallenge() {
        let challenges = Challenge.allChallenges
        guard !challenges.isEmpty else { return }

        // Select a random challenge
        let randomIndex = Int.random(in: 0..<challenges.count)
        currentChallenge = challenges[randomIndex]
        showChallenge = true

        // Play audio feedback if enabled
        if userPrefs.challengeAudioFeedbackEnabledValue {
            audioService.playSound(.challengeAppear)
        }
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
        // Set up basic intervals
        scheduler.sittingInterval = TimeInterval(userPrefs.maxSitMinutes * 60)
        scheduler.standingInterval = TimeInterval(userPrefs.maxStandMinutes * 60)
        scheduler.setAutoStartEnabled(userPrefs.autoStartEnabledValue)
        
        // Set up Pomodoro settings
        scheduler.setPomodoroMode(userPrefs.pomodoroModeEnabledValue)
        scheduler.focusInterval = TimeInterval(userPrefs.focusIntervalMinutesValue * 60)
        scheduler.shortBreakInterval = TimeInterval(userPrefs.shortBreakMinutesValue * 60)
        scheduler.longBreakInterval = TimeInterval(userPrefs.longBreakMinutesValue * 60)
        scheduler.intervalsBeforeLongBreak = userPrefs.intervalsBeforeLongBreakValue
        
        // Set up motion service if enabled
        if userPrefs.postureMonitoringEnabledValue {
            motionService.setPostureThresholds(pitch: userPrefs.postureSensitivityDegreesValue, roll: userPrefs.postureSensitivityDegreesValue, duration: TimeInterval(userPrefs.poorPostureThresholdSecondsValue))
            
            // Start monitoring if authorized
            if motionService.isAuthorized {
                motionService.startMonitoring()
            }
        }
    }
    
    // MARK: - Challenge Management

    private func checkForChallengeOpportunity() {
        guard userPrefs.moveChallengesEnabledValue,
              scheduler.isRunning,
              !showChallenge else { return }
        
        let now = Date()
        
        // Check if we should show a challenge
        var shouldShow = false

        if scheduler.pomodoroModeEnabled {
            // In Pomodoro mode: show at the start of breaks
            if scheduler.currentSessionType != lastSessionType {
                if scheduler.currentSessionType == .shortBreak || scheduler.currentSessionType == .longBreak {
                    shouldShow = true
                }
            }
        } else {
            // In simple mode: show when transitioning from sitting to standing
            if scheduler.currentPhase != lastPhase {
                if scheduler.currentPhase == .standing && lastPhase == .sitting {
                    shouldShow = true
                }
            }
        }

        if shouldShow {
            showRandomChallenge()
        }

        // Update tracking variables
        if scheduler.currentSessionType != lastSessionType {
            lastSessionType = scheduler.currentSessionType
            lastPhaseTransition = now
        }

        if scheduler.currentPhase != lastPhase {
            lastPhase = scheduler.currentPhase
            lastPhaseTransition = now
        }
    }

    private func completeChallenge() {
        showChallenge = false
        currentChallenge = nil
        
        // Play completion sound if audio feedback is enabled
        if userPrefs.challengeAudioFeedbackEnabledValue {
            audioService.playSound(.challengeComplete)
        }

        statsService.recordChallengeAction(completed: true)
    }

    private func discardChallenge() {
        showChallenge = false
        currentChallenge = nil
        
        // Play discard sound if audio feedback is enabled
        if userPrefs.challengeAudioFeedbackEnabledValue {
            audioService.playSound(.challengeDiscard)
        }
        
        statsService.recordChallengeAction(completed: false)
    }

    // MARK: - Action Methods

    private func handlePlayPause() {
        if !scheduler.isRunning {
            scheduler.start()
        } else if scheduler.isPaused {
            scheduler.resume()
        } else {
            scheduler.pause()
        }
    }

    private func handleRestart() {
        guard userPrefs.maxSitMinutes > 0, userPrefs.maxStandMinutes > 0 else {
            return
        }
        scheduler.stop()
        scheduler.start()
    }

    private func handleSkipPhase() {
        if scheduler.isRunning {
            scheduler.skip()
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let remaining = max(interval, 0)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    @ViewBuilder
    private var postureIndicator: some View {
        if userPrefs.postureMonitoringEnabledValue {
            HStack(spacing: 4) {
                Text(postureEmoji)
                    .font(.system(size: 16))
                
                Text(postureText)
                    .font(.system(size: 10, weight: .medium))
                    .opacity(0.9)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(postureBackgroundColor.opacity(0.15))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(postureBackgroundColor.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var postureText: String {
        // Check device status first
        if !motionService.isDeviceConnected {
            return "Connect AirPods"
        }
        
        if !motionService.isDeviceReceivingData {
            return "Wear AirPods"
        }
        
        switch motionService.currentPosture {
        case .good:
            return "Good Posture"
        case .poor:
            return "Poor Posture"
        case .calibrating:
            return "Calibrating..."
        case .unknown:
            return "Unknown"
        case .noData:
            return "No Data"
        }
    }
    
    private var postureBackgroundColor: Color {
        // Check device status first
        if !motionService.isDeviceConnected {
            return .orange
        }
        
        if !motionService.isDeviceReceivingData {
            return .yellow
        }
        
        switch motionService.currentPosture {
        case .good:
            return .green
        case .poor:
            return .red
        case .calibrating:
            return .settingsAccentGreen
        case .unknown, .noData:
            return .clear
        }
    }

    private func openStats() {
        // Post notification to open settings on stats tab
        NotificationCenter.default.post(name: NSNotification.Name("OpenStats"), object: nil)
        onOpenSettings()
    }
} 
