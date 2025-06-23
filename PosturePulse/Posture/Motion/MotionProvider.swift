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
            
            self.motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
                guard !hasResumed else { return }
                hasResumed = true
                
                self.motionManager.stopDeviceMotionUpdates()
                
                if let error = error {
                    print("🔔 AirPodsMotionProvider - Motion error: \(error)")
                    continuation.resume(returning: false)
                    return
                }
                
                if let motion = motion {
                    // Check if we have AirPods data by looking for gravity data
                    if motion.gravity.x != 0 || motion.gravity.y != 0 || motion.gravity.z != 0 {
                        print("🔔 AirPodsMotionProvider - AirPods motion data available")
                        continuation.resume(returning: true)
                    } else {
                        print("🔔 AirPodsMotionProvider - No AirPods motion data available")
                        continuation.resume(returning: false)
                    }
                } else {
                    print("🔔 AirPodsMotionProvider - No motion data")
                    continuation.resume(returning: false)
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
                print("🔔 AirPodsMotionProvider - Motion error: \(error)")
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
        print("🔔 AirPodsMotionProvider - Headphones connected")
        isConnected = true
    }
    
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        print("🔔 AirPodsMotionProvider - Headphones disconnected")
        isConnected = false
    }
} 