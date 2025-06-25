import Foundation
import CoreMotion
import Combine

/// Protocol for motion data providers
protocol MotionProvider: AnyObject {
    var isAvailable: Bool { get }
    var isConnected: Bool { get }
    var isReceivingData: Bool { get }
    var motionDataPublisher: AnyPublisher<MotionData, Never> { get }
    
    func requestAccess() async -> Bool
    func startUpdates()
    func stopUpdates()
}

/// AirPods-specific motion provider
@MainActor
class AirPodsMotionProvider: NSObject, MotionProvider, CMHeadphoneMotionManagerDelegate {
    @Published private(set) var isAvailable = false
    @Published private(set) var isConnected = false
    @Published private(set) var isReceivingData = false
    
    private let motionManager = CMHeadphoneMotionManager()
    private let motionDataSubject = PassthroughSubject<MotionData, Never>()
    
    // Data availability tracking
    private var lastDataReceivedTime: Date?
    private var dataTimeoutInterval: TimeInterval = 2.0 // Consider data stale after 2 seconds
    private var dataCheckTimer: Timer?
    
    // Prevent multiple simultaneous access requests
    private var isRequestingAccess = false
    
    var motionDataPublisher: AnyPublisher<MotionData, Never> {
        motionDataSubject.eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        motionManager.delegate = self
        checkAvailability()
        startDataAvailabilityMonitoring()
    }
    
    deinit {
        dataCheckTimer?.invalidate()
    }
    
    func requestAccess() async -> Bool {
        // Prevent multiple simultaneous requests
        if isRequestingAccess {
            return false
        }
        
        guard motionManager.isDeviceMotionAvailable else {
            return false
        }
        
        isRequestingAccess = true
        defer { isRequestingAccess = false }
        
        // Return true immediately if the system supports AirPods motion
        // The actual device connection and data availability will be handled separately
        return true
    }
    
    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            return
        }
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            if let error = error {
                self?.updateDataAvailability(false)
                return
            }
            
            if let motion = motion {
                // Check if we're getting meaningful data
                let hasValidData = motion.gravity.x != 0 || motion.gravity.y != 0 || motion.gravity.z != 0
                self?.updateDataAvailability(hasValidData)
                
                if hasValidData {
                    let motionData = MotionData(from: motion)
                    self?.motionDataSubject.send(motionData)
                }
            } else {
                self?.updateDataAvailability(false)
            }
        }
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
        updateDataAvailability(false)
    }
    
    private func updateDataAvailability(_ receiving: Bool) {
        if receiving {
            lastDataReceivedTime = Date()
        }
        
        if isReceivingData != receiving {
            isReceivingData = receiving
        }
    }
    
    private func checkAvailability() {
        let newAvailability = motionManager.isDeviceMotionAvailable
        if isAvailable != newAvailability {
            isAvailable = newAvailability
        }
    }
    
    private func startDataAvailabilityMonitoring() {
        dataCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkDataTimeout()
            }
        }
    }
    
    private func checkDataTimeout() {
        guard let lastDataTime = lastDataReceivedTime else {
            // No data ever received
            updateDataAvailability(false)
            return
        }
        
        let timeSinceLastData = Date().timeIntervalSince(lastDataTime)
        if timeSinceLastData > dataTimeoutInterval {
            updateDataAvailability(false)
        }
    }
    
    // MARK: - CMHeadphoneMotionManagerDelegate
    
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        isConnected = true
        checkAvailability() // Re-check availability when connection changes
    }
    
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        isConnected = false
        updateDataAvailability(false)
        checkAvailability() // Re-check availability when connection changes
    }
} 