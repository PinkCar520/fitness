
import Foundation
import Combine

class RecommendationManager: ObservableObject {
    @Published var recommendedContent: [String] = []

    private var profileViewModel: ProfileViewModel
    private var cancellables = Set<AnyCancellable>()

    init(profileViewModel: ProfileViewModel) {
        self.profileViewModel = profileViewModel
        setupSubscriptions()
        generateRecommendations()
    }

    private func setupSubscriptions() {
        profileViewModel.$userProfile
            .sink { [weak self] userProfile in
                self?.generateRecommendations()
            }
            .store(in: &cancellables)
    }

    func generateRecommendations() {
        let dietaryHabits = profileViewModel.userProfile.dietaryHabits

        var newRecommendations: [String] = []

        if let habits = dietaryHabits, !habits.isEmpty {
            if habits.contains(.vegetarian) || habits.contains(.balanced) {
                newRecommendations.append("探索素食食谱")
                newRecommendations.append("健康均衡餐指南")
            }
            if habits.contains(.highProtein) {
                newRecommendations.append("高蛋白增肌餐")
                newRecommendations.append("蛋白质补充剂推荐")
            }
            if habits.contains(.lowCarb) {
                newRecommendations.append("低碳水食谱合集")
                newRecommendations.append("生酮饮食入门")
            }
            if habits.contains(.takeout) || habits.contains(.irregular) {
                newRecommendations.append("15分钟快手健康餐")
                newRecommendations.append("外卖健康选择攻略")
            }
        } else {
            newRecommendations.append("个性化饮食推荐")
            newRecommendations.append("从这里开始健康饮食")
        }
        self.recommendedContent = newRecommendations
    }
}
