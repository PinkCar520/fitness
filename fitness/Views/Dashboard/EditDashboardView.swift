import SwiftUI
import SwiftData // Add this

struct EditDashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Section for visible, reorderable cards
                Section(header: Text("当前卡片")) {
                    ForEach(viewModel.visibleCards) { card in
                        HStack {
                            Button(action: { viewModel.toggleVisibility(for: card) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text(card.name)
                            
                            Spacer()
                        }
                    }
                    .onMove(perform: viewModel.moveCard)
                }

                // Section for hidden cards that can be added
                Section(header: Text("其他类别")) {
                    ForEach(viewModel.hiddenCards) { card in
                        HStack {
                            Button(action: { viewModel.toggleVisibility(for: card) }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text(card.name)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("编辑卡片")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.editMode, .constant(.active)) // Enable edit mode for reordering
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
    }
}

struct EditDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: HealthMetric.self, configurations: config)
        let healthKitManager = HealthKitManager()
        let weightManager = WeightManager(healthKitManager: healthKitManager, modelContainer: container)

        EditDashboardView()
            .environmentObject(DashboardViewModel(healthKitManager: healthKitManager, weightManager: weightManager))
            .modelContainer(container) // Add modelContainer for SwiftData context
    }
}