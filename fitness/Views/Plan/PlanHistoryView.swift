import SwiftUI
import SwiftData

struct PlanHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Plan> { $0.status == "archived" }, sort: \.startDate, order: .reverse)
    private var archivedPlans: [Plan]
    @State private var planPendingDeletion: Plan?
    @State private var isDeleteAlertPresented = false
    
    var body: some View {
        NavigationStack {
            List {
                historyRows
            }
            .scrollContentBackground(.hidden)
            .alert("删除历史计划?", isPresented: $isDeleteAlertPresented, presenting: planPendingDeletion) { plan in
                Button("删除", role: .destructive) {
                    deletePlan(plan)
                }
                Button("取消", role: .cancel) {
                    planPendingDeletion = nil
                }
            } message: { plan in
                Text("\"\(plan.name)\"将被永久删除，包含的每日任务也会一并移除。")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                }
            }
            .toolbar(removing: .title)
        }
        .presentationDetents([.fraction(0.9)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
    }
    
    @ViewBuilder
    private var historyRows: some View {
        if archivedPlans.isEmpty {
            emptyHistoryRow
        } else {
            planHistoryRows
        }
    }
    
    private var planHistoryRows: some View {
        ForEach(archivedPlans) { plan in
            NavigationLink(destination: PlanDetailView(plan: plan)) {
                historyCard(for: plan)
            }
            .listRowInsets(.init(top: 0, leading: 6, bottom: 6, trailing: 18))
            .listRowSeparator(.hidden)
        }
        .onDelete(perform: prepareDeletion)
    }
    
    private var emptyHistoryRow: some View {
        VStack(spacing: 12) {
            Image(systemName: "archivebox")
                .font(.system(size: 48, weight: .semibold))
                .symbolVariant(.fill)
                .foregroundStyle(.secondary)
            
            Text("暂无历史计划")
                .font(.headline)
            
            Text("创建并归档计划后，你可以在此查看过往的训练记录。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .listRowInsets(.init(top: 20, leading: 0, bottom: 20, trailing: 18))
        .listRowSeparator(.hidden)
    }
    
    private func historyCard(for plan: Plan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(plan.name)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(dateRangeText(for: plan))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    
    private func dateRangeText(for plan: Plan) -> String {
        let start = plan.startDate.formatted(date: .abbreviated, time: .omitted)
        let end = plan.endDate.formatted(date: .abbreviated, time: .omitted)
        return "\(start) - \(end)"
    }
    
    private func prepareDeletion(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        planPendingDeletion = archivedPlans[index]
        isDeleteAlertPresented = true
    }
    
    private func deletePlan(_ plan: Plan) {
        modelContext.delete(plan)
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to delete plan: \(error.localizedDescription)")
        }
        planPendingDeletion = nil
    }
}

struct PlanHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Plan.self, configurations: config)
        
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
