import SwiftUI

struct ChallengeCard: View {
    let challenge: Challenge
    let onStart: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon and category
            HStack {
                Image(systemName: challenge.icon)
                    .font(.title2)
                    .foregroundColor(challenge.category.color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text(challenge.category.rawValue)
                            .font(.caption)
                            .foregroundColor(challenge.category.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(challenge.category.color.opacity(0.2))
                            .cornerRadius(4)
                        
                        Text(challenge.difficulty.rawValue)
                            .font(.caption)
                            .foregroundColor(challenge.difficulty.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(challenge.difficulty.color.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // Duration indicator
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(challenge.duration))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Description
            Text(challenge.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Instructions preview
            if !challenge.instructions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Instructions:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                    
                    Text(challenge.instructions.prefix(2).joined(separator: " • "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // Start button
            Button(action: onStart) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.caption)
                    Text("Start Challenge")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(challenge.category.color)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(Color(red: 0.16, green: 0.16, blue: 0.18))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(challenge.category.color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        ChallengeCard(
            challenge: Challenge.allChallenges[0],
            onStart: {}
        )
        
        ChallengeCard(
            challenge: Challenge.allChallenges[2],
            onStart: {}
        )
    }
    .padding()
    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
} 