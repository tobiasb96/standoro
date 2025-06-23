import SwiftUI

struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .foregroundColor(.white)
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .frame(width: 50, height: 30)
                    .foregroundColor(configuration.isOn ? Color(red: 0.2, green: 0.4, blue: 0.9) : Color(red: 0.16, green: 0.16, blue: 0.18))
                
                Circle()
                    .frame(width: 26, height: 26)
                    .foregroundColor(.white)
                    .offset(x: configuration.isOn ? 10 : -10)
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