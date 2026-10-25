import Foundation
import XCTest
@testable import Fiilsa

@MainActor
final class SessionPersistenceTests: XCTestCase {
    func test_onboardingCompletionPersistsAcrossLogoutAndRecreation() async throws {
        let suiteName = "Onboarding.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = UserDefaultsLocalSettingsStore(userDefaults: defaults)
        XCTAssertFalse(settings.isOnboardingCompleted())
        settings.setOnboardingCompleted()
        settings.setLogoutRequested(true)
        let reopened = UserDefaultsLocalSettingsStore(userDefaults: try XCTUnwrap(UserDefaults(suiteName: suiteName)))
        XCTAssertTrue(reopened.isOnboardingCompleted())
    }

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

    func test_loginDoesNotUploadOrDeleteLegacyLocalQuotes() async throws {
        let suiteName = "SessionPersistenceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: directory)
        }

        let tokens = KeychainTokenStore(service: "\(suiteName).tokens")
        let database = try SQLiteLocalStore(path: directory.appendingPathComponent("quotes.sqlite").path)
        let repository = try DefaultLocalRepository(
            tokenStore: tokens,
            settingsStore: UserDefaultsLocalSettingsStore(userDefaults: defaults),
            localStore: database
        )
        let legacyQuote = LocalQuoteInfo(
            dailyQuoteSeq: 42, korQuote: "기존 명언", engQuote: "Old quote",
            korAuthor: "작가", engAuthor: "Author", korTyping: "기존 필사",
            engTyping: "Old typing", likeYn: "Y", memo: "기존 메모",
            date: "2025-03-21", dayOfWeek: "FRIDAY"
        )
        try await repository.addLocalQuote(legacyQuote)
        let response = LoginResponse(
            accessToken: "new-access", refreshToken: "new-refresh", memberSeq: 1,
            nickname: "필사", profileImageUrl: ""
        )
        let auth = RecordingAuthRepository(response: response)
        let login = LoginUseCase(
            authRepository: auth, localRepository: repository,
            currentPushToken: { nil }, currentPushAgreement: { false }
        )

        _ = try await login(user: SocialAuthUser(provider: "KAKAO", oauthID: "42", nickname: "필사", profileImageURL: ""))

        let request = await auth.request
        XCTAssertEqual(request?.syncData, [])
        let remaining = try await repository.getLocalQuotes()
        XCTAssertEqual(remaining, [legacyQuote])
        let isLoggedIn = try await repository.isLoggedIn()
        XCTAssertTrue(isLoggedIn)

        let failedLogin = LoginUseCase(
            authRepository: FailingAuthRepository(), localRepository: repository,
            currentPushToken: { nil }, currentPushAgreement: { false }
        )
        do {
            _ = try await failedLogin(user: SocialAuthUser(provider: "KAKAO", oauthID: "42", nickname: "필사", profileImageURL: ""))
            XCTFail("Expected server login failure")
        } catch SessionPersistenceTestError.loginFailed {
        }
        let afterFailure = try await repository.getLocalQuotes()
        XCTAssertEqual(afterFailure, [legacyQuote])
        try await tokens.clear()
    }
}

private actor RecordingAuthRepository: AuthRepository {
    let response: LoginResponse
    private(set) var request: LoginRequest?

    init(response: LoginResponse) { self.response = response }

    func login(_ request: LoginRequest) async throws -> LoginResponse {
        self.request = request
        return response
    }

    func refreshToken(_ request: TokenRefreshRequest) async throws -> TokenInfo? { nil }
}

private struct FailingAuthRepository: AuthRepository {
    func login(_ request: LoginRequest) async throws -> LoginResponse {
        throw SessionPersistenceTestError.loginFailed
    }

    func refreshToken(_ request: TokenRefreshRequest) async throws -> TokenInfo? { nil }
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
    case loginFailed
}
