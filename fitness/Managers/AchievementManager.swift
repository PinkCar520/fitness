import Foundation
import Combine

class AchievementManager: ObservableObject {
    @Published var showAchievementPopup: Bool = false
    @Published var unlockedAchievement: String? = nil

    private var profileViewModel: ProfileViewModel
    private var cancellables = Set<AnyCancellable>()
    private var hasTriggeredAchievementForMotivator: Bool = false // To prevent repeated pop-ups

    init(profileViewModel: ProfileViewModel) {
        self.profileViewModel = profileViewModel
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        profileViewModel.$userProfile
            .sink { [weak self] userProfile in
                self?.checkForAchievement(userProfile: userProfile)
            }
            .store(in: &cancellables)
    }

    private func checkForAchievement(userProfile: UserProfile) {
        if let motivators = userProfile.motivators, motivators.contains(.achievement) {
            if !hasTriggeredAchievementForMotivator {
                unlockedAchievement = "恭喜！你解锁了 '成就激励' 徽章！"
                showAchievementPopup = true
                hasTriggeredAchievementForMotivator = true
            }
        } else {
            // Reset if motivator is removed
            hasTriggeredAchievementForMotivator = false
        }
    }

    func dismissAchievementPopup() {
        showAchievementPopup = false
        unlockedAchievement = nil
    }
}
