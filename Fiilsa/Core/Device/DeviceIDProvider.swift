import Foundation

enum DeviceIDProvider {
    private static let key = "fillsa_device_id"

    static func current() -> String {
        if let value = UserDefaults.standard.string(forKey: key), !value.isEmpty {
            return value
        }

        let value = UUID().uuidString
        UserDefaults.standard.set(value, forKey: key)
        return value
    }
}
