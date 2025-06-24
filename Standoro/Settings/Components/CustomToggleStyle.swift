import SwiftUI

struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .frame(width: 36, height: 20)
                    .foregroundColor(configuration.isOn ? Color.settingsAccentBlue : Color(red: 60/255, green: 62/255, blue: 66/255))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.settingsCardBorder, lineWidth: 1)
                    )
                Circle()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.white)
                    .offset(x: configuration.isOn ? 8 : -8)
                    .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
            }
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Toggle("Sample Toggle", isOn: .constant(true))
            .toggleStyle(CustomToggleStyle())
        
        Toggle("Another Toggle", isOn: .constant(false))
            .toggleStyle(CustomToggleStyle())
    }
    .padding()
    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
} 