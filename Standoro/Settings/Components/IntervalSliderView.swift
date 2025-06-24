import SwiftUI
import SwiftData

struct IntervalSliderView: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    let quickOptions: [Int]
    let context: ModelContext
    
    init(label: String, value: Binding<Int>, range: ClosedRange<Int>, unit: String, quickOptions: [Int], context: ModelContext) {
        self.label = label
        self._value = value
        self.range = range
        self.unit = unit
        self.quickOptions = quickOptions
        self.context = context
    }
    
    // Convenience initializer for backward compatibility
    init(label: String, minutes: Binding<Int>, quickOptions: [Int], context: ModelContext) {
        self.label = label
        self._value = minutes
        self.range = 5...90
        self.unit = "min"
        self.quickOptions = quickOptions
        self.context = context
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
            Slider(value: Binding(
                get: { Double(value) },
                set: { 
                    value = Int($0)
                    try? context.save()
                }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
            .tint(Color(red: 0.4, green: 0.6, blue: 0.4))
            .controlSize(.regular)
            Spacer(minLength: 20)
            Text("\(value) \(unit)")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(red: 0.4, green: 0.6, blue: 0.4))
                .cornerRadius(8)
            }
            


            HStack(spacing: 6) {
                ForEach(quickOptions, id: \.self) { option in
                    Button("\(option)") {
                        value = option
                        try? context.save()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(value == option ? .white : .secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(value == option ? Color(red: 0.4, green: 0.6, blue: 0.4) : Color(red: 0.16, green: 0.16, blue: 0.18))
                    .cornerRadius(6)
                    .font(.caption)
                    .fontWeight(.medium)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        IntervalSliderView(
            label: "Focus Interval",
            value: .constant(25),
            range: 5...90,
            unit: "min",
            quickOptions: [20, 25, 30, 45],
            context: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext
        )
        
        IntervalSliderView(
            label: "Short Break",
            value: .constant(5),
            range: 3...30,
            unit: "min",
            quickOptions: [3, 5, 7, 10],
            context: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext
        )
        
        IntervalSliderView(
            label: "Long Break Frequency",
            value: .constant(4),
            range: 2...8,
            unit: "sessions",
            quickOptions: [3, 4, 5, 6],
            context: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext
        )
    }
    .background(Color(red: 0.0, green: 0.2, blue: 0.6))
    .padding()
} 