import SwiftUI
import SwiftData
import Combine

struct MenuBarLabelView: View {
    @Environment(\.modelContext) private var ctx
    let userPrefs: UserPrefs
    @ObservedObject var scheduler: Scheduler
    @ObservedObject var motionService: MotionService
    
    @State private var updateCounter = 0
    @State private var timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    private var shouldShowCountdown: Bool {
        let shouldShow = userPrefs.showMenuBarCountdown && scheduler.isRunning && !scheduler.isPaused
        print("📊 MenuBarLabelView: shouldShowCountdown - showMenuBarCountdown: \(userPrefs.showMenuBarCountdown), isRunning: \(scheduler.isRunning), isPaused: \(scheduler.isPaused) -> \(shouldShow)")
        return shouldShow
    }
    
    private var shouldShowPosture: Bool {
        return userPrefs.postureMonitoringEnabledValue
    }
    
    private var countdownText: String {
        // Use updateCounter to force recalculation when timer fires
        let _ = updateCounter
        
        if scheduler.isPaused {
            return "⏸"
        }
        
        // Use the scheduler's currentRemainingTime which handles pause state correctly
        let remaining = scheduler.currentRemainingTime
        
        let minutes = Int(max(remaining, 0)) / 60
        let seconds = Int(max(remaining, 0)) % 60
        
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            return "\(seconds)s"
        }
    }
    
    private var postureEmoji: String {
        guard userPrefs.postureMonitoringEnabledValue else { return "" }
        
        // Only show posture emoji if device is connected and receiving data
        guard motionService.isDeviceConnected && motionService.isDeviceReceivingData else { return "" }
        
        switch motionService.currentPosture {
        case .good:
            return "😊"
        case .poor:
            return "😟"
        case .calibrating, .unknown, .noData:
            return ""
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "figure.stand")
                .renderingMode(.template)
            
            if shouldShowCountdown {
                Text(" \(countdownText)")
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
            }
            
            if shouldShowPosture && !postureEmoji.isEmpty {
                Text(" \(postureEmoji)")
                    .font(.system(size: 12))
            }
        }
        .onReceive(timer) { _ in
            // Only update counter for scheduler-related updates
            if scheduler.isRunning && !scheduler.isPaused {
                updateCounter += 1
            }
        }
        .onChange(of: userPrefs.showMenuBarCountdown) { _, newValue in
            print("📊 MenuBarLabelView: showMenuBarCountdown changed to: \(newValue)")
            // Force UI update when showMenuBarCountdown changes
            updateCounter += 1
        }
        .onChange(of: userPrefs.postureMonitoringEnabledValue) { _, newValue in
            print("📊 MenuBarLabelView: postureMonitoringEnabledValue changed to: \(newValue)")
            // Force UI update when posture monitoring changes
            updateCounter += 1
        }
    }
} 
