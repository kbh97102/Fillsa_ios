import ComposableArchitecture
import FirebaseMessaging
@preconcurrency import Foundation

struct PushTokenClient {
    var currentToken: @Sendable () async -> String?
    var tokenUpdates: @Sendable () -> AsyncStream<String>
}

extension PushTokenClient: DependencyKey {
    static let liveValue = PushTokenClient(
        currentToken: {
            await withCheckedContinuation { continuation in
                Messaging.messaging().token { token, _ in
                    continuation.resume(returning: token)
                }
            }
        },
        tokenUpdates: {
            AsyncStream { continuation in
                let observer = NotificationCenter.default.addObserver(
                    forName: .fillsaFCMTokenRefreshed,
                    object: nil,
                    queue: nil
                ) { notification in
                    guard let token = notification.userInfo?["token"] as? String,
                          !token.isEmpty else {
                        return
                    }
                    continuation.yield(token)
                }

                continuation.onTermination = { _ in
                    NotificationCenter.default.removeObserver(observer)
                }
            }
        }
    )
}

extension DependencyValues {
    var pushTokenClient: PushTokenClient {
        get { self[PushTokenClient.self] }
        set { self[PushTokenClient.self] = newValue }
    }
}
