import SwiftUI
import SwiftData
import Combine

struct MenuBarView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [UserPrefs]
    @ObservedObject var scheduler: Scheduler
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

    var body: some View {
        VStack(spacing: 0) {
            VStack {
                Spacer(minLength: 20)

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

                    Button(action: handlePlayPause) {
                        Image(systemName: playPauseIcon)
                            .font(.system(size: 44, weight: .thin))
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 20)
            }

            HStack {
                Button(action: { /* TODO: Stats */ }) {
                    Image(systemName: "chart.bar.xaxis")
                }.buttonStyle(.plain)
                
                Spacer()
                
                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape.fill")
                }.buttonStyle(.plain)
                
                Spacer()
                
                Button(action: onQuit) {
                    Image(systemName: "power")
                }.buttonStyle(.plain)
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
            // Force UI update every second when timer is running and not paused
            if scheduler.isRunning && !scheduler.isPaused {
                // This will trigger a UI refresh every second
                updateCounter += 1
            }
        }
        .onChange(of: prefs) { _, newPrefs in
            print("🔔 Preferences changed, count: \(newPrefs.count)")
            if let p = newPrefs.first {
                print("🔔 Setting intervals from onChange: sitting \(p.maxSitMinutes) minutes, standing \(p.maxStandMinutes) minutes")
                scheduler.sittingInterval = TimeInterval(p.maxSitMinutes * 60)
                scheduler.standingInterval = TimeInterval(p.maxStandMinutes * 60)
                // Force UI update to reflect the new setting
                updateCounter += 1
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

    private func formatTime(_ interval: TimeInterval) -> String {
        let remaining = max(interval, 0)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
} 