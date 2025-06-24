import Foundation
import CoreMotion

/// Represents motion data from any provider in a unified format
struct MotionData {
    let timestamp: Date
    let pitch: Double
    let roll: Double
    let yaw: Double
    let acceleration: CMAcceleration
    let gravity: CMAcceleration
    let rotationRate: CMRotationRate
    
    init(from deviceMotion: CMDeviceMotion) {
        self.timestamp = Date()
        self.acceleration = deviceMotion.userAcceleration
        self.gravity = deviceMotion.gravity
        self.rotationRate = deviceMotion.rotationRate
        
        // Convert quaternion to Euler angles
        let (pitch, roll, yaw) = Self.quaternionToEulerAngles(deviceMotion.attitude.quaternion)
        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw
    }
    
    // Helper function to normalize angles to [-180, 180] range
    static func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle
        while normalized > 180 {
            normalized -= 360
        }
        while normalized < -180 {
            normalized += 360
        }
        return normalized
    }
    
    // Convert quaternion to Euler angles
    private static func quaternionToEulerAngles(_ quaternion: CMQuaternion) -> (pitch: Double, roll: Double, yaw: Double) {
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
            pitch = copysign(.pi / 2, sinp)
        } else {
            pitch = asin(sinp)
        }
        
        // Yaw (z-axis rotation)
        let siny_cosp = 2 * (qw * qz + qx * qy)
        let cosy_cosp = 1 - 2 * (qy * qy + qz * qz)
        let yaw = atan2(siny_cosp, cosy_cosp)
        
        // Convert to degrees
        let pitchDegrees = pitch * 180 / .pi
        let rollDegrees = roll * 180 / .pi
        let yawDegrees = yaw * 180 / .pi
        
        return (pitch: pitchDegrees, roll: rollDegrees, yaw: yawDegrees)
    }
} 