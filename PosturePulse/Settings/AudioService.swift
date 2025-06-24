import Foundation
import AVFoundation

/// Handles audio feedback for the app
@MainActor
class AudioService: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    
    init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("🔊 AudioService - Failed to setup audio session: \(error)")
        }
    }
    
    /// Play a challenge notification sound
    func playChallengeSound() {
        // Use a distinctive system sound for challenge notifications
        AudioServicesPlaySystemSound(1008) // System notification sound with a different tone
    }
    
    /// Play a completion sound when challenge is completed
    func playCompletionSound() {
        AudioServicesPlaySystemSound(1322) // Success sound
    }
    
    /// Play a discard sound when challenge is discarded
    func playDiscardSound() {
        AudioServicesPlaySystemSound(1006) // Cancel sound
    }
} 