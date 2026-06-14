struct CheckFirstOpenUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws -> Bool {
        try await localRepository.isFirstOpen()
    }
}

struct GetAccessTokenUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws -> String {
        try await localRepository.getAccessToken()
    }
}

struct GetLoginStatusUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws -> Bool {
        try await localRepository.isLoggedIn()
    }
}

struct GetRefreshTokenUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws -> String {
        try await localRepository.getRefreshToken()
    }
}

struct LogoutUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws {
        try await localRepository.setAccessToken("")
        try await localRepository.setRefreshToken("")
    }
}

struct SetAccessTokenUseCase {
    let localRepository: LocalRepository

    func callAsFunction(_ token: String) async throws {
        try await localRepository.setAccessToken(token)
    }
}

struct SetFirstOpenUseCase {
    let localRepository: LocalRepository

    func callAsFunction(_ isFirstOpen: Bool = false) async throws {
        try await localRepository.setFirstOpen(isFirstOpen)
    }
}

struct SetRefreshTokenUseCase {
    let localRepository: LocalRepository

    func callAsFunction(_ token: String) async throws {
        try await localRepository.setRefreshToken(token)
    }
}
