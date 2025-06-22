import SwiftUI
import SwiftData

struct IntervalSliderView: View {
    let label: String
    @Binding var minutes: Int
    let quickOptions: [Int]
    let context: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(label)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(minutes) min")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Slider(value: Binding(
                get: { Double(minutes) },
                set: { 
                    minutes = Int($0)
                    try? context.save()
                }
            ), in: 5...90, step: 1)
            .tint(Color(red: 0.2, green: 0.4, blue: 0.9))

            HStack(spacing: 12) {
                ForEach(quickOptions, id: \.self) { option in
                    Button("\(option) min") {
                        minutes = option
                        try? context.save()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(minutes == option ? .white : .gray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(minutes == option ? Color.accentColor.opacity(0.4) : Color.black.opacity(0.2))
                    .cornerRadius(8)
                    .font(.caption)
                }
            }
        }
    }
} 