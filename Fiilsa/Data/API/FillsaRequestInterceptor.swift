import Foundation
import Alamofire

enum FillsaRequestHeader {
    static let authorizationBehavior = "X-Fillsa-Authorization"
    static let noAuthorization = "none"
}

protocol TokenStore {
    func accessToken() async -> String
    func refreshToken() async -> String
    func update(accessToken: String, refreshToken: String) async throws
}

final class FillsaRequestInterceptor: RequestInterceptor {
    typealias RefreshTokenHandler = @Sendable (_ refreshToken: String) async throws -> TokenInfo?

    private let tokenStore: TokenStore
    private let refreshTokenHandler: RefreshTokenHandler

    init(
        tokenStore: TokenStore,
        refreshTokenHandler: @escaping RefreshTokenHandler
    ) {
        self.tokenStore = tokenStore
        self.refreshTokenHandler = refreshTokenHandler
    }

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        Task {
            var request = urlRequest

            if request.value(forHTTPHeaderField: FillsaRequestHeader.authorizationBehavior) == FillsaRequestHeader.noAuthorization {
                request.setValue(nil, forHTTPHeaderField: FillsaRequestHeader.authorizationBehavior)
                completion(.success(request))
                return
            }

            let accessToken = await tokenStore.accessToken()
            if !accessToken.isEmpty {
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            }

            completion(.success(request))
        }
    }

    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        guard
            request.retryCount == 0,
            let statusCode = request.response?.statusCode,
            statusCode == 401 || statusCode == 403
        else {
            completion(.doNotRetryWithError(error))
            return
        }

        Task {
            do {
                let refreshToken = await tokenStore.refreshToken()
                guard !refreshToken.isEmpty, let tokenInfo = try await refreshTokenHandler(refreshToken) else {
                    completion(.doNotRetryWithError(error))
                    return
                }

                try await tokenStore.update(
                    accessToken: tokenInfo.accessToken,
                    refreshToken: tokenInfo.refreshToken
                )
                completion(.retry)
            } catch {
                completion(.doNotRetryWithError(error))
            }
        }
    }
}
