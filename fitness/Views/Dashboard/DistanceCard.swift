
import SwiftUI

struct DistanceCard: View {
    let distanceData: [Double] = [1.0, 2.0, 1.5, 3.0, 2.5, 4.0, 3.5] // Sample data

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("步行距离")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "figure.walk")
                    .foregroundStyle(.cyan)
            }

            Text("2.15")
                .font(.title)
                .fontWeight(.bold)

            Text("公里")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<distanceData.count, id: \.self) { i in
                    VStack {
                        Rectangle()
                            .fill(Color.cyan.opacity(0.6))
                            .frame(height: distanceData[i] * 10)
                            .cornerRadius(4)
                    }
                }
            }
            .frame(height: 50)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct DistanceCard_Previews: PreviewProvider {
    static var previews: some View {
        DistanceCard()
    }
}
