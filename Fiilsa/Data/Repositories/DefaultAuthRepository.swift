import Foundation

struct DefaultAuthRepository: AuthRepository {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClientFactory.noToken()) {
        self.apiClient = apiClient
    }

    func login(_ requestBody: LoginRequest) async throws -> LoginResponse {
        let request = APIRequest(
            method: .post,
            path: APIEndpoint.login,
            body: requestBody,
            requiresAuthorization: false
        )
        return try await apiClient.send(request, responseType: LoginResponse.self)
    }

    func refreshToken(_ requestBody: TokenRefreshRequest) async throws -> TokenInfo? {
        let request = APIRequest(
            method: .post,
            path: APIEndpoint.refreshToken,
            body: requestBody,
            requiresAuthorization: false
        )
        return try await apiClient.send(request, responseType: TokenInfo.self)
    }
}
