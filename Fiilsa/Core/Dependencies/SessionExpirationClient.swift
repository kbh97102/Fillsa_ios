import ComposableArchitecture
import Foundation

struct SessionExpirationClient {
    var events: @Sendable () -> AsyncStream<SessionExpirationEvent>
}

extension SessionExpirationClient: DependencyKey {
    static let liveValue = SessionExpirationClient(
        events: {
            AsyncStream { continuation in
                let observer = NotificationCenter.default.addObserver(
                    forName: .fillsaSessionExpired,
                    object: nil,
                    queue: nil
                ) { notification in
                    guard
                        let statusCode = notification.userInfo?["statusCode"] as? Int,
                        let reasonValue = notification.userInfo?["reason"] as? String,
                        let reason = SessionExpirationReason(rawValue: reasonValue)
                    else {
                        return
                    }

                    continuation.yield(
                        SessionExpirationEvent(statusCode: statusCode, reason: reason)
                    )
                }

                continuation.onTermination = { _ in
                    NotificationCenter.default.removeObserver(observer)
                }
            }
        }
    )
}

extension DependencyValues {
    var sessionExpirationClient: SessionExpirationClient {
        get { self[SessionExpirationClient.self] }
        set { self[SessionExpirationClient.self] = newValue }
    }
}
