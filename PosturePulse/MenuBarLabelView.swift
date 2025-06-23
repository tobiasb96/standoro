import SwiftUI
import SwiftData
import Combine

struct MenuBarLabelView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [UserPrefs]
    @ObservedObject var scheduler: Scheduler
    @ObservedObject var motionService: MotionService
    
    @State private var updateCounter = 0
    @State private var timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    private var userPrefs: UserPrefs {
        if let p = prefs.first {
            return p
        } else {
            let newPrefs = UserPrefs()
            ctx.insert(newPrefs)
            try? ctx.save()
            return newPrefs
        }
    }
    
    private var shouldShowCountdown: Bool {
        let shouldShow = userPrefs.showMenuBarCountdown && scheduler.isRunning && !scheduler.isPaused
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
        .onChange(of: prefs) { _, newPrefs in
            // Force UI update when preferences change
            updateCounter += 1
        }
    }
} 
