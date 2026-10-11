import ComposableArchitecture
import Foundation

struct HomeUseCases {
    var loadDailyQuote: @Sendable (_ quoteDate: String) async throws -> HomeDailyQuoteResult
    var loadFeed: @Sendable (_ endDate: String?) async throws -> HomeFeedResult
    var updateLike: @Sendable (
        _ isLike: Bool,
        _ quote: DailyQuote,
        _ quoteDate: String,
        _ dayOfWeek: String
    ) async throws -> Int
    var postUploadImage: @Sendable (_ fileURL: URL, _ dailyQuoteSeq: Int) async throws -> MemberQuoteImageResponse
    var deleteUploadImage: @Sendable (_ dailyQuoteSeq: Int) async throws -> Int
    var saveAnswer: @Sendable (_ answer: String, _ dailyQuoteSeq: Int) async throws -> AnswerResponse
}

extension HomeUseCases: DependencyKey {
    static let liveValue: HomeUseCases = {
        let homeRepository = LiveRepositories.home
        return HomeUseCases(
            loadDailyQuote: { quoteDate in
                try await LoadHomeDailyQuoteUseCase(homeRepository: homeRepository)(quoteDate: quoteDate)
            },
            loadFeed: { endDate in
                try await LoadHomeFeedUseCase(homeRepository: homeRepository)(endDate: endDate)
            },
            updateLike: { isLike, quote, quoteDate, dayOfWeek in
                try await UpdateHomeLikeUseCase(homeRepository: homeRepository)(
                    isLike: isLike,
                    quote: quote,
                    quoteDate: quoteDate,
                    dayOfWeek: dayOfWeek
                )
            },
            postUploadImage: { fileURL, dailyQuoteSeq in
                try await PostUploadImageUseCase(homeRepository: homeRepository)(
                    fileURL: fileURL,
                    dailyQuoteSeq: dailyQuoteSeq
                )
            },
            deleteUploadImage: { dailyQuoteSeq in
                try await DeleteUploadImageUseCase(homeRepository: homeRepository)(
                    dailyQuoteSeq: dailyQuoteSeq
                )
            },
            saveAnswer: { answer, dailyQuoteSeq in
                try await SaveAnswerUseCase(homeRepository: homeRepository)(
                    answer,
                    dailyQuoteSeq: dailyQuoteSeq
                )
            }
        )
    }()
}

extension DependencyValues {
    var homeUseCases: HomeUseCases {
        get { self[HomeUseCases.self] }
        set { self[HomeUseCases.self] = newValue }
    }
}
