import Foundation
import XCTest
@testable import Fiilsa

@MainActor
final class SessionPersistenceTests: XCTestCase {
    func test_logoutRequestBlocksPersistedTokensAfterRepositoryRecreation() async throws {
        let suiteName = "SessionPersistenceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: directory)
        }

        let service = "\(suiteName).tokens"
        let tokens = KeychainTokenStore(service: service)
        let database = try SQLiteLocalStore(path: directory.appendingPathComponent("quotes.sqlite").path)
        let repository = try DefaultLocalRepository(
            tokenStore: tokens,
            settingsStore: UserDefaultsLocalSettingsStore(userDefaults: defaults),
            localStore: database
        )

        try await repository.setAccessToken("access")
        try await repository.setRefreshToken("refresh")
        let wasLoggedIn = try await repository.isLoggedIn()
        XCTAssertTrue(wasLoggedIn)

        try await repository.setLogoutRequested(true)

        let reopened = try DefaultLocalRepository(
            tokenStore: KeychainTokenStore(service: service),
            settingsStore: UserDefaultsLocalSettingsStore(userDefaults: try XCTUnwrap(UserDefaults(suiteName: suiteName))),
            localStore: database
        )
        let isLoggedIn = try await reopened.isLoggedIn()
        let accessToken = try await reopened.getAccessToken()
        let refreshToken = try await reopened.getRefreshToken()
        XCTAssertFalse(isLoggedIn)
        XCTAssertEqual(accessToken, "access")
        XCTAssertEqual(refreshToken, "refresh")

        try await tokens.clear()
    }

    func test_logoutFailureStillBlocksPersistedTokens() async throws {
        let suiteName = "SessionPersistenceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: directory)
        }

        let repository = try DefaultLocalRepository(
            tokenStore: FailingClearTokenStore(),
            settingsStore: UserDefaultsLocalSettingsStore(userDefaults: defaults),
            localStore: try SQLiteLocalStore(path: directory.appendingPathComponent("quotes.sqlite").path)
        )

        do {
            try await LogoutUseCase(localRepository: repository)()
            XCTFail("Expected token deletion to fail")
        } catch SessionPersistenceTestError.clearFailed {
        }

        let isLoggedIn = try await repository.isLoggedIn()
        let accessToken = try await repository.getAccessToken()
        XCTAssertFalse(isLoggedIn)
        XCTAssertEqual(accessToken, "access")
    }

    func test_successfulLoginClearsLogoutRequest() async throws {
        let suiteName = "SessionPersistenceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: directory)
        }

        let tokens = KeychainTokenStore(service: "\(suiteName).tokens")
        let repository = try DefaultLocalRepository(
            tokenStore: tokens,
            settingsStore: UserDefaultsLocalSettingsStore(userDefaults: defaults),
            localStore: try SQLiteLocalStore(path: directory.appendingPathComponent("quotes.sqlite").path)
        )
        try await repository.setLogoutRequested(true)

        let response = LoginResponse(
            accessToken: "new-access",
            refreshToken: "new-refresh",
            memberSeq: 1,
            nickname: "필사",
            profileImageUrl: ""
        )
        let login = LoginUseCase(
            authRepository: SuccessfulAuthRepository(response: response),
            localRepository: repository,
            currentPushToken: { nil },
            currentPushAgreement: { false }
        )
        _ = try await login(user: SocialAuthUser(provider: "KAKAO", oauthID: "42", nickname: "필사", profileImageURL: ""))

        let isLoggedIn = try await repository.isLoggedIn()
        XCTAssertTrue(isLoggedIn)
        try await tokens.clear()
    }
}

private struct SuccessfulAuthRepository: AuthRepository {
    let response: LoginResponse

    func login(_ request: LoginRequest) async throws -> LoginResponse { response }
    func refreshToken(_ request: TokenRefreshRequest) async throws -> TokenInfo? { nil }
}

private actor FailingClearTokenStore: TokenStore {
    func accessToken() async -> String { "access" }
    func refreshToken() async -> String { "refresh" }
    func update(accessToken: String, refreshToken: String) async throws {}
    func clear() async throws { throw SessionPersistenceTestError.clearFailed }
}

private enum SessionPersistenceTestError: Error {
    case clearFailed
}
