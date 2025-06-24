import Foundation
import SwiftUI

enum ChallengeCategory: String, CaseIterable {
    case balance = "Balance"
    case strength = "Strength"
    case flexibility = "Flexibility"
    case cardio = "Cardio"
    case mindfulness = "Mindfulness"
    
    var icon: String {
        switch self {
        case .balance:
            return "figure.stand"
        case .strength:
            return "dumbbell.fill"
        case .flexibility:
            return "figure.flexibility"
        case .cardio:
            return "heart.fill"
        case .mindfulness:
            return "brain.head.profile"
        }
    }
    
    var color: Color {
        switch self {
        case .balance:
            return .blue
        case .strength:
            return .orange
        case .flexibility:
            return .purple
        case .cardio:
            return .red
        case .mindfulness:
            return .green
        }
    }
}

struct Challenge: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: ChallengeCategory
    let duration: TimeInterval
    let difficulty: ChallengeDifficulty
    let icon: String
    let instructions: [String]
    
    enum ChallengeDifficulty: String, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        
        var color: Color {
            switch self {
            case .easy:
                return .green
            case .medium:
                return .orange
            case .hard:
                return .red
            }
        }
    }
}

// Predefined challenges
extension Challenge {
    static let allChallenges: [Challenge] = [
        // Balance challenges
        Challenge(
            title: "Stand on One Leg",
            description: "Improve your balance and core stability",
            category: .balance,
            duration: 30,
            difficulty: .easy,
            icon: "figure.stand",
            instructions: [
                "Stand with your feet shoulder-width apart",
                "Lift one foot off the ground",
                "Keep your balance for 30 seconds",
                "Switch legs and repeat"
            ]
        ),
        Challenge(
            title: "Tree Pose",
            description: "A classic yoga balance pose",
            category: .balance,
            duration: 45,
            difficulty: .medium,
            icon: "figure.yoga",
            instructions: [
                "Stand with feet together",
                "Place one foot on the opposite thigh",
                "Bring hands to prayer position",
                "Hold for 45 seconds"
            ]
        ),
        
        // Strength challenges
        Challenge(
            title: "10 Squats",
            description: "Build leg strength and endurance",
            category: .strength,
            duration: 60,
            difficulty: .easy,
            icon: "figure.strengthtraining.traditional",
            instructions: [
                "Stand with feet shoulder-width apart",
                "Lower your body as if sitting back",
                "Keep your knees behind your toes",
                "Perform 10 controlled squats"
            ]
        ),
        Challenge(
            title: "Wall Push-ups",
            description: "Upper body strength without equipment",
            category: .strength,
            duration: 90,
            difficulty: .medium,
            icon: "figure.strengthtraining.traditional",
            instructions: [
                "Stand facing a wall",
                "Place hands on wall at shoulder height",
                "Perform 15 push-ups",
                "Keep your body straight"
            ]
        ),
        
        // Flexibility challenges
        Challenge(
            title: "Shoulder Stretch",
            description: "Relieve tension in your shoulders",
            category: .flexibility,
            duration: 45,
            difficulty: .easy,
            icon: "figure.flexibility",
            instructions: [
                "Stand or sit comfortably",
                "Cross one arm across your chest",
                "Hold for 20 seconds",
                "Switch arms and repeat"
            ]
        ),
        Challenge(
            title: "Cat-Cow Stretch",
            description: "Gentle spine mobility exercise",
            category: .flexibility,
            duration: 60,
            difficulty: .easy,
            icon: "figure.flexibility",
            instructions: [
                "Start on hands and knees",
                "Arch your back (cow pose)",
                "Round your back (cat pose)",
                "Repeat for 1 minute"
            ]
        ),
        
        // Cardio challenges
        Challenge(
            title: "Jumping Jacks",
            description: "Get your heart rate up quickly",
            category: .cardio,
            duration: 60,
            difficulty: .medium,
            icon: "heart.fill",
            instructions: [
                "Stand with feet together",
                "Jump while raising arms overhead",
                "Land with feet apart",
                "Perform for 1 minute"
            ]
        ),
        Challenge(
            title: "High Knees",
            description: "Cardio exercise in place",
            category: .cardio,
            duration: 45,
            difficulty: .easy,
            icon: "heart.fill",
            instructions: [
                "Stand in place",
                "Lift knees to waist level",
                "Pump your arms",
                "Continue for 45 seconds"
            ]
        ),
        
        // Mindfulness challenges
        Challenge(
            title: "Deep Breathing",
            description: "Calm your mind and reduce stress",
            category: .mindfulness,
            duration: 120,
            difficulty: .easy,
            icon: "brain.head.profile",
            instructions: [
                "Sit comfortably with eyes closed",
                "Breathe in for 4 counts",
                "Hold for 4 counts",
                "Breathe out for 4 counts",
                "Repeat for 2 minutes"
            ]
        ),
        Challenge(
            title: "Body Scan",
            description: "Mindful awareness of your body",
            category: .mindfulness,
            duration: 180,
            difficulty: .medium,
            icon: "brain.head.profile",
            instructions: [
                "Lie down or sit comfortably",
                "Focus attention on your toes",
                "Slowly scan up your body",
                "Notice sensations without judgment",
                "Continue for 3 minutes"
            ]
        )
    ]
    
    static func challenges(for category: ChallengeCategory) -> [Challenge] {
        return allChallenges.filter { $0.category == category }
    }
} 