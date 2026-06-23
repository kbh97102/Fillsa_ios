import Foundation

struct LoadQuoteListUseCase {
    let quoteListRepository: QuoteListRepository
    let localRepository: LocalRepository

    func callAsFunction(
        page: Int,
        size: Int,
        likeYn: String,
        startDate: String,
        endDate: String
    ) async throws -> PageResponseMemberQuotesResponse {
        let isLoggedIn = try await GetLoginStatusUseCase(localRepository: localRepository)()

        if isLoggedIn {
            return try await GetQuotesListUseCase(quoteListRepository: quoteListRepository)(
                page: page,
                size: size,
                likeYn: likeYn,
                startDate: startDate,
                endDate: endDate
            )
        }

        let localQuotes = try await GetLocalQuotePagingUseCase(localRepository: localRepository)(
            likeYN: likeYn == "Y" ? .yes : .no,
            startDate: startDate,
            endDate: endDate,
            offset: page * size,
            limit: size
        )
        let content = localQuotes.map(MemberQuotesResponse.init(localQuote:))
        let hasNext = content.count == size

        return PageResponseMemberQuotesResponse(
            content: content,
            totalElements: page * size + content.count,
            totalPages: hasNext ? page + 2 : page + 1,
            currentPage: page
        )
    }
}

struct SaveQuoteMemoUseCase {
    let quoteListRepository: QuoteListRepository
    let localRepository: LocalRepository

    func callAsFunction(memo: String, memberQuoteSeq: String) async throws -> Int {
        let isLoggedIn = try await GetLoginStatusUseCase(localRepository: localRepository)()

        if isLoggedIn {
            return try await PostSaveMemoUseCase(quoteListRepository: quoteListRepository)(
                MemoRequest(memo: memo),
                memberQuoteSeq: memberQuoteSeq
            )
        }

        try await UpdateLocalQuoteMemoUseCase(localRepository: localRepository)(
            memo: memo,
            seq: Int(memberQuoteSeq) ?? 0
        )
        return 1
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

private extension MemberQuotesResponse {
    init(localQuote: LocalQuoteInfo) {
        self.init(
            memberQuoteSeq: localQuote.dailyQuoteSeq,
            quoteDate: localQuote.date,
            quoteDayOfWeek: localQuote.dayOfWeek,
            korQuote: localQuote.korQuote,
            engQuote: localQuote.engQuote,
            korAuthor: localQuote.korAuthor,
            engAuthor: localQuote.engAuthor,
            authorUrl: "",
            memo: localQuote.memo,
            memoYn: localQuote.memo.isEmpty ? "N" : "Y",
            likeYn: localQuote.likeYn,
            imagePath: nil
        )
    }
}
