import ComposableArchitecture
import Foundation

struct HomeUseCases {
    var loadDailyQuote: @Sendable (_ quoteDate: String) async throws -> HomeDailyQuoteResult
    var loadFeed: @Sendable (_ endDate: String?, _ guestQuoteDate: String) async throws -> HomeFeedResult
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
        let localRepository = LiveRepositories.local

        return HomeUseCases(
            loadDailyQuote: { quoteDate in
                try await LoadHomeDailyQuoteUseCase(
                    homeRepository: homeRepository,
                    localRepository: localRepository
                )(quoteDate: quoteDate)
            },
            loadFeed: { endDate, guestQuoteDate in
                try await LoadHomeFeedUseCase(
                    homeRepository: homeRepository,
                    localRepository: localRepository
                )(endDate: endDate, guestQuoteDate: guestQuoteDate)
            },
            updateLike: { isLike, quote, quoteDate, dayOfWeek in
                try await UpdateHomeLikeUseCase(
                    homeRepository: homeRepository,
                    localRepository: localRepository
                )(
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
