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
                    .foregroundColor(configuration.isOn ? Color.accentColor : Color.gray.opacity(0.5))
                
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