struct DefaultTypingRepository: TypingRepository {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClientFactory.authenticated(deviceIDProvider: { "" })) {
        self.apiClient = apiClient
    }

    func getTyping(dailyQuoteSeq: Int) async throws -> MemberTypingQuoteResponse {
        let request = APIRequest<EmptyRequestBody>(
            method: .get,
            path: APIEndpoint.typing(dailyQuoteSeq: dailyQuoteSeq)
        )
        return try await apiClient.send(request, responseType: MemberTypingQuoteResponse.self)
    }

    func postTyping(dailyQuoteSeq: Int, request requestBody: TypingQuoteRequest) async throws -> Int {
        let request = APIRequest(
            method: .post,
            path: APIEndpoint.typing(dailyQuoteSeq: dailyQuoteSeq),
            body: requestBody
        )
        return try await apiClient.send(request, responseType: Int.self)
    }
}
