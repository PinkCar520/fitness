
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
            let generatedPlan = recommendationManager.generateInitialWorkoutPlan(userProfile: profileViewModel.userProfile)
            modelContext.insert(generatedPlan)
            profileViewModel.userProfile.hasCompletedOnboarding = true // Mark onboarding as complete
            // No need to save modelContext explicitly here, as it's often handled by the environment
        }
    }
}

struct CompletionView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock data for preview
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Plan.self, configurations: config)
        
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
