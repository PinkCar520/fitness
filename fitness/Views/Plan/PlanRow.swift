import SwiftUI

struct PlanRow: View {
    let name: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            Text(name).font(.headline)
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
            Text("\(Int(progress * 100))% 完成")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
