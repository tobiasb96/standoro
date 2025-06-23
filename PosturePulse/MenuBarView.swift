import SwiftUI
import SwiftData
import Combine

struct MenuBarView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [UserPrefs]
    @ObservedObject var scheduler: Scheduler
    @ObservedObject var motionService: MotionService
    @StateObject private var calendarService = CalendarService()
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    @State private var updateCounter = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
            switch scheduler.currentPhase {
            case .sitting:
                return "Sitting"
            case .standing:
                return "Standing"
            }
        } else {
            return "Sitting"
        }
    }

    private var playPauseIcon: String {
        return scheduler.isRunning && !scheduler.isPaused ? "pause.circle.fill" : "play.circle.fill"
    }
    
    private var shouldShowCalendarMute: Bool {
        guard let prefs = prefs.first else { return false }
        return prefs.calendarFilter && calendarService.isAuthorized && calendarService.isInMeeting
    }

    var body: some View {
        VStack(spacing: 0) {
            // Calendar mute indicator in top right
            HStack {
                Spacer()
                if shouldShowCalendarMute {
                    Image(systemName: "bell.slash.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                        .help("Notifications muted - you're currently in a meeting")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            VStack {
                Spacer(minLength: 20)

                // Posture indicator
                HStack {
                    Spacer()
                    postureIndicator
                    Spacer()
                }
                .padding(.bottom, 10)

                Text(phaseText)
                    .font(.system(size: 28, weight: .medium))

                Text(formatTime(displayTime))
                    .font(.system(size: 64, weight: .light, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                HStack(spacing: 40) {
                    Button(action: handleRestart) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 22))
                    }
                    .buttonStyle(.plain)
                    .disabled(!scheduler.isRunning)
                    .help("Restart timer")

                    Button(action: handlePlayPause) {
                        Image(systemName: playPauseIcon)
                            .font(.system(size: 44, weight: .thin))
                    }
                    .buttonStyle(.plain)
                    .help(scheduler.isRunning && !scheduler.isPaused ? "Pause timer" : "Start/resume timer")
                    
                    Button(action: handleSkipPhase) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 22))
                    }
                    .buttonStyle(.plain)
                    .disabled(!scheduler.isRunning)
                    .help("Skip to next phase")
                }

                Spacer(minLength: 20)
            }

            HStack {
                Button(action: { /* TODO: Stats */ }) {
                    Image(systemName: "chart.bar.xaxis")
                }.buttonStyle(.plain)
                .help("View statistics")
                
                Spacer()
                
                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape.fill")
                }.buttonStyle(.plain)
                .help("Open settings")
                
                Spacer()
                
                Button(action: onQuit) {
                    Image(systemName: "power")
                }.buttonStyle(.plain)
                .help("Quit application")
            }
            .font(.system(size: 20))
            .padding()
            .background(Color.black.opacity(0.2))
        }
        .frame(width: 300, height: 300)
        .background(Color(red: 0.0, green: 0.2, blue: 0.6))
        .foregroundColor(.white)
        .onAppear(perform: setupInitialState)
        .onReceive(timer) { _ in
            // Force UI update every second when popup is open
            // This ensures posture emoji and other UI elements update regularly
            updateCounter += 1
        }
        .onChange(of: prefs) { _, newPrefs in
            print("🔔 Preferences changed, count: \(newPrefs.count)")
            if let p = newPrefs.first {
                print("🔔 Setting intervals from onChange: sitting \(p.maxSitMinutes) minutes, standing \(p.maxStandMinutes) minutes")
                scheduler.sittingInterval = TimeInterval(p.maxSitMinutes * 60)
                scheduler.standingInterval = TimeInterval(p.maxStandMinutes * 60)
                
                // Update motion service settings
                if p.postureMonitoringEnabledValue {
                    motionService.setPostureThresholds(pitch: p.postureSensitivityDegreesValue, roll: p.postureSensitivityDegreesValue, duration: TimeInterval(p.poorPostureThresholdSecondsValue))
                    
                    // Start monitoring if authorized
                    if motionService.isAuthorized {
                        motionService.startMonitoring()
                    }
                } else {
                    // Stop monitoring if disabled
                    motionService.stopMonitoring()
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
            }
        }
        .onDisappear {
            // Disable high frequency mode when popup is closed
            if prefs.first?.postureMonitoringEnabledValue == true && motionService.isAuthorized {
                motionService.disablePostureHighFrequencyMode()
            }
        }
    }

    private func setupInitialState() {
        print("🔔 setupInitialState called, prefs count: \(prefs.count)")
        
        if prefs.isEmpty {
            print("🔔 Creating default preferences")
            let newPrefs = UserPrefs()
            ctx.insert(newPrefs)
            try? ctx.save()
            scheduler.sittingInterval = TimeInterval(newPrefs.maxSitMinutes * 60)
            scheduler.standingInterval = TimeInterval(newPrefs.maxStandMinutes * 60)
        } else if let p = prefs.first {
            print("🔔 Setting intervals from preferences: sitting \(p.maxSitMinutes) minutes, standing \(p.maxStandMinutes) minutes")
            scheduler.sittingInterval = TimeInterval(p.maxSitMinutes * 60)
            scheduler.standingInterval = TimeInterval(p.maxStandMinutes * 60)
            
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
            print("🔔 Cannot restart: intervals not set")
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
            HStack(spacing: 8) {
                Text(postureEmoji)
                    .font(.system(size: 24))
                
                Text(postureText)
                    .font(.system(size: 12, weight: .medium))
                    .opacity(0.8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(postureBackgroundColor.opacity(0.2))
            .cornerRadius(12)
        }
    }
    
    private var postureEmoji: String {
        switch motionService.currentPosture {
        case .good:
            return "😊"
        case .poor:
            return "😟"
        case .calibrating, .unknown, .noData:
            return ""
        }
    }
    
    private var postureText: String {
        switch motionService.currentPosture {
        case .good:
            return "Good Posture"
        case .poor:
            return "Poor Posture"
        case .calibrating, .unknown:
            return ""
        case .noData:
            return "Wear AirPods for posture detection"
        }
    }
    
    private var postureBackgroundColor: Color {
        switch motionService.currentPosture {
        case .good:
            return .green
        case .poor:
            return .red
        case .calibrating, .unknown, .noData:
            return .clear
        }
    }
} 
