final class DefaultLocalRepository: LocalRepository {
    private let tokenStore: KeychainTokenStore
    private let settingsStore: UserDefaultsLocalSettingsStore

    init(
        tokenStore: KeychainTokenStore = KeychainTokenStore(),
        settingsStore: UserDefaultsLocalSettingsStore = UserDefaultsLocalSettingsStore()
    ) {
        self.tokenStore = tokenStore
        self.settingsStore = settingsStore
    }

    func setAccessToken(_ token: String) async throws {
        try await tokenStore.update(
            accessToken: token,
            refreshToken: await tokenStore.refreshToken()
        )
    }

    func getAccessToken() async throws -> String {
        await tokenStore.accessToken()
    }

    func setRefreshToken(_ token: String) async throws {
        try await tokenStore.update(
            accessToken: await tokenStore.accessToken(),
            refreshToken: token
        )
    }

    func getRefreshToken() async throws -> String {
        await tokenStore.refreshToken()
    }

    func isLoggedIn() async throws -> Bool {
        let accessToken = await tokenStore.accessToken()
        let refreshToken = await tokenStore.refreshToken()
        return !accessToken.isEmpty && !refreshToken.isEmpty
    }

    func setImageURI(_ uri: String) async throws {
        settingsStore.setImageURI(uri)
    }

    func getImageURI() async throws -> String {
        settingsStore.imageURI()
    }

    func setShareDescriptionVisible(_ isVisible: Bool) async throws {
        settingsStore.setShareDescriptionVisible(isVisible)
    }

    func getShareDescriptionVisible() async throws -> Bool {
        settingsStore.isShareDescriptionVisible()
    }

    func isFirstOpen() async throws -> Bool {
        settingsStore.isFirstOpen()
    }

    func setFirstOpen(_ value: Bool) async throws {
        settingsStore.setFirstOpen(value)
    }

    func setAlarm(_ value: Bool) async throws {
        settingsStore.setAlarm(value)
    }

    func getAlarm() async throws -> Bool {
        settingsStore.alarm()
    }

    func setName(_ value: String) async throws {
        settingsStore.setUserName(value)
    }

    func getName() async throws -> String {
        settingsStore.userName()
    }

    func isAlarmPermissionRequestedBefore() async throws -> Bool {
        settingsStore.isAlarmPermissionRequestedBefore()
    }

    func setAlarmPermissionRequestedBefore(_ requested: Bool) async throws {
        settingsStore.setAlarmPermissionRequestedBefore(requested)
    }

    func emitTokenExpired(_ errorCode: String) async throws {
        settingsStore.setTokenExpired(errorCode)
    }

    func getTokenExpired() async throws -> String {
        settingsStore.tokenExpired()
    }

    func setDarkModeType(_ darkModeType: DarkModeType) async throws {
        settingsStore.setDarkModeType(darkModeType)
    }

    func getDarkModeType() async throws -> DarkModeType {
        settingsStore.darkModeType()
    }

    func checkPopupIsHidden(seq: Int) async throws -> Bool {
        settingsStore.isPopupHidden(seq: seq)
    }

    func addHiddenPopup(seq: Int) async throws {
        settingsStore.addHiddenPopup(seq: seq)
    }

    func clearAllHiddenPopup() async throws {
        settingsStore.clearAllHiddenPopups()
    }

    func getLocalQuotes() async throws -> [LocalQuoteInfo] {
        throw LocalRepositoryStorageError.localQuoteStoreNotImplemented
    }

    func addLocalQuote(_ quote: LocalQuoteInfo) async throws {
        throw LocalRepositoryStorageError.localQuoteStoreNotImplemented
    }

    func updateLocalQuoteMemo(_ memo: String, seq: Int) async throws {
        throw LocalRepositoryStorageError.localQuoteStoreNotImplemented
    }

    func updateLocalQuoteLike(_ likeYN: YN, seq: Int) async throws -> Int {
        throw LocalRepositoryStorageError.localQuoteStoreNotImplemented
    }

    func getQuoteLocal(seq: Int) async throws -> LocalQuoteInfo? {
        throw LocalRepositoryStorageError.localQuoteStoreNotImplemented
    }

    func deleteQuote(seq: Int) async throws {
        throw LocalRepositoryStorageError.localQuoteStoreNotImplemented
    }

    func clear() async throws {
        try await tokenStore.clear()
    }
}

enum LocalRepositoryStorageError: Error, Equatable {
    case localQuoteStoreNotImplemented
}
