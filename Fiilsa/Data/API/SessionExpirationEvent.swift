import Foundation

enum SessionExpirationReason: String, Sendable {
    case missingRefreshToken
    case refreshFailed
    case retryRejected
}

struct SessionExpirationEvent: Equatable, Sendable {
    let statusCode: Int
    let reason: SessionExpirationReason
}

extension Notification.Name {
    static let fillsaSessionExpired = Notification.Name("fillsaSessionExpired")
}

enum SessionExpirationEventCenter {
    static func emit(_ event: SessionExpirationEvent) {
        NotificationCenter.default.post(
            name: .fillsaSessionExpired,
            object: nil,
            userInfo: [
                "statusCode": event.statusCode,
                "reason": event.reason.rawValue
            ]
        )
    }
}
