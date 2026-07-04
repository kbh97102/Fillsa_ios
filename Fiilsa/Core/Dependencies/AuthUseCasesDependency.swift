import ComposableArchitecture
import Foundation
import UIKit

struct AuthUseCases {
    var login: @Sendable (_ user: SocialAuthUser) async throws -> LoginResponse
}

extension AuthUseCases: DependencyKey {
    static let liveValue: AuthUseCases = {
        let authRepository = LiveRepositories.auth
        let localRepository = LiveRepositories.local

        return AuthUseCases(
            login: { user in
                try await LoginUseCase(
                    authRepository: authRepository,
                    localRepository: localRepository
                )(user: user)
            }
        )
    }()
}

extension DependencyValues {
    var authUseCases: AuthUseCases {
        get { self[AuthUseCases.self] }
        set { self[AuthUseCases.self] = newValue }
    }
}

private struct LoginUseCase {
    let authRepository: AuthRepository
    let localRepository: LocalRepository

    func callAsFunction(user: SocialAuthUser) async throws -> LoginResponse {
        let localQuotes = try await GetLocalQuoteListUseCase(localRepository: localRepository)()
        let request = LoginRequest(
            loginData: LoginData(
                deviceData: DeviceData(
                    deviceId: DeviceIDProvider.current(),
                    osType: "IOS",
                    appVersion: APIAppVersionProvider.current(),
                    osVersion: UIDevice.current.systemVersion,
                    deviceModel: UIDevice.current.model
                ),
                userData: UserData(
                    oAuthProvider: user.provider,
                    oAuthId: user.oauthID,
                    nickname: user.nickname,
                    profileImageUrl: user.profileImageURL
                )
            ),
            syncData: localQuotes.map {
                DailySyncData(
                    dailyQuoteSeq: $0.dailyQuoteSeq,
                    typingQuoteRequest: TypingQuoteRequest(
                        typingKorQuote: $0.korTyping,
                        typingEngQuote: $0.engTyping
                    ),
                    memoRequest: MemoRequest(memo: $0.memo),
                    likeRequest: LikeRequest(likeYn: $0.likeYn)
                )
            }
        )

        let response = try await authRepository.login(request)
        try await SetAccessTokenUseCase(localRepository: localRepository)(response.accessToken)
        try await SetRefreshTokenUseCase(localRepository: localRepository)(response.refreshToken)
        try await SetUserNameUseCase(localRepository: localRepository)(response.nickname)
        try await localRepository.setImageURI(response.profileImageUrl)
        try await ClearLocalDataUseCase(localRepository: localRepository)()
        return response
    }
}

private enum DeviceIDProvider {
    private static let key = "fillsa_device_id"

    static func current() -> String {
        if let value = UserDefaults.standard.string(forKey: key), !value.isEmpty {
            return value
        }
        let value = UUID().uuidString
        UserDefaults.standard.set(value, forKey: key)
        return value
    }
}

private enum APIAppVersionProvider {
    static func current() -> String {
        let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        if let bundleVersion, !bundleVersion.isEmpty, bundleVersion != "1.0" {
            return bundleVersion
        }
        return "1.0.26"
    }
}
