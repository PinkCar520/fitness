import SwiftUI

struct PlanView: View {
    var profileViewModel: ProfileViewModel
    @StateObject private var planViewModel: PlanViewModel

    init(profileViewModel: ProfileViewModel) {
        self.profileViewModel = profileViewModel
        _planViewModel = StateObject(wrappedValue: PlanViewModel(profileViewModel: profileViewModel))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    workoutPlanSection
                    mealPlanSection
                }
                .padding()
            }
            .navigationTitle("计划")
        }
    }

    private var workoutPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本周锻炼").font(.title2).bold()
            VStack(spacing: 12) {
                ForEach(planViewModel.workouts) { workout in
                    HStack {
                        Image(systemName: "figure.run.circle.fill")
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading) {
                            Text(workout.name)
                                .fontWeight(.bold)
                            Text("\(workout.durationInMinutes) 分钟 - \(workout.caloriesBurned) 卡路里")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(workout.date.shortDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }

    private var mealPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本周饮食").font(.title2).bold()
            VStack(spacing: 12) {
                ForEach(planViewModel.meals) { meal in
                    HStack {
                        Image(systemName: "leaf.circle.fill")
                            .foregroundColor(meal.mealType == .snack ? .orange : .green)
                        VStack(alignment: .leading) {
                            Text(meal.name)
                                .fontWeight(.bold)
                            Text("\(meal.calories) 卡路里 - \(meal.mealType.rawValue)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(meal.date.shortDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }
}

struct PlanView_Previews: PreviewProvider {
    static var previews: some View {
        PlanView(profileViewModel: ProfileViewModel())
            .environmentObject(ProfileViewModel())
    }
}