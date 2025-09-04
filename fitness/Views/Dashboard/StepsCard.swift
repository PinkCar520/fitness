
import SwiftUI

struct StepsCard: View {
    let stepsData: [Double] = [100, 200, 150, 300, 250, 400, 350] // Sample data

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("步数")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "flame.fill")
                    .foregroundStyle(.purple)
            }

            Text("8,520")
                .font(.title)
                .fontWeight(.bold)

            Text("今天")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<stepsData.count, id: \.self) { i in
                    VStack {
                        Rectangle()
                            .fill(Color.purple.opacity(0.6))
                            .frame(height: stepsData[i] / 8)
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

struct StepsCard_Previews: PreviewProvider {
    static var previews: some View {
        StepsCard()
    }
}
