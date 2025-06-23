import SwiftUI
import SwiftData

struct IntervalSliderView: View {
    let label: String
    @Binding var minutes: Int
    let quickOptions: [Int]
    let context: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(label)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(minutes) min")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.2, green: 0.4, blue: 0.9))
                    .cornerRadius(10)
            }
            
            Slider(value: Binding(
                get: { Double(minutes) },
                set: { 
                    minutes = Int($0)
                    try? context.save()
                }
            ), in: 5...90, step: 1)
            .tint(Color(red: 0.2, green: 0.4, blue: 0.9))
            .controlSize(.large)

            HStack(spacing: 8) {
                ForEach(quickOptions, id: \.self) { option in
                    Button("\(option) min") {
                        minutes = option
                        try? context.save()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(minutes == option ? .white : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(minutes == option ? Color(red: 0.2, green: 0.4, blue: 0.9) : Color(red: 0.16, green: 0.16, blue: 0.18))
                    .cornerRadius(8)
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
            }
        }
    }
}

#Preview {
    IntervalSliderView(
        label: "Minutes",
        minutes: .constant(15),
        quickOptions: [5, 10, 15, 20],
        context: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext
    )
    .background(Color(red: 0.0, green: 0.2, blue: 0.6))
    .padding()
} 