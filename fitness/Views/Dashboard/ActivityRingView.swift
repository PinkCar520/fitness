import SwiftUI

struct ActivityRingView: View {
    var progress: Double
    var color: Color
    var ringSize: CGFloat = 60

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: ringSize * 0.15)
            Circle()
                .trim(from: 0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(color, style: StrokeStyle(lineWidth: ringSize * 0.15, lineCap: .round))
                .rotationEffect(Angle(degrees: -90))
        }
        .frame(width: ringSize, height: ringSize)
    }
}
