import Foundation

struct UserDefaultsLocalSettingsStore {
    private enum Key {
        static let imageURI = "image_uri"
        static let userName = "user_name"
        static let isFirstOpen = "is_first_open"
        static let alarm = "alarm_key"
        static let tokenExpired = "token_expired"
        static let permissionRequested = "PERMISSION_REQUESTED"
        static let shareDescription = "SHARE_DESCRIPTION"
        static let darkModeType = "DARK_MODE_TYPE"
        static let hiddenPopupSeqSet = "HIDDEN_POPUP_SEQ_SET"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func setImageURI(_ uri: String) {
        userDefaults.set(uri, forKey: Key.imageURI)
    }

    func imageURI() -> String {
        userDefaults.string(forKey: Key.imageURI) ?? ""
    }

    func setUserName(_ name: String) {
        userDefaults.set(name, forKey: Key.userName)
    }

    func userName() -> String {
        userDefaults.string(forKey: Key.userName) ?? ""
    }

    func setFirstOpen(_ value: Bool) {
        userDefaults.set(value, forKey: Key.isFirstOpen)
    }

    func isFirstOpen() -> Bool {
        if userDefaults.object(forKey: Key.isFirstOpen) == nil {
            return true
        }
        return userDefaults.bool(forKey: Key.isFirstOpen)
    }

    func setAlarm(_ value: Bool) {
        userDefaults.set(value, forKey: Key.alarm)
    }

    func alarm() -> Bool {
        userDefaults.bool(forKey: Key.alarm)
    }

    func setTokenExpired(_ errorCode: String) {
        userDefaults.set(errorCode, forKey: Key.tokenExpired)
    }

    func tokenExpired() -> String {
        userDefaults.string(forKey: Key.tokenExpired) ?? ""
    }

    func setAlarmPermissionRequestedBefore(_ requested: Bool) {
        userDefaults.set(requested, forKey: Key.permissionRequested)
    }

    func isAlarmPermissionRequestedBefore() -> Bool {
        userDefaults.bool(forKey: Key.permissionRequested)
    }

    func setShareDescriptionVisible(_ isVisible: Bool) {
        userDefaults.set(isVisible, forKey: Key.shareDescription)
    }

    func isShareDescriptionVisible() -> Bool {
        if userDefaults.object(forKey: Key.shareDescription) == nil {
            return true
        }
        return userDefaults.bool(forKey: Key.shareDescription)
    }

    func setDarkModeType(_ darkModeType: DarkModeType) {
        userDefaults.set(darkModeType.rawValue, forKey: Key.darkModeType)
    }

    func darkModeType() -> DarkModeType {
        guard let value = userDefaults.string(forKey: Key.darkModeType) else {
            return .system
        }
        return DarkModeType(rawValue: value) ?? .system
    }

    func isPopupHidden(seq: Int) -> Bool {
        hiddenPopupSeqSet().contains(String(seq))
    }

    func addHiddenPopup(seq: Int) {
        var values = hiddenPopupSeqSet()
        values.insert(String(seq))
        userDefaults.set(Array(values), forKey: Key.hiddenPopupSeqSet)
    }

    func clearAllHiddenPopups() {
        userDefaults.set([], forKey: Key.hiddenPopupSeqSet)
    }

    private func hiddenPopupSeqSet() -> Set<String> {
        let values = userDefaults.stringArray(forKey: Key.hiddenPopupSeqSet) ?? []
        return Set(values)
    }
}
