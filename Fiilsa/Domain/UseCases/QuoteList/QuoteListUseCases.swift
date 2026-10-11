import Foundation

struct LoadQuoteListUseCase {
    let quoteListRepository: QuoteListRepository

    func callAsFunction(
        page: Int,
        size: Int,
        likeYn: String,
        startDate: String,
        endDate: String
    ) async throws -> PageResponseMemberQuotesResponse {
        try await GetQuotesListUseCase(quoteListRepository: quoteListRepository)(
            page: page,
            size: size,
            likeYn: likeYn,
            startDate: startDate,
            endDate: endDate
        )
    }
}

struct SaveQuoteMemoUseCase {
    let quoteListRepository: QuoteListRepository

    func callAsFunction(memo: String, memberQuoteSeq: String) async throws -> Int {
        try await PostSaveMemoUseCase(quoteListRepository: quoteListRepository)(
            MemoRequest(memo: memo),
            memberQuoteSeq: memberQuoteSeq
        )
    }
}

struct GetQuotesListUseCase {
    let quoteListRepository: QuoteListRepository

    func callAsFunction(
        page: Int,
        size: Int,
        likeYn: String,
        startDate: String,
        endDate: String
    ) async throws -> PageResponseMemberQuotesResponse {
        try await quoteListRepository.getQuotesList(
            page: page,
            size: size,
            likeYn: likeYn,
            startDate: startDate,
            endDate: endDate
        )
    }
}

struct PostSaveMemoUseCase {
    let quoteListRepository: QuoteListRepository

    func callAsFunction(_ request: MemoRequest, memberQuoteSeq: String) async throws -> Int {
        try await quoteListRepository.postSaveMemo(request, memberQuoteSeq: memberQuoteSeq)
    }
}
