import ComposableArchitecture

struct SessionClient {
    var isFirstOpen: @Sendable () async throws -> Bool
    var setFirstOpen: @Sendable (_ isFirstOpen: Bool) async throws -> Void
    var isLoggedIn: @Sendable () async throws -> Bool
    var getAccessToken: @Sendable () async throws -> String
    var setAccessToken: @Sendable (_ token: String) async throws -> Void
    var getRefreshToken: @Sendable () async throws -> String
    var setRefreshToken: @Sendable (_ token: String) async throws -> Void
    var logout: @Sendable () async throws -> Void
}

extension SessionClient: DependencyKey {
    static let liveValue: SessionClient = {
        let repository = LiveRepositories.local

        return SessionClient(
            isFirstOpen: {
                try await CheckFirstOpenUseCase(localRepository: repository)()
            },
            setFirstOpen: { isFirstOpen in
                try await SetFirstOpenUseCase(localRepository: repository)(isFirstOpen)
            },
            isLoggedIn: {
                try await GetLoginStatusUseCase(localRepository: repository)()
            },
            getAccessToken: {
                try await GetAccessTokenUseCase(localRepository: repository)()
            },
            setAccessToken: { token in
                try await SetAccessTokenUseCase(localRepository: repository)(token)
            },
            getRefreshToken: {
                try await GetRefreshTokenUseCase(localRepository: repository)()
            },
            setRefreshToken: { token in
                try await SetRefreshTokenUseCase(localRepository: repository)(token)
            },
            logout: {
                try await LogoutUseCase(localRepository: repository)()
            }
        )
    }()
}

extension DependencyValues {
    var sessionClient: SessionClient {
        get { self[SessionClient.self] }
        set { self[SessionClient.self] = newValue }
    }
}
