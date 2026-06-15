import Foundation

struct DefaultCalendarRepository: CalendarRepository {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClientFactory.authenticated(deviceIDProvider: { "" })) {
        self.apiClient = apiClient
    }

    func getQuotesMonthly(yearMonth: String) async throws -> MemberMonthlyQuoteResponse {
        let request = APIRequest<EmptyRequestBody>(
            method: .get,
            path: APIEndpoint.memberMonthlyQuotes,
            queryItems: [.init(name: "yearMonth", value: yearMonth)]
        )
        return try await apiClient.send(request, responseType: MemberMonthlyQuoteResponse.self)
    }

    func getQuotesMonthlyNonMember(yearMonth: String) async throws -> [MonthlyQuoteResponse] {
        let request = APIRequest<EmptyRequestBody>(
            method: .get,
            path: APIEndpoint.monthlyQuotes,
            queryItems: [.init(name: "yearMonth", value: yearMonth)],
            requiresAuthorization: false
        )
        return try await apiClient.send(request, responseType: [MonthlyQuoteResponse].self)
    }
}
