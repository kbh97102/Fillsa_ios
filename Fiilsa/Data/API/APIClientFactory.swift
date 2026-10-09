import Alamofire
import Foundation

enum APIClientFactory {
    static func authenticated(
        environment: APIEnvironment = .production,
        tokenStore: TokenStore = KeychainTokenStore(),
        sessionConfiguration: URLSessionConfiguration = .default
    ) -> APIClient {
        let refreshClient = APIClient(
            environment: environment,
            session: Session(configuration: sessionConfiguration, interceptor: nil)
        )

        let interceptor = FillsaRequestInterceptor(
            tokenStore: tokenStore,
            refreshTokenHandler: { refreshToken in
                let request = APIRequest(
                    method: .post,
                    path: APIEndpoint.refreshToken,
                    body: TokenRefreshRequest(
                        deviceId: DeviceIDProvider.current(),
                        refreshToken: refreshToken
                    ),
                    requiresAuthorization: false
                )
                return try await refreshClient.send(request, responseType: TokenInfo.self)
            }
        )

        return APIClient(
            environment: environment,
            session: Session(configuration: sessionConfiguration, interceptor: interceptor)
        )
    }

    static func noToken(environment: APIEnvironment = .production) -> APIClient {
        APIClient(
            environment: environment,
            session: Session(interceptor: nil)
        )
    }
}
