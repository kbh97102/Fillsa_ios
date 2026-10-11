import Foundation
import CryptoKit

enum SessionExpirationReason: String, Sendable {
    case missingRefreshToken
    case refreshFailed
    case retryRejected
}

struct SessionExpirationEvent: Equatable, Sendable {
    let statusCode: Int
    let reason: SessionExpirationReason
    let failedAccessTokenFingerprint: String?

    nonisolated init(statusCode: Int, reason: SessionExpirationReason, failedAccessTokenFingerprint: String? = nil) {
        self.statusCode = statusCode
        self.reason = reason
        self.failedAccessTokenFingerprint = failedAccessTokenFingerprint
    }

    nonisolated static func fingerprint(of token: String) -> String {
        SHA256.hash(data: Data(token.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

extension Notification.Name {
    static let fillsaSessionExpired = Notification.Name("fillsaSessionExpired")
}

enum SessionExpirationEventCenter {
    static func emit(_ event: SessionExpirationEvent) {
        var userInfo: [String: Any] = [
            "statusCode": event.statusCode,
            "reason": event.reason.rawValue
        ]
        if let fingerprint = event.failedAccessTokenFingerprint {
            userInfo["failedAccessTokenFingerprint"] = fingerprint
        }
        NotificationCenter.default.post(
            name: .fillsaSessionExpired,
            object: nil,
            userInfo: userInfo
        )
    }
}
