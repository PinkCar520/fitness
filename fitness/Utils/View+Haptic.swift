import SwiftUI

struct HapticOnChangeModifier<V: Equatable>: ViewModifier {
    let value: V
    @State private var isFirstChange = true

    func body(content: Content) -> some View {
        content
            .onChange(of: value) {
                if isFirstChange {
                    isFirstChange = false
                    return
                }
                triggerFlippingHaptics()
            }
    }
    
    private func triggerFlippingHaptics() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        let duration = 0.3
        let interval = 0.05
        let steps = Int(duration / interval)
        
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                generator.impactOccurred(intensity: 0.8)
            }
        }
    }
}

extension View {
    func hapticOnChange<V: Equatable>(of value: V) -> some View {
        self.modifier(HapticOnChangeModifier(value: value))
    }
}
