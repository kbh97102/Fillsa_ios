protocol AuthRepository {
    func login(_ request: LoginRequest) async throws -> LoginResponse
    func refreshToken(_ request: TokenRefreshRequest) async throws -> TokenInfo?
}

