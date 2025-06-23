import Foundation
import Combine
import CoreMotion

/// Detects when user stands up from sitting position
@MainActor
class StandupDetector: ObservableObject {
    @Published var isStanding = false
    @Published var lastStandupTime: Date?
    @Published var lastSitTime: Date?
    
    private var accelerationThreshold: Double = 2.0 // m/s²
    private var isHighFrequencyMode = false
    private var updateFrequency: TimeInterval = 1.0
    private var lastUpdateTime = Date()
    
    func setAccelerationThreshold(_ threshold: Double) {
        accelerationThreshold = threshold
        print("🔔 StandupDetector - Acceleration threshold set to \(threshold) m/s²")
    }
    
    func enableHighFrequencyMode() {
        isHighFrequencyMode = true
        updateFrequency = 0.5
        print("🔔 StandupDetector - High frequency mode enabled")
    }
    
    func disableHighFrequencyMode() {
        isHighFrequencyMode = false
        updateFrequency = 1.0
        print("🔔 StandupDetector - High frequency mode disabled")
    }
    
    func processMotionData(_ motionData: MotionData) {
        // Check update frequency
        let now = Date()
        if now.timeIntervalSince(lastUpdateTime) < updateFrequency {
            return
        }
        lastUpdateTime = now
        
        // Calculate vertical acceleration magnitude
        let verticalAcceleration = abs(motionData.acceleration.y)
        
        // Detect standup based on vertical acceleration
        if verticalAcceleration > accelerationThreshold {
            if !isStanding {
                isStanding = true
                lastStandupTime = now
                print("🔔 StandupDetector - 🚶 User stood up (acceleration: \(String(format: "%.2f", verticalAcceleration)) m/s²)")
                
                // Notify standup detected
                NotificationCenter.default.post(name: .standupDetected, object: nil)
            }
        } else {
            if isStanding {
                isStanding = false
                lastSitTime = now
                print("🔔 StandupDetector - 🪑 User sat down")
                
                // Notify sit down detected
                NotificationCenter.default.post(name: .sitDownDetected, object: nil)
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let standupDetected = Notification.Name("standupDetected")
    static let sitDownDetected = Notification.Name("sitDownDetected")
} 