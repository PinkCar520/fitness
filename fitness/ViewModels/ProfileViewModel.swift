import Foundation
import Combine

final class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile

    private let userDefaultsKey = "userProfile"

    init() {
        if let savedProfileData = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decodedProfile = try? JSONDecoder().decode(UserProfile.self, from: savedProfileData) {
                self.userProfile = decodedProfile
                return
            }
        }
        // If no saved profile or decoding failed, create a default one
        self.userProfile = UserProfile()
    }

    func saveProfile() {
        if let encoded = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey);
        }
    }
}
