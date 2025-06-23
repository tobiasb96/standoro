import Foundation
import CoreMotion
import Combine

/// Protocol for motion data providers
protocol MotionProvider: AnyObject {
    var isAvailable: Bool { get }
    var isConnected: Bool { get }
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
    
    private let motionManager = CMHeadphoneMotionManager()
    private let motionDataSubject = PassthroughSubject<MotionData, Never>()
    
    var motionDataPublisher: AnyPublisher<MotionData, Never> {
        motionDataSubject.eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        motionManager.delegate = self
        checkAvailability()
    }
    
    func requestAccess() async -> Bool {
        guard motionManager.isDeviceMotionAvailable else {
            return false
        }
        
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            let resumeOnce = { (result: Bool) in
                guard !hasResumed else { return }
                hasResumed = true
                self.motionManager.stopDeviceMotionUpdates()
                continuation.resume(returning: result)
            }
            
            // Timeout task
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                if !hasResumed {
                    print("🔔 AirPodsMotionProvider - requestAccess timed out.")
                    resumeOnce(false)
                }
            }
            
            // Motion updates
            self.motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
                if let error = error {
                    print("🔔 AirPodsMotionProvider - Motion access error: \(error.localizedDescription)")
                    resumeOnce(false)
                    return
                }
                
                if let motion = motion {
                    // Check for actual motion data to confirm connection
                    if motion.gravity.x != 0 || motion.gravity.y != 0 || motion.gravity.z != 0 {
                        print("🔔 AirPodsMotionProvider - Motion data available, access granted.")
                        resumeOnce(true)
                    } else {
                        // This can happen if updates start but there's no data (e.g., not AirPods Pro/Max)
                        print("🔔 AirPodsMotionProvider - Motion data received but gravity is zero, likely not supported.")
                        resumeOnce(false)
                    }
                } else {
                    // This case should ideally not be reached if error is nil, but handled for safety
                    print("🔔 AirPodsMotionProvider - No motion data received.")
                    resumeOnce(false)
                }
            }
        }
    }
    
    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("🔔 AirPodsMotionProvider - Device motion not available")
            return
        }
        
        print("🔔 AirPodsMotionProvider - Starting motion updates")
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            if let error = error {
                print("🔔 AirPodsMotionProvider - Motion update error: \(error.localizedDescription)")
                return
            }
            
            if let motion = motion {
                let motionData = MotionData(from: motion)
                self?.motionDataSubject.send(motionData)
            }
        }
    }
    
    func stopUpdates() {
        print("🔔 AirPodsMotionProvider - Stopping motion updates")
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func checkAvailability() {
        isAvailable = motionManager.isDeviceMotionAvailable
    }
    
    // MARK: - CMHeadphoneMotionManagerDelegate
    
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        print("🔔 AirPodsMotionProvider - Headphones connected.")
        isConnected = true
    }
    
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        print("🔔 AirPodsMotionProvider - Headphones disconnected.")
        isConnected = false
    }
} 