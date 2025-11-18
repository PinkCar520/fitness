
import SwiftUI
import SwiftData

struct CompletionView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var recommendationManager: RecommendationManager

    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "party.popper.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .padding(.bottom, 20)
            
            Text("设置完成！")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            Text("您的个性化健身计划已准备就绪。祝您健身愉快！")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .onAppear {
            // Generate and save the initial plan
            let planDuration = defaultPlanDuration
            let planGoal = buildPlanGoal(for: profileViewModel.userProfile, planDuration: planDuration)
            let generatedPlan = recommendationManager.generateInitialWorkoutPlan(
                userProfile: profileViewModel.userProfile,
                planGoal: planGoal,
                planDuration: planDuration
            )
            modelContext.insert(generatedPlan)
            profileViewModel.userProfile.hasCompletedOnboarding = true // Mark onboarding as complete
            // No need to save modelContext explicitly here, as it's often handled by the environment
        }
    }

    private var defaultPlanDuration: Int { 30 }

    private func buildPlanGoal(for profile: UserProfile, planDuration: Int) -> PlanGoal {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let targetDate = calendar.date(byAdding: .day, value: planDuration, to: startDate)
        let startWeight = profile.currentWeight ?? latestWeight() ?? profile.targetWeight
        let goal = profile.goal ?? .healthImprovement

        return PlanGoal(
            fitnessGoal: goal,
            startWeight: startWeight,
            targetWeight: profile.targetWeight,
            startDate: startDate,
            targetDate: targetDate
        )
    }

    private func latestWeight() -> Double? {
        var descriptor = FetchDescriptor<HealthMetric>(sortBy: [SortDescriptor(\HealthMetric.date, order: .reverse)])
        descriptor.fetchLimit = 20
        return try? modelContext.fetch(descriptor).first(where: { $0.type == .weight })?.value
    }
}

struct CompletionView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock data for preview
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Plan.self, DailyTask.self, Workout.self, Meal.self, HealthMetric.self, configurations: config)
        
        let mockProfileViewModel = ProfileViewModel()
        mockProfileViewModel.userProfile.name = "预览用户"
        mockProfileViewModel.userProfile.goal = .fatLoss
        mockProfileViewModel.userProfile.experienceLevel = .beginner
        mockProfileViewModel.userProfile.workoutLocation = .home
        mockProfileViewModel.userProfile.healthConditions = [.kneeDiscomfort]
        
        return CompletionView()
            .environmentObject(mockProfileViewModel)
            .environmentObject(RecommendationManager(profileViewModel: mockProfileViewModel))
            .modelContainer(container)
    }
}
