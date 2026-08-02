import Foundation

enum FCMTokenEventCenter {
    static func post(token: String) {
        NotificationCenter.default.post(
            name: .fillsaFCMTokenRefreshed,
            object: nil,
            userInfo: ["token": token]
        )
    }
}

extension Notification.Name {
    static let fillsaFCMTokenRefreshed = Notification.Name("fillsaFCMTokenRefreshed")
}
