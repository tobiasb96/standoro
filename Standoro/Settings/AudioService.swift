import Foundation
import AVFoundation
import Combine
import AppKit

enum SoundType: String, CaseIterable {
    case challengeAppear = "challenge_appear"
    case challengeComplete = "challenge_complete"
    case challengeDiscard = "challenge_discard"
    case workoutComplete
    case notification
    case success
    case error
}

/// Handles audio feedback for the app
@MainActor
class AudioService: ObservableObject {
    
    private var audioPlayers: [SoundType: AVAudioPlayer] = [:]
    private var isEnabled = true
    
    init() {
        loadSounds()
    }
    
    private func loadSounds() {
        for soundType in SoundType.allCases {
            if let url = Bundle.main.url(forResource: soundType.rawValue, withExtension: "wav") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    audioPlayers[soundType] = player
                } catch {
                    #if DEBUG
                    print("AudioService: Failed to load sound \(soundType.rawValue): \(error)")
                    #endif
                }
            } else {
                #if DEBUG
                print("AudioService: No sound found for type: \(soundType)")
                #endif
            }
        }
    }
    
    func playSound(_ type: SoundType) {
        guard isEnabled else { return }
        
        if let player = audioPlayers[type] {
            player.currentTime = 0
            player.play()
        }
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    func isSoundEnabled() -> Bool {
        return isEnabled
    }
} 
