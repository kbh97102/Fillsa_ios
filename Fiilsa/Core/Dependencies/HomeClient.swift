import ComposableArchitecture
import Foundation

struct HomeClient {
    var getDailyQuoteNoToken: @Sendable (_ quoteDate: String) async throws -> DailyQuoteNoToken
    var getDailyQuote: @Sendable (_ quoteDate: String) async throws -> DailyQuote
    var postLike: @Sendable (_ request: LikeRequest, _ dailyQuoteSeq: Int) async throws -> Int
    var deleteUploadImage: @Sendable (_ dailyQuoteSeq: Int) async throws -> Int
}

extension HomeClient: DependencyKey {
    static let liveValue: HomeClient = {
        let repository = LiveRepositories.home

        return HomeClient(
            getDailyQuoteNoToken: { quoteDate in
                try await repository.getDailyQuoteNoToken(quoteDate: quoteDate)
            },
            getDailyQuote: { quoteDate in
                try await repository.getDailyQuote(quoteDate: quoteDate)
            },
            postLike: { request, dailyQuoteSeq in
                try await repository.postLike(request, dailyQuoteSeq: dailyQuoteSeq)
            },
            deleteUploadImage: { dailyQuoteSeq in
                try await repository.deleteUploadImage(dailyQuoteSeq: dailyQuoteSeq)
            }
        )
    }()
}

extension DependencyValues {
    var homeClient: HomeClient {
        get { self[HomeClient.self] }
        set { self[HomeClient.self] = newValue }
    }
}
