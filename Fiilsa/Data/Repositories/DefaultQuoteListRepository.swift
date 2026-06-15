import Foundation

struct DefaultQuoteListRepository: QuoteListRepository {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClientFactory.authenticated(deviceIDProvider: { "" })) {
        self.apiClient = apiClient
    }

    func getQuotesList(
        page: Int,
        size: Int,
        likeYn: String,
        startDate: String,
        endDate: String
    ) async throws -> PageResponseMemberQuotesResponse {
        let request = APIRequest<EmptyRequestBody>(
            method: .get,
            path: APIEndpoint.quoteList,
            queryItems: [
                .init(name: "page", value: String(page)),
                .init(name: "size", value: String(size)),
                .init(name: "likeYn", value: likeYn),
                .init(name: "startDate", value: startDate),
                .init(name: "endDate", value: endDate)
            ]
        )
        return try await apiClient.send(request, responseType: PageResponseMemberQuotesResponse.self)
    }

    func postSaveMemo(_ requestBody: MemoRequest, memberQuoteSeq: String) async throws -> Int {
        let request = APIRequest(
            method: .post,
            path: APIEndpoint.saveMemo(memberQuoteSeq: memberQuoteSeq),
            body: requestBody
        )
        return try await apiClient.send(request, responseType: Int.self)
    }
}
