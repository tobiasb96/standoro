import Foundation
import AVFoundation
import Combine
import AppKit

enum SoundType {
    case challengeAppear
    case challengeComplete
    case challengeDiscard
    case workoutComplete
    case notification
    case success
    case error
}

/// Handles audio feedback for the app
@MainActor
class AudioService: ObservableObject {
    
    private let soundMap: [SoundType: String] = [
        .challengeAppear: "Glass",
        .challengeComplete: "Ping",
        .challengeDiscard: "Basso",
        .workoutComplete: "Ping",
        .notification: "Glass",
        .success: "Ping",
        .error: "Basso"
    ]
    
    init() {
        // No need for AVAudioSession setup on macOS
        // System sounds work directly without session configuration
    }
    
    func playSound(_ type: SoundType) {
        guard let soundName = soundMap[type] else { 
            print("🔊 AudioService - No sound found for type: \(type)")
            return 
        }        
        if let sound = NSSound(named: soundName) {
            sound.play()
        } else {
            AudioServicesPlaySystemSound(1000)
        }
    }
} 
