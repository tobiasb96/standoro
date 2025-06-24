import Foundation

/// Base class for motion analyzers with common update frequency control
@MainActor
class BaseAnalyzer {
    // Update frequency control
    var updateFrequency: TimeInterval = 5.0
    var lastUpdateTime = Date()
    var isHighFrequencyMode = false
    
    func setUpdateFrequency(_ frequency: TimeInterval) {
        updateFrequency = frequency
    }
    
    func enableHighFrequencyMode() {
        isHighFrequencyMode = true
        updateFrequency = 1.0
    }
    
    func disableHighFrequencyMode() {
        isHighFrequencyMode = false
        updateFrequency = 5.0
    }
    
    /// Check if enough time has passed since last update
    func shouldUpdate() -> Bool {
        let now = Date()
        if now.timeIntervalSince(lastUpdateTime) < updateFrequency {
            return false
        }
        lastUpdateTime = now
        return true
    }
} 
