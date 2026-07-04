import ComposableArchitecture
import UserNotifications

struct NotificationPermissionClient {
    var authorizationStatus: @Sendable () async -> UNAuthorizationStatus
    var requestAuthorization: @Sendable () async -> Bool
    var scheduleDailyQuoteNotification: @Sendable () async throws -> Void
    var cancelDailyQuoteNotification: @Sendable () async -> Void
}

extension NotificationPermissionClient: DependencyKey {
    static let liveValue = NotificationPermissionClient(
        authorizationStatus: {
            await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        },
        requestAuthorization: {
            do {
                return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        },
        scheduleDailyQuoteNotification: {
            let identifier = "daily_quote_notification"
            let content = UNMutableNotificationContent()
            content.title = "오늘의 필사 문장"
            content.body = "오늘의 필사 문장을 확인해보세요."
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = 9
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: [identifier]
            )
            try await UNUserNotificationCenter.current().add(request)
        },
        cancelDailyQuoteNotification: {
            let identifier = "daily_quote_notification"
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: [identifier]
            )
        }
    )
}

extension DependencyValues {
    var notificationPermissionClient: NotificationPermissionClient {
        get { self[NotificationPermissionClient.self] }
        set { self[NotificationPermissionClient.self] = newValue }
    }
}
