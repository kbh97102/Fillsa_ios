import Foundation

struct DefaultHomeRepository: HomeRepository {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClientFactory.authenticated(deviceIDProvider: { "" })) {
        self.apiClient = apiClient
    }

    func getDailyQuoteNoToken(quoteDate: String) async throws -> DailyQuoteNoToken {
        let request = APIRequest<EmptyRequestBody>(
            method: .get,
            path: APIEndpoint.dailyQuoteNonMember,
            queryItems: [.init(name: "quoteDate", value: quoteDate)],
            requiresAuthorization: false
        )
        return try await apiClient.send(request, responseType: DailyQuoteNoToken.self)
    }

    func getDailyQuote(quoteDate: String) async throws -> DailyQuote {
        let request = APIRequest<EmptyRequestBody>(
            method: .get,
            path: APIEndpoint.dailyQuote,
            queryItems: [.init(name: "quoteDate", value: quoteDate)]
        )
        return try await apiClient.send(request, responseType: DailyQuote.self)
    }

    func postLike(_ requestBody: LikeRequest, dailyQuoteSeq: Int) async throws -> Int {
        let request = APIRequest(
            method: .post,
            path: APIEndpoint.like(dailyQuoteSeq: dailyQuoteSeq),
            body: requestBody
        )
        return try await apiClient.send(request, responseType: Int.self)
    }

    func postUploadImage(fileURL: URL, dailyQuoteSeq: Int) async throws -> MemberQuoteImageResponse {
        throw ErrorResponse.defaultError
    }

    func deleteUploadImage(dailyQuoteSeq: Int) async throws -> Int {
        let request = APIRequest<EmptyRequestBody>(
            method: .delete,
            path: APIEndpoint.uploadImage(dailyQuoteSeq: dailyQuoteSeq)
        )
        return try await apiClient.send(request, responseType: Int.self)
    }
}
