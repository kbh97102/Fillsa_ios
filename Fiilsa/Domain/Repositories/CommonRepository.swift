protocol CommonRepository {
    func getNotice(page: Int, size: Int) async throws -> PageResponseNoticeResponse
    func getMemberStreaks() async throws -> MemberStreakResponse
    func getPopupGeneral() async throws -> PopupResponse
    func getPopupVersionUpdate(currentVersion: String) async throws -> PopupResponse
    func deleteResign() async throws -> Int
}

