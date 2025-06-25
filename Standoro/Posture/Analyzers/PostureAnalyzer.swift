import Foundation
import Combine

/// Analyzes motion data to detect posture quality
@MainActor
class PostureAnalyzer: ObservableObject {
    @Published var currentPosture: PostureStatus = .unknown
    @Published var currentPitch: Double = 0.0
    @Published var currentRoll: Double = 0.0
    @Published var pitchDeviation: Double = 0.0
    @Published var rollDeviation: Double = 0.0
    
    // Calibration data
    private var calibrationData: (pitch: Double, roll: Double)?
    private var userPrefs: UserPrefs?
    
    // Thresholds
    private var pitchThreshold: Double = 15.0
    private var rollThreshold: Double = 15.0
    private var poorPostureThreshold: TimeInterval = 30.0
    
    // State tracking
    private var poorPostureStartTime: Date?
    private var isInPoorPosture = false
    private var lastUpdateTime: Date = Date()
    private var updateFrequency: TimeInterval = 1.0
    private var isHighFrequencyMode = false
    
    // Publishers
    private let postureStatusSubject = PassthroughSubject<PostureStatus, Never>()
    private let poorPostureAlertSubject = PassthroughSubject<Void, Never>()
    
    var postureStatusPublisher: AnyPublisher<PostureStatus, Never> {
        postureStatusSubject.eraseToAnyPublisher()
    }
    
    var poorPostureAlertPublisher: AnyPublisher<Void, Never> {
        poorPostureAlertSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Calibration Methods
    
    func startCalibration() {
        // Reset calibration data
        calibrationData = nil
        currentPosture = .calibrating
        #if DEBUG
        print("PostureAnalyzer: Calibration started")
        #endif
    }
    
    func completeCalibration() {
        guard let pitch = currentPitch, let roll = currentRoll else {
            return
        }
        
        calibrationData = (pitch: pitch, roll: roll)
        currentPosture = .good
        
        // Save calibration to UserPrefs if available
        if let prefs = userPrefs {
            prefs.calibratedPitchValue = pitch
            prefs.calibratedRollValue = roll
            prefs.isCalibratedValue = true
        }
        
        #if DEBUG
        print("PostureAnalyzer: Calibration completed: pitch=\(String(format: "%.1f", pitch))°, roll=\(String(format: "%.1f", roll))°")
        #endif
    }
    
    func setUserPrefs(_ prefs: UserPrefs) {
        self.userPrefs = prefs
        
        // Restore calibration if available
        if prefs.isCalibratedValue, 
           let pitch = prefs.calibratedPitchValue,
           let roll = prefs.calibratedRollValue {
            calibrationData = (pitch: pitch, roll: roll)
            currentPosture = .good
            
            #if DEBUG
            print("PostureAnalyzer: Restored calibration: pitch=\(String(format: "%.1f", pitch))°, roll=\(String(format: "%.1f", roll))°")
            #endif
        }
    }
    
    // MARK: - Configuration Methods
    
    func setPitchThreshold(_ threshold: Double) {
        pitchThreshold = threshold
    }
    
    func setRollThreshold(_ threshold: Double) {
        rollThreshold = threshold
    }
    
    func setPoorPostureThreshold(_ threshold: TimeInterval) {
        poorPostureThreshold = threshold
    }
    
    func setUpdateFrequency(_ frequency: TimeInterval) {
        updateFrequency = frequency
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
        // Update current values
        currentPitch = motionData.pitch
        currentRoll = motionData.roll
        
        // Auto-calibrate if no calibration data exists
        if calibrationData == nil {
            calibrationData = (pitch: motionData.pitch, roll: motionData.roll)
            currentPosture = .good
            
            #if DEBUG
            print("PostureAnalyzer: Auto-calibrated: pitch=\(String(format: "%.1f", motionData.pitch))°, roll=\(String(format: "%.1f", motionData.roll))°")
            #endif
            return
        }
        
        // Check if we should update based on frequency
        if !shouldUpdate() {
            return
        }
        
        // Calculate deviations from calibration
        guard let calibration = calibrationData else {
            return
        }
        
        let pitchDev = abs(MotionData.normalizeAngle(motionData.pitch - calibration.pitch))
        let rollDev = abs(MotionData.normalizeAngle(motionData.roll - calibration.roll))
        
        pitchDeviation = pitchDev
        rollDeviation = rollDev
        
        #if DEBUG
        print("PostureAnalyzer: Current: pitch=\(String(format: "%.1f", motionData.pitch))°, roll=\(String(format: "%.1f", motionData.roll))° | Deviations: pitch=\(String(format: "%.1f", pitchDev))°, roll=\(String(format: "%.1f", rollDev))°")
        #endif
        
        // Determine posture status
        let isGoodPosture = pitchDev <= pitchThreshold && rollDev <= rollThreshold
        
        if isGoodPosture {
            if currentPosture != .good {
                currentPosture = .good
                postureStatusSubject.send(.good)
                
                #if DEBUG
                print("PostureAnalyzer: ✅ Posture improved")
                #endif
                
                // Reset poor posture tracking
                if isInPoorPosture {
                    isInPoorPosture = false
                    poorPostureStartTime = nil
                }
            }
            
            // Check if calibration is complete
            if currentPosture == .calibrating {
                completeCalibration()
            }
        } else {
            if currentPosture != .poor {
                currentPosture = .poor
                postureStatusSubject.send(.poor)
                
                #if DEBUG
                print("PostureAnalyzer: ⚠️ Poor posture detected")
                #endif
                
                // Start tracking poor posture duration
                if !isInPoorPosture {
                    isInPoorPosture = true
                    poorPostureStartTime = Date()
                }
            }
            
            // Check if poor posture has been maintained for threshold duration
            if isInPoorPosture, let startTime = poorPostureStartTime {
                let duration = Date().timeIntervalSince(startTime)
                
                if duration >= poorPostureThreshold {
                    #if DEBUG
                    print("PostureAnalyzer: 🚨 Poor posture maintained for \(Int(poorPostureThreshold)) seconds")
                    #endif
                    
                    // Send alert
                    poorPostureAlertSubject.send(())
                    
                    // Reset to prevent multiple alerts
                    poorPostureStartTime = Date()
                } else {
                    let remaining = poorPostureThreshold - duration
                    #if DEBUG
                    print("PostureAnalyzer: ⏰ Poor posture for \(Int(duration))s, \(Int(remaining))s until notification")
                    #endif
                }
            }
        }
        
        lastUpdateTime = Date()
    }
    
    private func shouldUpdate() -> Bool {
        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdateTime)
        return timeSinceLastUpdate >= updateFrequency
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let postureThresholdReached = Notification.Name("postureThresholdReached")
    static let postureImproved = Notification.Name("postureImproved")
    static let postureBecamePoor = Notification.Name("postureBecamePoor")
} 