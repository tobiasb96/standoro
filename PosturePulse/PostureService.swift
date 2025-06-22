import Foundation
import CoreMotion
import UserNotifications
import Combine

@MainActor
class PostureService: NSObject, ObservableObject, CMHeadphoneMotionManagerDelegate {
    @Published var isEnabled = false
    @Published var isAuthorized = false
    @Published var isMonitoring = false
    @Published var currentPosture: PostureStatus = .unknown
    @Published var errorMessage: String?
    @Published var currentPitch: Double = 0.0
    @Published var currentRoll: Double = 0.0
    @Published var pitchDeviation: Double = 0.0
    @Published var rollDeviation: Double = 0.0
    
    private var motionManager: CMHeadphoneMotionManager?
    private var timer: Timer?
    private var poorPostureStartTime: Date?
    private var poorPostureThreshold: TimeInterval = 30 // Default 30 seconds
    private var pitchThreshold: Double = 15.0 // Degrees from upright
    private var rollThreshold: Double = 15.0 // Degrees from upright
    
    // Logging throttling variables
    private var lastLogTime = Date()
    private var lastDurationLog = Date()
    
    enum PostureStatus {
        case good
        case poor
        case unknown
        case calibrating
        case noAirPods
    }
    
    // Default to perfect 0/0 degrees calibration
    private var calibrationData: (pitch: Double, roll: Double)? = (pitch: 0.0, roll: 0.0)
    
    override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    deinit {
        // Use Task to ensure we're on the main actor for cleanup
        Task { @MainActor [weak self] in
            self?.cleanupMotionManager()
        }
    }
    
    // MARK: - Public Methods
    
    func requestAccess() async -> Bool {
        // Check if headphone motion is available (AirPods)
        guard CMHeadphoneMotionManager().isDeviceMotionAvailable else {
            await MainActor.run {
                self.errorMessage = "AirPods motion is not available. Please ensure you have AirPods connected and are running macOS Sonoma 14.0+"
            }
            return false
        }
        
        // Create motion manager if needed
        if motionManager == nil {
            motionManager = CMHeadphoneMotionManager()
            motionManager?.delegate = self
        }
        
        guard let motionManager = motionManager else {
            await MainActor.run {
                self.errorMessage = "Failed to initialize motion manager"
            }
            return false
        }
        
        // Start motion updates to check if we can access AirPods data
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            
            motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
                // Ensure we only resume once
                guard !hasResumed else { return }
                hasResumed = true
                
                // Stop motion updates immediately
                motionManager.stopDeviceMotionUpdates()
                
                if let error = error {
                    print("🔔 PostureService - Motion error: \(error)")
                    continuation.resume(returning: false)
                    return
                }
                
                if let motion = motion {
                    // Check if we have AirPods data by looking for gravity data
                    if motion.gravity.x != 0 || motion.gravity.y != 0 || motion.gravity.z != 0 {
                        print("🔔 PostureService - AirPods motion data available")
                        continuation.resume(returning: true)
                    } else {
                        print("🔔 PostureService - No AirPods motion data available")
                        continuation.resume(returning: false)
                    }
                } else {
                    print("🔔 PostureService - No motion data")
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    func startMonitoring() {
        guard isAuthorized else {
            print("🔔 PostureService - Not authorized to monitor posture")
            currentPosture = .noAirPods
            return
        }
        
        guard CMHeadphoneMotionManager().isDeviceMotionAvailable else {
            errorMessage = "AirPods motion is not available"
            currentPosture = .noAirPods
            return
        }
        
        // Create motion manager if needed
        if motionManager == nil {
            motionManager = CMHeadphoneMotionManager()
            motionManager?.delegate = self
        }
        
        guard let motionManager = motionManager else {
            errorMessage = "Failed to initialize motion manager"
            currentPosture = .noAirPods
            return
        }
        
        print("🔔 PostureService - Starting continuous monitoring...")
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            Task { @MainActor in
                self?.processMotionData(motion, error: error)
            }
        }
        
        isMonitoring = true
        currentPosture = .calibrating
        print("🔔 PostureService - Started monitoring")
    }
    
    func stopMonitoring() {
        cleanupMotionManager()
        isMonitoring = false
        currentPosture = .unknown
        poorPostureStartTime = nil
        print("🔔 PostureService - Stopped monitoring")
    }
    
    func calibrate() {
        currentPosture = .calibrating
        calibrationData = nil
        print("🔔 PostureService - Starting calibration...")
        
        // Start a brief calibration period
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            Task { @MainActor in
                self?.currentPosture = .good
                print("🔔 PostureService - Calibration complete, posture set to good")
            }
        }
    }
    
    func startCalibration() {
        currentPosture = .calibrating
        calibrationData = nil
        print("🔔 PostureService - Calibration started - please sit straight and look at the center of your screen")
    }
    
    func completeCalibration() {
        // Use current position as calibration data
        calibrationData = (pitch: currentPitch, roll: currentRoll)
        currentPosture = .good
        print("🔔 PostureService - Calibration completed with: pitch=\(String(format: "%.1f", currentPitch))°, roll=\(String(format: "%.1f", currentRoll))°")
    }
    
    func setPoorPostureThreshold(_ seconds: TimeInterval) {
        poorPostureThreshold = seconds
        print("🔔 PostureService - Poor posture threshold set to \(seconds) seconds")
    }
    
    func setPitchThreshold(_ degrees: Double) {
        pitchThreshold = degrees
        print("🔔 PostureService - Pitch threshold set to \(degrees) degrees")
    }
    
    func setRollThreshold(_ degrees: Double) {
        rollThreshold = degrees
        print("🔔 PostureService - Roll threshold set to \(rollThreshold) degrees")
    }
    
    // MARK: - CMHeadphoneMotionManagerDelegate
    
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        print("🔔 PostureService - Headphones connected")
    }
    
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        print("🔔 PostureService - Headphones disconnected")
        isMonitoring = false
        currentPosture = .unknown
    }
    
    // MARK: - Private Methods
    
    private func checkAuthorizationStatus() {
        // Check if headphone motion is available
        isAuthorized = CMHeadphoneMotionManager().isDeviceMotionAvailable
        if !isAuthorized {
            errorMessage = "AirPods motion is not available. Please ensure you have AirPods connected and are running macOS Sonoma 14.0+"
            currentPosture = .noAirPods
        } else {
            currentPosture = .unknown
        }
    }
    
    private func processMotionData(_ motion: CMDeviceMotion?, error: Error?) {
        if let error = error {
            print("🔔 PostureService - Motion error: \(error)")
            errorMessage = "Motion data error: \(error.localizedDescription)"
            return
        }
        
        guard let motion = motion else {
            print("🔔 PostureService - No motion data received")
            return
        }
        
        // Convert quaternion to Euler angles
        let (pitch, roll) = quaternionToEulerAngles(motion.attitude.quaternion)
        
        // Update published values for UI
        currentPitch = pitch
        currentRoll = roll
        
        // Check if we need to calibrate
        if calibrationData == nil {
            calibrationData = (pitch: pitch, roll: roll)
            print("🔔 PostureService - Calibrated: pitch=\(String(format: "%.1f", pitch))°, roll=\(String(format: "%.1f", roll))°")
            return
        }
        
        // Calculate deviation from calibrated position with proper angle wrapping
        let pitchDev = abs(normalizeAngle(pitch - calibrationData!.pitch))
        let rollDev = abs(normalizeAngle(roll - calibrationData!.roll))
        
        // Update published values for UI
        pitchDeviation = pitchDev
        rollDeviation = rollDev
        
        // Determine posture status
        let isGoodPosture = pitchDev <= pitchThreshold && rollDev <= rollThreshold
        
        // Log current status every few seconds (throttled to avoid spam)
        if Date().timeIntervalSince(lastLogTime) > 2.0 {
            print("🔔 PostureService - Current: pitch=\(String(format: "%.1f", pitch))°, roll=\(String(format: "%.1f", roll))° | Deviations: pitch=\(String(format: "%.1f", pitchDev))°, roll=\(String(format: "%.1f", rollDev))° | Thresholds: pitch=\(String(format: "%.1f", pitchThreshold))°, roll=\(String(format: "%.1f", rollThreshold))° | Good posture: \(isGoodPosture)")
            lastLogTime = Date()
        }
        
        if isGoodPosture {
            if currentPosture == .poor {
                // User returned to good posture
                poorPostureStartTime = nil
                currentPosture = .good
                print("🔔 PostureService - ✅ Posture improved - back to good posture")
            } else if currentPosture == .calibrating {
                currentPosture = .good
                print("🔔 PostureService - ✅ Calibration complete, posture is good")
            }
        } else {
            if currentPosture == .good || currentPosture == .calibrating {
                // User started poor posture
                poorPostureStartTime = Date()
                currentPosture = .poor
                print("🔔 PostureService - ⚠️ Poor posture detected: pitch deviation=\(String(format: "%.1f", pitchDev))°, roll deviation=\(String(format: "%.1f", rollDev))°")
            } else if currentPosture == .poor {
                // Check if poor posture has been maintained for threshold duration
                checkPoorPostureDuration()
            }
        }
    }
    
    private func checkPoorPostureDuration() {
        guard let startTime = poorPostureStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        if duration >= poorPostureThreshold {
            // Send notification
            sendPostureNotification()
            // Reset timer to avoid spam
            poorPostureStartTime = Date()
            print("🔔 PostureService - 🚨 Poor posture maintained for \(Int(poorPostureThreshold)) seconds - notification sent")
        } else {
            // Log remaining time every 5 seconds
            if Date().timeIntervalSince(lastDurationLog) > 5.0 {
                let remaining = poorPostureThreshold - duration
                print("🔔 PostureService - ⏰ Poor posture for \(Int(duration))s, \(Int(remaining))s until notification")
                lastDurationLog = Date()
            }
        }
    }
    
    private func sendPostureNotification() {
        print("🔔 PostureService - Sending posture notification")
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                let content = UNMutableNotificationContent()
                content.title = "Check Your Posture!"
                content.body = "Sit up straight to maintain good posture."
                content.sound = .default
                
                let request = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: nil
                )
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("🔔 PostureService - Notification error: \(error)")
                    } else {
                        print("🔔 PostureService - ✅ Posture notification sent successfully")
                    }
                }
            } else {
                print("🔔 PostureService - ❌ Notifications not authorized")
            }
        }
    }
    
    private func quaternionToEulerAngles(_ quaternion: CMQuaternion) -> (pitch: Double, roll: Double) {
        // Convert quaternion to Euler angles (pitch and roll)
        // This is a simplified conversion - for more accuracy, you might want to use more complex math
        
        let qw = quaternion.w
        let qx = quaternion.x
        let qy = quaternion.y
        let qz = quaternion.z
        
        // Roll (x-axis rotation)
        let sinr_cosp = 2 * (qw * qx + qy * qz)
        let cosr_cosp = 1 - 2 * (qx * qx + qy * qy)
        let roll = atan2(sinr_cosp, cosr_cosp)
        
        // Pitch (y-axis rotation)
        let sinp = 2 * (qw * qy - qz * qx)
        let pitch: Double
        if abs(sinp) >= 1 {
            pitch = copysign(.pi / 2, sinp) // use 90 degrees if out of range
        } else {
            pitch = asin(sinp)
        }
        
        // Convert to degrees
        let pitchDegrees = pitch * 180 / .pi
        let rollDegrees = roll * 180 / .pi
        
        return (pitch: pitchDegrees, roll: rollDegrees)
    }
    
    // Helper function to normalize angles to [-180, 180] range
    private func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle
        while normalized > 180 {
            normalized -= 360
        }
        while normalized < -180 {
            normalized += 360
        }
        return normalized
    }
    
    // MainActor method for cleanup
    private func cleanupMotionManager() {
        motionManager?.stopDeviceMotionUpdates()
        timer?.invalidate()
        timer = nil
    }
} 
