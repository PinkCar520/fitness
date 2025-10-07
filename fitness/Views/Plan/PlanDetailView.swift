import SwiftUI
import SwiftData

struct PlanDetailView: View {
    let plan: Plan

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(plan.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("目标: \(plan.goal)")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("时长: \(plan.duration) 天")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("开始日期: \(plan.startDate.formatted(date: .long, time: .omitted))")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Text("每日计划")
                    .font(.title)
                    .fontWeight(.bold)
                
                ForEach(plan.dailyTasks.sorted(by: { $0.date < $1.date })) { dailyTask in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(dailyTask.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.headline)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(8)
                        
                        if let workouts = try? JSONDecoder().decode([Workout].self, from: dailyTask.workoutsData ?? Data()) {
                            ForEach(workouts) { workout in
                                HStack {
                                    Image(systemName: "figure.run")
                                    Text(workout.name)
                                    Spacer()
                                    Text("\(workout.durationInMinutes) 分钟")
                                }
                                .font(.subheadline)
                            }
                        }
                        
                        if let meals = try? JSONDecoder().decode([Meal].self, from: dailyTask.mealsData ?? Data()) {
                            ForEach(meals) { meal in
                                HStack {
                                    Image(systemName: "fork.knife")
                                    Text(meal.name)
                                    Spacer()
                                    Text("\(meal.calories) 卡路里")
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("计划详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PlanDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Plan.self, configurations: config)
        
        let mockPlan = Plan(name: "30天减脂计划", goal: .fatLoss, startDate: Date(), duration: 30, tasks: [], status: "active")
        
        let workout1 = Workout(name: "胸部训练", durationInMinutes: 60, caloriesBurned: 400, date: Date())
        let meal1 = Meal(name: "鸡胸肉沙拉", calories: 350, date: Date(), mealType: .lunch) // Use .lunch
        let dailyTask1 = DailyTask(date: Date(), workouts: [workout1], meals: [meal1])
        
        let workout2 = Workout(name: "腿部训练", durationInMinutes: 75, caloriesBurned: 500, date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!) // Use .day
        let meal2 = Meal(name: "三文鱼蔬菜", calories: 450, date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, mealType: .dinner) // Use .dinner
        let dailyTask2 = DailyTask(date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, workouts: [workout2], meals: [meal2])
        
        mockPlan.dailyTasks.append(dailyTask1)
        mockPlan.dailyTasks.append(dailyTask2)
        
        container.mainContext.insert(mockPlan)

        return NavigationStack {
            PlanDetailView(plan: mockPlan)
        }
        .modelContainer(container)
    }
}
