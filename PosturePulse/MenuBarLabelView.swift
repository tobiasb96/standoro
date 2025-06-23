import SwiftUI
import SwiftData
import Combine

struct MenuBarLabelView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [UserPrefs]
    @ObservedObject var scheduler: Scheduler
    @ObservedObject var postureService: PostureService
    
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
        
        switch postureService.currentPosture {
        case .good:
            return "😊"
        case .poor:
            return "😟"
        case .calibrating, .unknown, .noAirPods:
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
            
            if !postureEmoji.isEmpty {
                Text(" \(postureEmoji)")
                    .font(.system(size: 12))
            }
        }
        .onReceive(timer) { _ in
            if scheduler.isRunning && !scheduler.isPaused {
                updateCounter += 1
            }
            // Also update when posture monitoring is enabled to show emoji changes
            if userPrefs.postureMonitoringEnabledValue && postureService.isAuthorized {
                updateCounter += 1
            }
        }
        .onChange(of: prefs) { _, newPrefs in
            print("🔔 MenuBarLabelView - Preferences changed, count: \(newPrefs.count)")
            if let p = newPrefs.first {
                print("🔔 MenuBarLabelView - showMenuBarCountdown: \(p.showMenuBarCountdown)")
            }
            // Force UI update when preferences change
            updateCounter += 1
        }
        .onAppear {
            print("🔔 MenuBarLabelView - onAppear, prefs count: \(prefs.count)")
            if let p = prefs.first {
                print("🔔 MenuBarLabelView - showMenuBarCountdown: \(p.showMenuBarCountdown)")
            }
        }
    }
} 
