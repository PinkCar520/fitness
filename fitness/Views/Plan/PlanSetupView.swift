import SwiftUI


struct PlanSetupView: View {
    @Environment(\.dismiss) var dismiss
    
    // State for user's selections
    @State private var selectedGoal: FitnessGoal = .fatLoss
    @State private var planDuration: Double = 30

    // Callback to pass data back
    var onStartPlan: (FitnessGoal, Int) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("选择你的主要目标")) {
                    Picker("主要目标", selection: $selectedGoal) {
                        ForEach(FitnessGoal.allCases) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("设定计划时长（天）")) {
                    VStack {
                        Slider(value: $planDuration, in: 7...90, step: 1)
                        Text("\(Int(planDuration)) 天")
                            .font(.headline)
                            .padding(.top, 8)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("制定新计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("开始计划") {
                        // Call the callback with the selected data
                        onStartPlan(selectedGoal, Int(planDuration))
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

struct PlanSetupView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a dummy closure for the preview
        PlanSetupView { goal, duration in
            print("Preview: Starting a new \(duration)-day plan with goal: \(goal.rawValue)")
        }
    }
}
