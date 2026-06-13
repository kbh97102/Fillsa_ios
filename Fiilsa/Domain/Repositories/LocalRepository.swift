protocol LocalRepository {
    func setAccessToken(_ token: String) async throws
    func getAccessToken() async throws -> String
    func setRefreshToken(_ token: String) async throws
    func getRefreshToken() async throws -> String

    func getLocalQuotes() async throws -> [LocalQuoteInfo]
    func addLocalQuote(_ quote: LocalQuoteInfo) async throws
    func updateLocalQuoteMemo(_ memo: String, seq: Int) async throws
    func updateLocalQuoteLike(_ likeYN: YN, seq: Int) async throws -> Int
    func getQuoteLocal(seq: Int) async throws -> LocalQuoteInfo?
    func deleteQuote(seq: Int) async throws
    func clear() async throws
}
