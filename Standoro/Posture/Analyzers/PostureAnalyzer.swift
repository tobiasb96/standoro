import Foundation
import Combine

/// Analyzes motion data for posture detection
@MainActor
class PostureAnalyzer: BaseAnalyzer, ObservableObject {
    @Published var currentPosture: PostureStatus = .unknown
    @Published var currentPitch: Double = 0.0
    @Published var currentRoll: Double = 0.0
    @Published var pitchDeviation: Double = 0.0
    @Published var rollDeviation: Double = 0.0
    
    private var calibrationData: (pitch: Double, roll: Double)? = (pitch: 0.0, roll: 0.0)
    private var poorPostureStartTime: Date?
    private var poorPostureThreshold: TimeInterval = 30
    private var pitchThreshold: Double = 15.0
    private var rollThreshold: Double = 15.0
    
    // UserPrefs reference for persistence
    private var userPrefs: UserPrefs?
    
    // Logging throttling
    private var lastLogTime = Date()
    private var lastDurationLog = Date()
    
    enum PostureStatus {
        case good
        case poor
        case unknown
        case calibrating
        case noData
    }
    
    override func enableHighFrequencyMode() {
        super.enableHighFrequencyMode()
        updateFrequency = 1.0
    }
    
    override func disableHighFrequencyMode() {
        super.disableHighFrequencyMode()
        updateFrequency = 5.0
    }
    
    func startCalibration() {
        currentPosture = .calibrating
        calibrationData = nil
        print("🔔 PostureAnalyzer - Calibration started")
    }
    
    func completeCalibration() {
        calibrationData = (pitch: currentPitch, roll: currentRoll)
        currentPosture = .good
        print("🔔 PostureAnalyzer - Calibration completed: pitch=\(String(format: "%.1f", currentPitch))°, roll=\(String(format: "%.1f", currentRoll))°")
        
        // Save calibration data to UserPrefs
        saveCalibrationToUserPrefs()
    }
    
    func setPoorPostureThreshold(_ seconds: TimeInterval) {
        poorPostureThreshold = seconds
    }
    
    func setPitchThreshold(_ degrees: Double) {
        pitchThreshold = degrees
    }
    
    func setRollThreshold(_ degrees: Double) {
        rollThreshold = degrees
    }
    
    func setUserPrefs(_ prefs: UserPrefs) {
        self.userPrefs = prefs
        // Restore calibration data from UserPrefs
        restoreCalibrationFromUserPrefs(prefs)
    }
    
    private func saveCalibrationToUserPrefs() {
        guard let prefs = userPrefs, let calibration = calibrationData else { return }
        prefs.calibratedPitchValue = calibration.pitch
        prefs.calibratedRollValue = calibration.roll
        prefs.isCalibratedValue = true
        
        // Trigger a save to the model context
        NotificationCenter.default.post(name: NSNotification.Name("SaveUserPrefs"), object: nil)
    }
    
    private func restoreCalibrationFromUserPrefs(_ prefs: UserPrefs) {
        if prefs.isCalibratedValue, 
           let pitch = prefs.calibratedPitchValue, 
           let roll = prefs.calibratedRollValue {
            calibrationData = (pitch: pitch, roll: roll)
            print("🔔 PostureAnalyzer - Restored calibration: pitch=\(String(format: "%.1f", pitch))°, roll=\(String(format: "%.1f", roll))°")
        }
    }
    
    func setNoData() {
        currentPosture = .noData
    }
    
    func processMotionData(_ motionData: MotionData) {
        // Check if enough time has passed since last update
        if !shouldUpdate() {
            return
        }
        
        // Update current values
        currentPitch = motionData.pitch
        currentRoll = motionData.roll
        
        // Check if we need to calibrate
        if calibrationData == nil {
            calibrationData = (pitch: motionData.pitch, roll: motionData.roll)
            print("🔔 PostureAnalyzer - Auto-calibrated: pitch=\(String(format: "%.1f", motionData.pitch))°, roll=\(String(format: "%.1f", motionData.roll))°")
            
            // Save auto-calibration data to UserPrefs
            saveCalibrationToUserPrefs()
            return
        }
        
        // Calculate deviation from calibrated position
        let pitchDev = abs(MotionData.normalizeAngle(motionData.pitch - calibrationData!.pitch))
        let rollDev = abs(MotionData.normalizeAngle(motionData.roll - calibrationData!.roll))
        
        pitchDeviation = pitchDev
        rollDeviation = rollDev
        
        // Determine posture status
        let isGoodPosture = pitchDev <= pitchThreshold && rollDev <= rollThreshold
        
        // Log current status (throttled)
        if Date().timeIntervalSince(lastLogTime) > 2.0 {
            print("🔔 PostureAnalyzer - Current: pitch=\(String(format: "%.1f", motionData.pitch))°, roll=\(String(format: "%.1f", motionData.roll))° | Deviations: pitch=\(String(format: "%.1f", pitchDev))°, roll=\(String(format: "%.1f", rollDev))° | Good posture: \(isGoodPosture)")
            lastLogTime = Date()
        }
        
        if isGoodPosture {
            if currentPosture == .poor {
                poorPostureStartTime = nil
                currentPosture = .good
                print("🔔 PostureAnalyzer - ✅ Posture improved")
                
                // Start tracking sustained good posture
                NotificationCenter.default.post(name: .postureImproved, object: nil)
            } else if currentPosture == .calibrating {
                currentPosture = .good
                print("🔔 PostureAnalyzer - ✅ Calibration complete")
            } else if currentPosture == .noData {
                currentPosture = .good
            }
        } else {
            if currentPosture == .good || currentPosture == .calibrating || currentPosture == .noData {
                poorPostureStartTime = Date()
                currentPosture = .poor
                print("🔔 PostureAnalyzer - ⚠️ Poor posture detected")
                
                // Stop tracking good posture when it becomes poor
                NotificationCenter.default.post(name: .postureBecamePoor, object: nil)
            } else if currentPosture == .poor {
                checkPoorPostureDuration()
            }
        }
    }
    
    private func checkPoorPostureDuration() {
        guard let startTime = poorPostureStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        if duration >= poorPostureThreshold {
            // Notify that poor posture threshold reached
            NotificationCenter.default.post(name: .postureThresholdReached, object: nil)
            poorPostureStartTime = Date()
            print("🔔 PostureAnalyzer - 🚨 Poor posture maintained for \(Int(poorPostureThreshold)) seconds")
        } else {
            // Log remaining time every 5 seconds
            if Date().timeIntervalSince(lastDurationLog) > 5.0 {
                let remaining = poorPostureThreshold - duration
                print("🔔 PostureAnalyzer - ⏰ Poor posture for \(Int(duration))s, \(Int(remaining))s until notification")
                lastDurationLog = Date()
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let postureThresholdReached = Notification.Name("postureThresholdReached")
    static let postureImproved = Notification.Name("postureImproved")
    static let postureBecamePoor = Notification.Name("postureBecamePoor")
} 