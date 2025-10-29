import SwiftUI
import SwiftData

struct PlanHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @Query(filter: #Predicate<Plan> { $0.status == "archived" }, sort: \.startDate, order: .reverse)
    private var archivedPlans: [Plan]

    var body: some View {
        NavigationStack {
            List {
                if archivedPlans.isEmpty {
                    ContentUnavailableView("暂无历史计划", systemImage: "archivebox")
                } else {
                    ForEach(archivedPlans) { plan in
                        NavigationLink(destination: PlanDetailView(plan: plan)) { // PlanDetailView will be created later
                            VStack(alignment: .leading) {
                                Text(plan.name)
                                    .font(.headline)
                                Text("\(plan.startDate.formatted(date: .abbreviated, time: .omitted)) - \(plan.endDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("历史计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PlanHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock container for previews
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Plan.self, configurations: config)
        
        // Add some mock archived plans
        let planGoal1 = PlanGoal(
            fitnessGoal: .fatLoss,
            startWeight: 75.0,
            targetWeight: 68.0,
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
            targetDate: Calendar.current.date(byAdding: .day, value: 30, to: Calendar.current.date(byAdding: .month, value: -2, to: Date())!)
        )
        let planGoal2 = PlanGoal(
            fitnessGoal: .muscleGain,
            startWeight: 68.0,
            targetWeight: 72.0,
            startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
            targetDate: Calendar.current.date(byAdding: .day, value: 14, to: Calendar.current.date(byAdding: .month, value: -1, to: Date())!)
        )

        let mockPlan1 = Plan(name: "30天减脂计划", planGoal: planGoal1, startDate: planGoal1.startDate, duration: 30, tasks: [], status: "archived")
        let mockPlan2 = Plan(name: "14天增肌计划", planGoal: planGoal2, startDate: planGoal2.startDate, duration: 14, tasks: [], status: "archived")
        
        container.mainContext.insert(mockPlan1)
        container.mainContext.insert(mockPlan2)

        return PlanHistoryView()
            .modelContainer(container)
    }
}
