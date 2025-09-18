import SwiftUI

import SwiftUI
import SwiftData

// MARK: - Main View: The Storybook
struct HistoryListView: View {
    @EnvironmentObject var weightManager: WeightManager
    @State private var currentPageIndex = 0
    
    @Query(sort: \HealthMetric.date, order: .forward) private var allMetrics: [HealthMetric]

    private var weightMetrics: [HealthMetric] {
        allMetrics.filter { $0.type == .weight }
    }

    // Group records by the first day of their month to create "chapters" or "pages"
    private var pages: [(month: Date, records: [HealthMetric])] {
        let grouped = Dictionary(grouping: weightMetrics) { $0.date.startOfMonth }
        return grouped.sorted { $0.key > $1.key }.map { ($0.key, $0.value.sorted(by: { $0.date > $1.date })) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if pages.isEmpty {
                emptyStateView
            } else {
                titleHeader
                
                TabView(selection: $currentPageIndex) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, pageData in
                        MonthlyPageView(records: pageData.records)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            }
        }
        .aspectRatio(1/1, contentMode: .fit)
        .background(Color(hue: 0.12, saturation: 0.1, brightness: 0.97)) // Use a warm, paper-like beige
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var titleHeader: some View {
        VStack {
            Text("成长的足迹")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.top, 16)
            
            Text(pages[currentPageIndex].month.formatted(.dateTime.year().month()))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .animation(.easeInOut, value: currentPageIndex)
                .padding(.bottom, 8)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("你的第一页，正等待着被书写。")
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - A Single Page in the Book (for one month)
struct MonthlyPageView: View {
    let records: [HealthMetric]
    
    var body: some View {
        // 2. The ScrollView now has its own background, acting as a single "page"
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(records) { record in
                    HistoryRowView(record: record)
                }
            }
            .padding() // Padding for the content within the page
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24) // Padding to show the book's background behind the page
    }
}

// MARK: - A Single Entry on the Page (Read-Only)
struct HistoryRowView: View {
    @EnvironmentObject var weightManager: WeightManager
    let record: HealthMetric
    @State private var isDeleteAlertPresented = false

    var body: some View {
        HStack(spacing: 16) {
            Capsule()
                .fill(Color.accentColor.opacity(0.7))
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.date.formatted(.dateTime.day().weekday(.wide)))
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(record.date.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "%.1f kg", record.value))
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        // 3. Removed individual background and padding to blend into the page
        .padding(.vertical, 8)
        .contextMenu { // Deletion is kept as you approved.
            Button(role: .destructive) {
                isDeleteAlertPresented = true
            } label: {
                Label("删除记录", systemImage: "trash")
            }
        }
        .alert("删除记录?", isPresented: $isDeleteAlertPresented) {
            Button("删除", role: .destructive) {
                weightManager.delete(record)
            }
            Button("取消", role: .cancel) {}
        }
    }
}

// MARK: - Date Extension for Grouping
extension Date {
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
}
