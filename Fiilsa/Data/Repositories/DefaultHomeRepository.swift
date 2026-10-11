import Foundation

struct DefaultHomeRepository: HomeRepository {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClientFactory.authenticated(deviceIDProvider: { "" })) {
        self.apiClient = apiClient
    }

    func getDailyQuote(quoteDate: String) async throws -> DailyQuote {
        let request = APIRequest<EmptyRequestBody>(
            method: .get,
            path: APIEndpoint.dailyQuote,
            queryItems: [.init(name: "quoteDate", value: quoteDate)]
        )
        return try await apiClient.send(request, responseType: DailyQuote.self)
    }

    func getWeeklyQuotes(endDate: String?) async throws -> MemberWeeklyQuoteResponse {
        let request = APIRequest<EmptyRequestBody>(
            method: .get,
            path: APIEndpoint.memberWeeklyQuotes,
            queryItems: endDate.map { [.init(name: "endDate", value: $0)] } ?? []
        )
        return try await apiClient.send(request, responseType: MemberWeeklyQuoteResponse.self)
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
        try await apiClient.uploadImage(
            fileURL: fileURL,
            path: APIEndpoint.uploadImage(dailyQuoteSeq: dailyQuoteSeq),
            fieldName: "image"
        )
    }

    func deleteUploadImage(dailyQuoteSeq: Int) async throws -> Int {
        let request = APIRequest<EmptyRequestBody>(
            method: .delete,
            path: APIEndpoint.uploadImage(dailyQuoteSeq: dailyQuoteSeq)
        )
        return try await apiClient.send(request, responseType: Int.self)
    }

    func postAnswer(_ requestBody: AnswerRequest, dailyQuoteSeq: Int) async throws -> AnswerResponse {
        let request = APIRequest(
            method: .post,
            path: APIEndpoint.answer(dailyQuoteSeq: dailyQuoteSeq),
            body: requestBody
        )
        return try await apiClient.send(request, responseType: AnswerResponse.self)
    }
}
