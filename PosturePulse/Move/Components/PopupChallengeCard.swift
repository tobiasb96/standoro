import SwiftUI

struct PopupChallengeCard: View {
    let challenge: Challenge
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with icon and title
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
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(challenge.category.color.opacity(0.2))
                            .cornerRadius(4)
                        
                        Text("\(Int(challenge.duration))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Description
            Text(challenge.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            // Instructions (first 2 only)
            if !challenge.instructions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Instructions:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                    
                    ForEach(Array(challenge.instructions.prefix(2).enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: 6) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 16, alignment: .leading)
                            Text(instruction)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Complete button
            Button(action: onComplete) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline)
                    Text("Complete Challenge")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
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
    PopupChallengeCard(
        challenge: Challenge.allChallenges[0],
        onComplete: {}
    )
    .frame(width: 280)
    .padding()
    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
} 