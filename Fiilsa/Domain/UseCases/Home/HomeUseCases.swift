import Foundation

struct HomeDailyQuoteResult: Equatable {
    let quote: DailyQuote
    let isLoggedIn: Bool
}

enum HomeFeedResult: Equatable {
    case member(MemberWeeklyQuoteResponse)
}

struct LoadHomeFeedUseCase {
    let homeRepository: HomeRepository

    func callAsFunction(endDate: String?) async throws -> HomeFeedResult {
        .member(try await homeRepository.getWeeklyQuotes(endDate: endDate))
    }
}

struct LoadHomeDailyQuoteUseCase {
    let homeRepository: HomeRepository

    func callAsFunction(quoteDate: String) async throws -> HomeDailyQuoteResult {
        return HomeDailyQuoteResult(
            quote: try await GetDailyQuoteUseCase(homeRepository: homeRepository)(quoteDate: quoteDate),
            isLoggedIn: true
        )
    }
}

struct UpdateHomeLikeUseCase {
    let homeRepository: HomeRepository

    func callAsFunction(
        isLike: Bool,
        quote: DailyQuote,
        quoteDate: String,
        dayOfWeek: String
    ) async throws -> Int {
        try await PostLikeUseCase(homeRepository: homeRepository)(
            LikeRequest(likeYn: isLike ? "Y" : "N"),
            dailyQuoteSeq: quote.dailyQuoteSeq
        )
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

struct SaveAnswerUseCase {
    let homeRepository: HomeRepository

    func callAsFunction(_ answer: String, dailyQuoteSeq: Int) async throws -> AnswerResponse {
        try await homeRepository.postAnswer(
            AnswerRequest(answer: answer),
            dailyQuoteSeq: dailyQuoteSeq
        )
    }
}

struct DeleteUploadImageUseCase {
    let homeRepository: HomeRepository

    func callAsFunction(dailyQuoteSeq: Int) async throws -> Int {
        try await homeRepository.deleteUploadImage(dailyQuoteSeq: dailyQuoteSeq)
    }
}
