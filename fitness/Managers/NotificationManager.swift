
import Foundation
import UserNotifications

enum NotificationManager {
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification auth error: \(error)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }
    
    static func scheduleDailyWeighIn(hour: Int = 8, minute: Int = 0, title: String = "Time to Weigh In", body: String = "Record your weight today to keep your trend up-to-date.", completion: ((Result<Void, Error>) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyWeighIn"])
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyWeighIn", content: content, trigger: trigger)
        
        center.add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification schedule error: \(error)")
                    completion?(.failure(error))
                } else {
                    completion?(.success(()))
                }
            }
        }
    }
}
