import SwiftUI
import SwiftData

struct SearchView: View {
    @Binding var selectedIndex: Int
    @Binding var searchText: String
    @State private var selectedActivityType: ActivityType = .all

    @Query(sort: \HealthMetric.date, order: .reverse) private var metrics: [HealthMetric]

    enum ActivityType: String, CaseIterable {
        case all = "全部"
        case weight = "体重"
        case running = "跑步"
        case swimming = "游泳"
    }

    var searchResults: [HealthMetric] {
        var filteredMetrics = metrics

        // Filter by activity type
        if selectedActivityType == .weight {
            filteredMetrics = metrics.filter { $0.type == .weight }
        } else if selectedActivityType != .all {
            return [] // Placeholder for other types
        }

        // Filter by search text
        if searchText.isEmpty {
            return filteredMetrics
        } else {
            return filteredMetrics.filter { metric in
                let weightMatch = String(metric.value).localizedCaseInsensitiveContains(searchText)
                // You could add date matching here as well if desired
                return weightMatch
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Filters
                activityTypeFilter

                // Search Results
                List(searchResults) { record in
                    WeightRow(record: record)
                }
                .listStyle(.plain)
            }
            .navigationTitle("搜索")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var activityTypeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(ActivityType.allCases, id: \.self) { type in
                    Button(action: {
                        selectedActivityType = type
                    }) {
                        Text(type.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedActivityType == type ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedActivityType == type ? .white : .primary)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
    }
}

struct WeightRow: View {
    let record: HealthMetric

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(record.value, specifier: "%.1f") kg")
                    .font(.headline)
                Text(record.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
