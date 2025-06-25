import Foundation
import Combine
import CoreMotion

/// Detects when user stands up or sits down using motion data
@MainActor
class StandupDetector: ObservableObject {
    @Published var isStanding: Bool = false
    
    // Configuration
    private var accelerationThreshold: Double = 2.0 // m/s²
    private var updateFrequency: TimeInterval = 1.0
    private var isHighFrequencyMode = false
    
    // State tracking
    private var lastUpdateTime: Date = Date()
    private var lastAcceleration: Double = 0.0
    private var accelerationBuffer: [Double] = []
    private let bufferSize = 5
    
    // Publishers
    private let standupEventSubject = PassthroughSubject<Bool, Never>()
    
    var standupEventPublisher: AnyPublisher<Bool, Never> {
        standupEventSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Configuration Methods
    
    func setAccelerationThreshold(_ threshold: Double) {
        accelerationThreshold = threshold
    }
    
    func enableHighFrequencyMode() {
        isHighFrequencyMode = true
        updateFrequency = 0.1 // 10Hz updates
    }
    
    func disableHighFrequencyMode() {
        isHighFrequencyMode = false
        updateFrequency = 1.0 // 1Hz updates
    }
    
    // MARK: - Analysis Methods
    
    func processMotionData(_ motionData: MotionData) {
        // Check if we should update based on frequency
        if !shouldUpdate() {
            return
        }
        
        // Calculate vertical acceleration (simplified)
        let verticalAcceleration = abs(motionData.acceleration.z)
        
        // Add to buffer for smoothing
        accelerationBuffer.append(verticalAcceleration)
        if accelerationBuffer.count > bufferSize {
            accelerationBuffer.removeFirst()
        }
        
        // Calculate average acceleration
        let averageAcceleration = accelerationBuffer.reduce(0, +) / Double(accelerationBuffer.count)
        
        // Detect significant acceleration change
        let accelerationChange = abs(averageAcceleration - lastAcceleration)
        
        if accelerationChange > accelerationThreshold {
            // Detect standup/sitdown based on acceleration pattern
            if averageAcceleration > lastAcceleration && !isStanding {
                // User stood up
                isStanding = true
                standupEventSubject.send(true)
                
                #if DEBUG
                print("StandupDetector: User stood up (acceleration: \(String(format: "%.2f", verticalAcceleration)) m/s²)")
                #endif
            } else if averageAcceleration < lastAcceleration && isStanding {
                // User sat down
                isStanding = false
                standupEventSubject.send(false)
                
                #if DEBUG
                print("StandupDetector: User sat down")
                #endif
            }
        }
        
        lastAcceleration = averageAcceleration
        lastUpdateTime = Date()
    }
    
    private func shouldUpdate() -> Bool {
        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdateTime)
        return timeSinceLastUpdate >= updateFrequency
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let standupDetected = Notification.Name("standupDetected")
    static let sitDownDetected = Notification.Name("sitDownDetected")
} 