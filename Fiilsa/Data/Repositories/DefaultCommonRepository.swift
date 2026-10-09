import Foundation

struct DefaultCommonRepository: CommonRepository {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClientFactory.authenticated()) {
        self.apiClient = apiClient
    }

    func getNotice(page: Int, size: Int) async throws -> PageResponseNoticeResponse {
        let request = APIRequest<EmptyRequestBody>(
            method: .get,
            path: APIEndpoint.notice,
            queryItems: [
                .init(name: "page", value: String(page)),
                .init(name: "size", value: String(size))
            ],
            requiresAuthorization: false
        )
        return try await apiClient.send(request, responseType: PageResponseNoticeResponse.self)
    }

    func getMemberStreaks() async throws -> MemberStreakResponse {
        let request = APIRequest<EmptyRequestBody>(
            method: .get,
            path: APIEndpoint.memberStreaks
        )
        return try await apiClient.send(request, responseType: MemberStreakResponse.self)
    }

    func getPopupGeneral() async throws -> PopupResponse {
        let request = APIRequest<EmptyRequestBody>(
            method: .get,
            path: APIEndpoint.popupGeneral,
            requiresAuthorization: false
        )
        return try await apiClient.send(request, responseType: PopupResponse.self)
    }

    func getPopupVersionUpdate(currentVersion: String) async throws -> PopupResponse {
        let request = APIRequest<EmptyRequestBody>(
            method: .get,
            path: APIEndpoint.versionUpdate,
            queryItems: [.init(name: "currentVersion", value: currentVersion)],
            requiresAuthorization: false
        )
        return try await apiClient.send(request, responseType: PopupResponse.self)
    }

    func deleteResign() async throws {
        let request = APIRequest<EmptyRequestBody>(
            method: .delete,
            path: APIEndpoint.resign
        )
        let _: EmptyResponse = try await apiClient.send(request, responseType: EmptyResponse.self)
    }
}
