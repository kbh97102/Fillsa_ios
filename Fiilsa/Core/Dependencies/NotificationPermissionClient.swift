import ComposableArchitecture
import UserNotifications

struct NotificationPermissionClient {
    var requestAuthorization: @Sendable () async -> Bool
}

extension NotificationPermissionClient: DependencyKey {
    static let liveValue = NotificationPermissionClient {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
}

extension DependencyValues {
    var notificationPermissionClient: NotificationPermissionClient {
        get { self[NotificationPermissionClient.self] }
        set { self[NotificationPermissionClient.self] = newValue }
    }
}
