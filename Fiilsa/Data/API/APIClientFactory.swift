import Alamofire
import Foundation

enum APIClientFactory {
    typealias DeviceIDProvider = @Sendable () async -> String

    static func authenticated(
        environment: APIEnvironment = .production,
        tokenStore: TokenStore = KeychainTokenStore(),
        deviceIDProvider: @escaping DeviceIDProvider
    ) -> APIClient {
        let refreshClient = APIClient(
            environment: environment,
            session: Session(interceptor: nil)
        )

        let interceptor = FillsaRequestInterceptor(
            tokenStore: tokenStore,
            refreshTokenHandler: { refreshToken in
                let request = APIRequest(
                    method: .post,
                    path: APIEndpoint.refreshToken,
                    body: TokenRefreshRequest(
                        deviceId: await deviceIDProvider(),
                        refreshToken: refreshToken
                    ),
                    requiresAuthorization: false
                )
                return try await refreshClient.send(request, responseType: TokenInfo.self)
            }
        )

        return APIClient(
            environment: environment,
            session: Session(interceptor: interceptor)
        )
    }

    static func noToken(environment: APIEnvironment = .production) -> APIClient {
        APIClient(
            environment: environment,
            session: Session(interceptor: nil)
        )
    }
}
