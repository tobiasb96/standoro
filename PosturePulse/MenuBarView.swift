import SwiftUI
import SwiftData
import Combine

struct MenuBarView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [UserPrefs]
    @ObservedObject var scheduler: Scheduler
    @ObservedObject var motionService: MotionService
    @ObservedObject var calendarService: CalendarService
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    @State private var updateCounter = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
            if let p = prefs.first {
                return TimeInterval(p.maxSitMinutes * 60)
            } else {
                return scheduler.sittingInterval
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
            return "Sitting"
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
            return "chair"
        }
    }
    
    private var phaseBackgroundColor: Color {
        if !scheduler.isRunning {
            return Color.gray.opacity(0.3)
        } else if scheduler.isPaused {
            return Color.gray.opacity(0.3)
        } else {
            if scheduler.pomodoroModeEnabled {
                switch scheduler.currentSessionType {
                case .focus:
                    return Color.blue.opacity(0.3)
                case .shortBreak, .longBreak:
                    return Color.green.opacity(0.3)
                }
            } else {
                return Color.blue.opacity(0.3)
            }
        }
    }
    
    private var phaseIconColor: Color {
        if !scheduler.isRunning {
            return Color.gray
        } else if scheduler.isPaused {
            return Color.gray
        } else {
            if scheduler.pomodoroModeEnabled {
                switch scheduler.currentSessionType {
                case .focus:
                    return Color.blue
                case .shortBreak, .longBreak:
                    return Color.green
                }
            } else {
                return Color.blue
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
        guard let prefs = prefs.first else { return false }
        return prefs.calendarFilter && calendarService.isAuthorized && calendarService.isInMeeting
    }

    private var calendarMuteTooltip: String {
        if let eventDetails = calendarService.getCurrentEventDetails() {
            return "Notifications paused until \(eventDetails.endTime) after your event \"\(eventDetails.title)\""
        } else {
            return "Notifications muted - you're currently in a meeting"
        }
    }

    private var sessionProgressText: String? {
        guard scheduler.pomodoroModeEnabled && scheduler.isRunning else { return nil }
        
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
    }
    
    private var sessionProgressColor: Color {
        guard scheduler.pomodoroModeEnabled && scheduler.isRunning else { return .clear }
        
        switch scheduler.currentSessionType {
        case .focus:
            return .blue.opacity(0.2)
        case .shortBreak:
            return .green.opacity(0.2)
        case .longBreak:
            return .green.opacity(0.2)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with posture indicator and calendar mute
            HStack {
                // Posture indicator in top left
                if let prefs = prefs.first, prefs.postureMonitoringEnabledValue {
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
            if showChallenge, let challenge = currentChallenge {
                // Show challenge card
                VStack(spacing: 16) {
                    Text("Time for a Challenge!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.top, 8)
                    
                    PopupChallengeCard(
                        challenge: challenge,
                        onComplete: completeChallenge
                    )
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
            } else {
                // Show normal timer interface
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
            }

            // Bottom toolbar with smaller, monochrome buttons
            HStack {
                Button(action: { /* TODO: Stats */ }) {
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
        .frame(width: 300, height: showChallenge ? 400 : 300)
        .background(phaseBackgroundColor)
        .foregroundColor(.white)
        .onAppear(perform: setupInitialState)
        .onReceive(timer) { _ in
            // Force UI update every second when popup is open
            // This ensures posture emoji and other UI elements update regularly
            updateCounter += 1
            
            // Check for phase transitions to show challenges
            checkForChallengeOpportunity()
        }
        .onChange(of: prefs) { _, newPrefs in
            if let p = newPrefs.first {
                scheduler.sittingInterval = TimeInterval(p.maxSitMinutes * 60)
                scheduler.standingInterval = TimeInterval(p.maxStandMinutes * 60)
                
                // Update Pomodoro settings
                scheduler.setPomodoroMode(p.pomodoroModeEnabledValue)
                scheduler.focusInterval = TimeInterval(p.focusIntervalMinutesValue * 60)
                scheduler.shortBreakInterval = TimeInterval(p.shortBreakMinutesValue * 60)
                scheduler.longBreakInterval = TimeInterval(p.longBreakMinutesValue * 60)
                scheduler.intervalsBeforeLongBreak = p.intervalsBeforeLongBreakValue
                
                // Update auto-start setting
                scheduler.setAutoStartEnabled(p.autoStartEnabledValue)
                
                // Update motion service settings (but don't start/stop monitoring)
                if p.postureMonitoringEnabledValue {
                    motionService.setPostureThresholds(pitch: p.postureSensitivityDegreesValue, roll: p.postureSensitivityDegreesValue, duration: TimeInterval(p.poorPostureThresholdSecondsValue))
                }
                
                // Update calendar service integration
                scheduler.setCalendarService(calendarService, shouldCheck: p.calendarFilter)
                motionService.setCalendarService(calendarService, shouldCheck: p.calendarFilter)
                
                // Force UI update to reflect the new setting
                updateCounter += 1
            }
        }
        .onAppear {
            // Enable high frequency mode when popup is opened
            if prefs.first?.postureMonitoringEnabledValue == true && motionService.isAuthorized {
                motionService.enablePostureHighFrequencyMode()
            }
            
            // Set up calendar service integration
            if let p = prefs.first {
                scheduler.setCalendarService(calendarService, shouldCheck: p.calendarFilter)
                motionService.setCalendarService(calendarService, shouldCheck: p.calendarFilter)
                scheduler.setAutoStartEnabled(p.autoStartEnabledValue)
            }
        }
        .onDisappear {
            // Disable high frequency mode when popup is closed
            if prefs.first?.postureMonitoringEnabledValue == true && motionService.isAuthorized {
                motionService.disablePostureHighFrequencyMode()
            }
        }
    }

    // MARK: - Challenge Management
    
    private func checkForChallengeOpportunity() {
        guard let prefs = prefs.first,
              prefs.moveChallengesEnabledValue,
              scheduler.isRunning,
              !showChallenge else { return }
        
        let now = Date()
        let timeSinceLastTransition = now.timeIntervalSince(lastPhaseTransition)
        
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
                print("🔄 Phase transition detected: \(lastPhase) -> \(scheduler.currentPhase)")
                if scheduler.currentPhase == .standing && lastPhase == .sitting {
                    shouldShow = true
                    print("✅ Should show challenge: sitting -> standing transition")
                }
            }
        }
        
        if shouldShow {
            print("🎯 Showing challenge!")
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
    
    private func showRandomChallenge() {
        let challenges = Challenge.allChallenges
        guard !challenges.isEmpty else { return }
        
        // Select a random challenge
        let randomIndex = Int.random(in: 0..<challenges.count)
        currentChallenge = challenges[randomIndex]
        showChallenge = true
    }
    
    private func completeChallenge() {
        showChallenge = false
        currentChallenge = nil
        
        // Optional: Add completion tracking here
        // For now, just hide the challenge
    }

    // MARK: - Existing Methods
    
    private func setupInitialState() {
        if prefs.isEmpty {
            let newPrefs = UserPrefs()
            ctx.insert(newPrefs)
            try? ctx.save()
            scheduler.sittingInterval = TimeInterval(newPrefs.maxSitMinutes * 60)
            scheduler.standingInterval = TimeInterval(newPrefs.maxStandMinutes * 60)
            scheduler.setAutoStartEnabled(newPrefs.autoStartEnabledValue)
            
            // Set up Pomodoro settings
            scheduler.setPomodoroMode(newPrefs.pomodoroModeEnabledValue)
            scheduler.focusInterval = TimeInterval(newPrefs.focusIntervalMinutesValue * 60)
            scheduler.shortBreakInterval = TimeInterval(newPrefs.shortBreakMinutesValue * 60)
            scheduler.longBreakInterval = TimeInterval(newPrefs.longBreakMinutesValue * 60)
            scheduler.intervalsBeforeLongBreak = newPrefs.intervalsBeforeLongBreakValue
        } else if let p = prefs.first {
            scheduler.sittingInterval = TimeInterval(p.maxSitMinutes * 60)
            scheduler.standingInterval = TimeInterval(p.maxStandMinutes * 60)
            scheduler.setAutoStartEnabled(p.autoStartEnabledValue)
            
            // Set up Pomodoro settings
            scheduler.setPomodoroMode(p.pomodoroModeEnabledValue)
            scheduler.focusInterval = TimeInterval(p.focusIntervalMinutesValue * 60)
            scheduler.shortBreakInterval = TimeInterval(p.shortBreakMinutesValue * 60)
            scheduler.longBreakInterval = TimeInterval(p.longBreakMinutesValue * 60)
            scheduler.intervalsBeforeLongBreak = p.intervalsBeforeLongBreakValue
            
            // Set up motion service if enabled
            if p.postureMonitoringEnabledValue {
                motionService.setPostureThresholds(pitch: p.postureSensitivityDegreesValue, roll: p.postureSensitivityDegreesValue, duration: TimeInterval(p.poorPostureThresholdSecondsValue))
                
                // Start monitoring if authorized
                if motionService.isAuthorized {
                    motionService.startMonitoring()
                }
            }
        }
    }

    private func handlePlayPause() {
        if !scheduler.isRunning {
            // When starting, use the current preference settings
            if let p = prefs.first {
                scheduler.start(
                    sittingInterval: TimeInterval(p.maxSitMinutes * 60),
                    standingInterval: TimeInterval(p.maxStandMinutes * 60)
                )
            } else {
                scheduler.start()
            }
        } else if scheduler.isPaused {
            scheduler.resume()
        } else {
            scheduler.pause()
        }
    }

    private func handleRestart() {
        guard let p = prefs.first, p.maxSitMinutes > 0, p.maxStandMinutes > 0 else {
            return
        }
        scheduler.restart()
    }

    private func handleSkipPhase() {
        if scheduler.isRunning {
            scheduler.skipPhase()
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
        if let prefs = prefs.first, prefs.postureMonitoringEnabledValue {
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
            return .blue
        case .unknown, .noData:
            return .clear
        }
    }
} 
