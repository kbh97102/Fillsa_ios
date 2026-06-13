protocol QuoteListRepository {
    func getQuotesList(
        page: Int,
        size: Int,
        likeYn: String,
        startDate: String,
        endDate: String
    ) async throws -> PageResponseMemberQuotesResponse

    func postSaveMemo(_ request: MemoRequest, memberQuoteSeq: String) async throws -> Int
}

