protocol LocalRepository {
    func setAccessToken(_ token: String) async throws
    func getAccessToken() async throws -> String
    func setRefreshToken(_ token: String) async throws
    func getRefreshToken() async throws -> String
    func isLoggedIn() async throws -> Bool

    func setImageURI(_ uri: String) async throws
    func getImageURI() async throws -> String
    func setShareDescriptionVisible(_ isVisible: Bool) async throws
    func getShareDescriptionVisible() async throws -> Bool
    func isFirstOpen() async throws -> Bool
    func setFirstOpen(_ value: Bool) async throws
    func setAlarm(_ value: Bool) async throws
    func getAlarm() async throws -> Bool
    func setName(_ value: String) async throws
    func getName() async throws -> String
    func isAlarmPermissionRequestedBefore() async throws -> Bool
    func setAlarmPermissionRequestedBefore(_ requested: Bool) async throws
    func emitTokenExpired(_ errorCode: String) async throws
    func getTokenExpired() async throws -> String
    func setDarkModeType(_ darkModeType: DarkModeType) async throws
    func getDarkModeType() async throws -> DarkModeType
    func checkPopupIsHidden(seq: Int) async throws -> Bool
    func addHiddenPopup(seq: Int) async throws
    func clearAllHiddenPopup() async throws

    func getLocalQuotes() async throws -> [LocalQuoteInfo]
    func addLocalQuote(_ quote: LocalQuoteInfo) async throws
    func updateLocalQuoteMemo(_ memo: String, seq: Int) async throws
    func updateLocalQuoteLike(_ likeYN: YN, seq: Int) async throws -> Int
    func getQuoteLocal(seq: Int) async throws -> LocalQuoteInfo?
    func deleteQuote(seq: Int) async throws
    func clear() async throws
}
