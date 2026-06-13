protocol TypingRepository {
    func getTyping(dailyQuoteSeq: Int) async throws -> MemberTypingQuoteResponse
    func postTyping(dailyQuoteSeq: Int, request: TypingQuoteRequest) async throws -> Int
}

