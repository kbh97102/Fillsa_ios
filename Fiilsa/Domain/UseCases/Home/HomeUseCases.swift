import Foundation

struct HomeDailyQuoteResult: Equatable {
    let quote: DailyQuote
    let isLoggedIn: Bool
}

struct LoadHomeDailyQuoteUseCase {
    let homeRepository: HomeRepository
    let localRepository: LocalRepository

    func callAsFunction(quoteDate: String) async throws -> HomeDailyQuoteResult {
        let isLoggedIn = try await GetLoginStatusUseCase(localRepository: localRepository)()

        if isLoggedIn {
            return HomeDailyQuoteResult(
                quote: try await GetDailyQuoteUseCase(homeRepository: homeRepository)(quoteDate: quoteDate),
                isLoggedIn: true
            )
        }

        let response = try await GetDailyQuoteNoTokenUseCase(homeRepository: homeRepository)(quoteDate: quoteDate)
        let localQuote = try await FindLocalQuoteByIdUseCase(localRepository: localRepository)(seq: response.dailyQuoteSeq)

        return HomeDailyQuoteResult(
            quote: DailyQuote(
                likeYn: localQuote?.likeYn ?? "N",
                dailyQuoteSeq: response.dailyQuoteSeq,
                korQuote: response.korQuote,
                engQuote: response.engQuote,
                korAuthor: response.korAuthor,
                engAuthor: response.engAuthor,
                authorUrl: response.authorUrl,
                quoteDate: quoteDate
            ),
            isLoggedIn: false
        )
    }
}

struct UpdateHomeLikeUseCase {
    let homeRepository: HomeRepository
    let localRepository: LocalRepository

    func callAsFunction(
        isLike: Bool,
        quote: DailyQuote,
        quoteDate: String,
        dayOfWeek: String
    ) async throws -> Int {
        let isLoggedIn = try await GetLoginStatusUseCase(localRepository: localRepository)()

        if isLoggedIn {
            return try await PostLikeUseCase(homeRepository: homeRepository)(
                LikeRequest(likeYn: isLike ? "Y" : "N"),
                dailyQuoteSeq: quote.dailyQuoteSeq
            )
        }

        if try await FindLocalQuoteByIdUseCase(localRepository: localRepository)(seq: quote.dailyQuoteSeq) == nil {
            try await AddLocalQuoteUseCase(localRepository: localRepository)(
                LocalQuoteInfo(
                    dailyQuoteSeq: quote.dailyQuoteSeq,
                    korQuote: quote.korQuote ?? "",
                    engQuote: quote.engQuote ?? "",
                    korAuthor: quote.korAuthor ?? "",
                    engAuthor: quote.engAuthor ?? "",
                    korTyping: "",
                    engTyping: "",
                    likeYn: isLike ? "Y" : "N",
                    memo: "",
                    date: quoteDate,
                    dayOfWeek: dayOfWeek
                )
            )
            return 1
        }

        return try await UpdateLocalQuoteLikeUseCase(localRepository: localRepository)(
            likeYN: isLike ? .yes : .no,
            seq: quote.dailyQuoteSeq
        )
    }
}

struct GetDailyQuoteNoTokenUseCase {
    let homeRepository: HomeRepository

    func callAsFunction(quoteDate: String) async throws -> DailyQuoteNoToken {
        try await homeRepository.getDailyQuoteNoToken(quoteDate: quoteDate)
    }
}

struct GetDailyQuoteUseCase {
    let homeRepository: HomeRepository

    func callAsFunction(quoteDate: String) async throws -> DailyQuote {
        try await homeRepository.getDailyQuote(quoteDate: quoteDate)
    }
}

struct PostLikeUseCase {
    let homeRepository: HomeRepository

    func callAsFunction(_ request: LikeRequest, dailyQuoteSeq: Int) async throws -> Int {
        try await homeRepository.postLike(request, dailyQuoteSeq: dailyQuoteSeq)
    }
}

struct PostUploadImageUseCase {
    let homeRepository: HomeRepository

    func callAsFunction(fileURL: URL, dailyQuoteSeq: Int) async throws -> MemberQuoteImageResponse {
        try await homeRepository.postUploadImage(fileURL: fileURL, dailyQuoteSeq: dailyQuoteSeq)
    }
}

struct DeleteUploadImageUseCase {
    let homeRepository: HomeRepository

    func callAsFunction(dailyQuoteSeq: Int) async throws -> Int {
        try await homeRepository.deleteUploadImage(dailyQuoteSeq: dailyQuoteSeq)
    }
}
