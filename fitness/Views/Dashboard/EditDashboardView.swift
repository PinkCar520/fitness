import SwiftUI
import SwiftData

struct EditDashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("当前卡片")) {
                    ForEach(viewModel.visibleCards) { card in
                        DraggableCardRow(card: card)
                            .id("visible_\(card.id)")
                    }
                    .onMove(perform: viewModel.moveCard)
                    .onDelete(perform: viewModel.deleteVisibleCard)
                    .id("visible_cards")
                }

                Section(header: Text("可添加的卡片")) {
                    ForEach(viewModel.hiddenCards) { card in
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            DraggableCardRow(card: card)
                        }
                        .id("hidden_\(card.id)")
                        .onTapGesture {
                            viewModel.toggleVisibility(for: card)
                        }
                    }
                    .id("hidden_cards")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle("编辑卡片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .animation(.default, value: viewModel.visibleCards)

        }
    }

}

// MARK: - Private Subviews

private struct DraggableCardRow: View {
    let card: DashboardCard

    var body: some View {
        HStack(spacing: 12) {
            icon(for: card.id)
                .font(.headline)
                .frame(width: 24, height: 24)
                .foregroundColor(.secondary)
            Text(card.name)
                .font(.headline)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func icon(for cardType: DashboardCard.CardType) -> some View {
        switch cardType {
        case .todaysWorkout:
            Image(systemName: "sun.max.fill")
        case .fitnessRings:
            Image(systemName: "circle.dashed.inset.filled")
        case .goalProgress:
            Image(systemName: "flag.checkered")
        case .stepsAndDistance:
            Image(systemName: "figure.walk")
        case .monthlyChallenge:
            Image(systemName: "trophy.fill")
        case .recentActivity:
            Image(systemName: "clock.fill")
        case .historyList:
            Image(systemName: "list.bullet")
        }
    }
}

// MARK: - Previews

struct EditDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        // This is a simplified setup for previewing purposes.
        // In a real app, the container and managers would be passed from the environment.
        let healthKitManager = HealthKitManager()
        let dashboardViewModel = DashboardViewModel(healthKitManager: healthKitManager, weightManager: WeightManager(healthKitManager: healthKitManager, modelContainer: try! ModelContainer(for: HealthMetric.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))))

        EditDashboardView()
            .environmentObject(dashboardViewModel)
    }
}
