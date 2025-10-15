import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 35)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text(unit)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 16, leading: 12, bottom: 12, trailing: 12))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}
