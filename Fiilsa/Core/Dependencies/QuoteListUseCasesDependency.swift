import ComposableArchitecture

struct QuoteListUseCases {
    var loadList: @Sendable (
        _ page: Int,
        _ size: Int,
        _ likeYn: String,
        _ startDate: String,
        _ endDate: String
    ) async throws -> PageResponseMemberQuotesResponse
    var saveMemo: @Sendable (_ memo: String, _ memberQuoteSeq: String) async throws -> Int
}

extension QuoteListUseCases: DependencyKey {
    static let liveValue: QuoteListUseCases = {
        let quoteListRepository = LiveRepositories.quoteList
        let localRepository = LiveRepositories.local

        return QuoteListUseCases(
            loadList: { page, size, likeYn, startDate, endDate in
                try await LoadQuoteListUseCase(
                    quoteListRepository: quoteListRepository,
                    localRepository: localRepository
                )(
                    page: page,
                    size: size,
                    likeYn: likeYn,
                    startDate: startDate,
                    endDate: endDate
                )
            },
            saveMemo: { memo, memberQuoteSeq in
                try await SaveQuoteMemoUseCase(
                    quoteListRepository: quoteListRepository,
                    localRepository: localRepository
                )(
                    memo: memo,
                    memberQuoteSeq: memberQuoteSeq
                )
            }
        )
    }()
}

extension DependencyValues {
    var quoteListUseCases: QuoteListUseCases {
        get { self[QuoteListUseCases.self] }
        set { self[QuoteListUseCases.self] = newValue }
    }
}
