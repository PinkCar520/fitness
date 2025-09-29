
import SwiftUI

struct WelcomeView: View {

    var body: some View {
        ZStack {
            // Background layer with gradient and ignores safe area
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.accentColor.opacity(0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Content layer
            VStack {
                Spacer()
                
                Image(systemName: "figure.walk.motion")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 20)
                
                Text("欢迎使用 Fitness")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                Text("让我们开始为您量身定制健身计划，只需几个简单的步骤。")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure content VStack fills ZStack
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
