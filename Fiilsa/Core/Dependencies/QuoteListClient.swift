import ComposableArchitecture

struct QuoteListClient {
    var getQuotesList: @Sendable (_ page: Int, _ size: Int, _ likeYn: String, _ startDate: String, _ endDate: String) async throws -> PageResponseMemberQuotesResponse
    var postSaveMemo: @Sendable (_ request: MemoRequest, _ memberQuoteSeq: String) async throws -> Int
}

extension QuoteListClient: DependencyKey {
    static let liveValue: QuoteListClient = {
        let repository = LiveRepositories.quoteList

        return QuoteListClient(
            getQuotesList: { page, size, likeYn, startDate, endDate in
                try await repository.getQuotesList(
                    page: page,
                    size: size,
                    likeYn: likeYn,
                    startDate: startDate,
                    endDate: endDate
                )
            },
            postSaveMemo: { request, memberQuoteSeq in
                try await repository.postSaveMemo(request, memberQuoteSeq: memberQuoteSeq)
            }
        )
    }()
}

extension DependencyValues {
    var quoteListClient: QuoteListClient {
        get { self[QuoteListClient.self] }
        set { self[QuoteListClient.self] = newValue }
    }
}
