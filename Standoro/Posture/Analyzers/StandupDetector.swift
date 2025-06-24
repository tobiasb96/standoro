import Foundation
import Combine
import CoreMotion

/// Detects when user stands up from sitting position
@MainActor
class StandupDetector: BaseAnalyzer, ObservableObject {
    @Published var isStanding = false
    @Published var lastStandupTime: Date?
    @Published var lastSitTime: Date?
    
    private var accelerationThreshold: Double = 2.0 // m/s²
    
    func setAccelerationThreshold(_ threshold: Double) {
        accelerationThreshold = threshold
    }
    
    override func enableHighFrequencyMode() {
        super.enableHighFrequencyMode()
        updateFrequency = 0.5
    }
    
    override func disableHighFrequencyMode() {
        super.disableHighFrequencyMode()
        updateFrequency = 1.0
    }
    
    func processMotionData(_ motionData: MotionData) {
        // Check update frequency
        if !shouldUpdate() {
            return
        }
        
        // Calculate vertical acceleration magnitude
        let verticalAcceleration = abs(motionData.acceleration.y)
        
        // Detect standup based on vertical acceleration
        if verticalAcceleration > accelerationThreshold {
            if !isStanding {
                isStanding = true
                lastStandupTime = Date()
                print("🔔 StandupDetector - 🚶 User stood up (acceleration: \(String(format: "%.2f", verticalAcceleration)) m/s²)")
                
                // Notify standup detected
                NotificationCenter.default.post(name: .standupDetected, object: nil)
            }
        } else {
            if isStanding {
                isStanding = false
                lastSitTime = Date()
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