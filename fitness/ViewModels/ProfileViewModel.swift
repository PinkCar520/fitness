import Foundation
import Combine
import WidgetKit
import UIKit
import SwiftUI
import PhotosUI

final class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile

    private let userDefaultsKey = "userProfile"
    private let appGroup = AppGroup.suiteName

    // Computed property to get the avatar UIImage
    var displayAvatar: UIImage {
        guard let avatarPath = userProfile.avatarPath, 
              let fileURL = getDocumentsDirectory()?.appendingPathComponent(avatarPath), 
              let imageData = try? Data(contentsOf: fileURL) else {
            return UIImage(named: "user_avatar") ?? UIImage()
        }
        return UIImage(data: imageData) ?? UIImage(named: "user_avatar") ?? UIImage()
    }

    init() {
        if let userDefaults = UserDefaults(suiteName: appGroup),
           let savedProfileData = userDefaults.data(forKey: userDefaultsKey),
           let decodedProfile = try? JSONDecoder().decode(UserProfile.self, from: savedProfileData) {
            self.userProfile = decodedProfile
            return
        }
        self.userProfile = UserProfile()
    }

    func saveProfile() {
        guard let userDefaults = UserDefaults(suiteName: appGroup) else { return }
        
        if let encoded = try? JSONEncoder().encode(userProfile) {
            userDefaults.set(encoded, forKey: userDefaultsKey)
        }
        
        userDefaults.set(userProfile.targetWeight, forKey: "targetWeight")
        WidgetCenter.shared.reloadAllTimelines()
    }

    // Method to handle avatar updates from PhotosPickerItem
    @MainActor
    func setAvatar(from item: PhotosPickerItem?) {
        Task {
            guard let item = item, 
                  let data = try? await item.loadTransferable(type: Data.self) else { return }
            
            let fileName = "user_avatar.jpg"
            guard let fileURL = getDocumentsDirectory()?.appendingPathComponent(fileName) else { return }

            do {
                try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
                userProfile.avatarPath = fileName
                saveProfile()
                objectWillChange.send() // Manually notify views of the change
            } catch {
                print("Error saving avatar image: \(error)")
            }
        }
    }

    private func getDocumentsDirectory() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
}
