import SwiftUI

struct SearchView: View {
    @EnvironmentObject var weightManager: WeightManager
    @Binding var selectedIndex: Int
    @Binding var searchText: String
    @State private var selectedActivityType: ActivityType = .all

    enum ActivityType: String, CaseIterable {
        case all = "全部"
        case weight = "体重"
        case running = "跑步"
        case swimming = "游泳"
    }

    var searchResults: [WeightRecord] {
        var records = weightManager.records

        if selectedActivityType == .weight {
            // This is a placeholder for when other activity types are added.
        } else if selectedActivityType != .all {
            return []
        }

        if searchText.isEmpty {
            return records
        } else {
            return records.filter { record in
                let weightMatch = String(record.weight).localizedCaseInsensitiveContains(searchText)
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
    let record: WeightRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(record.weight, specifier: "%.1f") kg")
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
