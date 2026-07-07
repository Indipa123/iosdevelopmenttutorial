import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private let dailyChallengeIdentifier = "dailyChallenge"

    private init() {}

    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func scheduleDailyChallenge(at time: Date) {
        cancelDailyChallenge()

        let content = UNMutableNotificationContent()
        content.title = "Daily Challenge"
        content.body = "The arcade is waiting — beat your high score today!"
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: dailyChallengeIdentifier,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func cancelDailyChallenge() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyChallengeIdentifier])
    }
}
