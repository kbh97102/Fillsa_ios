import AuthenticationServices
import ComposableArchitecture
import Foundation
import UIKit
import KakaoSDKCommon
import KakaoSDKUser
import GoogleSignIn
import FirebaseCore

struct SocialAuthUser: Equatable {
    let provider: String
    let oauthID: String
    let nickname: String
    let profileImageURL: String
}

struct SocialAuthClient {
    var signInWithGoogle: @Sendable () async throws -> SocialAuthUser
    var signInWithApple: @Sendable () async throws -> SocialAuthUser
    var signInWithKakao: @Sendable () async throws -> SocialAuthUser
}

extension SocialAuthClient: DependencyKey {
    static let liveValue = SocialAuthClient(
        signInWithGoogle: { try await GoogleSocialAuthClient.signIn() },
        signInWithApple: {
            try await AppleSocialAuthClient().signIn()
        },
        signInWithKakao: {
            try await KakaoSocialAuthClient(config: .current).signIn()
        }
    )
}

extension DependencyValues {
    var socialAuthClient: SocialAuthClient {
        get { self[SocialAuthClient.self] }
        set { self[SocialAuthClient.self] = newValue }
    }
}

enum SocialAuthError: Error, Equatable {
    case missingConfiguration
    case kakaoTalkNotInstalled
    case cancelled
    case invalidUserResponse
}

private struct KakaoSocialAuthClient {
    let config: AuthConfig

    func signIn() async throws -> SocialAuthUser {
        guard UserApi.isKakaoTalkLoginAvailable() else {
            throw SocialAuthError.kakaoTalkNotInstalled
        }
        guard !config.kakaoNativeAppKey.isEmpty else {
            throw SocialAuthError.missingConfiguration
        }

        try await loginWithKakaoTalk()
        let user = try await kakaoUser()
        guard let userID = user.id else {
            throw SocialAuthError.invalidUserResponse
        }

        return SocialAuthUser(
            provider: "KAKAO",
            oauthID: String(userID),
            nickname: user.kakaoAccount?.profile?.nickname ?? "",
            profileImageURL: user.kakaoAccount?.profile?.profileImageUrl?.absoluteString ?? ""
        )
    }

    private func loginWithKakaoTalk() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UserApi.shared.loginWithKakaoTalk { token, error in
                if let error {
                    continuation.resume(throwing: map(error))
                    return
                }
                guard token != nil else {
                    continuation.resume(throwing: SocialAuthError.invalidUserResponse)
                    return
                }
                continuation.resume(returning: ())
            }
        }
    }

    private func kakaoUser() async throws -> User {
        try await withCheckedThrowingContinuation { continuation in
            UserApi.shared.me { user, error in
                if let error {
                    continuation.resume(throwing: map(error))
                    return
                }
                guard let user else {
                    continuation.resume(throwing: SocialAuthError.invalidUserResponse)
                    return
                }
                continuation.resume(returning: user)
            }
        }
    }

    private func map(_ error: Error) -> Error {
        guard let sdkError = error as? SdkError else { return error }
        if case .ClientFailed(reason: .Cancelled, errorMessage: _) = sdkError {
            return SocialAuthError.cancelled
        }
        return error
    }
}

private struct AppleSocialAuthClient {
    func signIn() async throws -> SocialAuthUser {
        try await withCheckedThrowingContinuation { continuation in
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let coordinator = AppleSignInCoordinator(continuation: continuation)
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = coordinator
            controller.presentationContextProvider = coordinator
            AppleSignInSessionStore.shared.currentCoordinator = coordinator
            controller.performRequests()
        }
    }
}

private final class AppleSignInSessionStore {
    static let shared = AppleSignInSessionStore()
    var currentCoordinator: AppleSignInCoordinator?
}

private final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let continuation: CheckedContinuation<SocialAuthUser, Error>

    init(continuation: CheckedContinuation<SocialAuthUser, Error>) {
        self.continuation = continuation
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        AppleSignInSessionStore.shared.currentCoordinator = nil

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              !credential.user.isEmpty else {
            continuation.resume(throwing: SocialAuthError.invalidUserResponse)
            return
        }

#if DEBUG
        let formattedName = Self.displayName(from: credential.fullName)
        print("""
        [Apple Sign In] Credential received
        user: <redacted>
        fullName: \(formattedName.isEmpty ? "<not provided>" : formattedName)
        email: \(credential.email ?? "<not provided>")
        realUserStatus: \(credential.realUserStatus.rawValue)
        identityTokenBytes: \(credential.identityToken?.count ?? 0)
        authorizationCodeBytes: \(credential.authorizationCode?.count ?? 0)
        """)
#endif

        continuation.resume(
            returning: SocialAuthUser(
                provider: "APPLE",
                oauthID: credential.user,
                nickname: Self.displayName(from: credential.fullName),
                profileImageURL: ""
            )
        )
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        AppleSignInSessionStore.shared.currentCoordinator = nil

        if let authorizationError = error as? ASAuthorizationError,
           authorizationError.code == .canceled {
            continuation.resume(throwing: SocialAuthError.cancelled)
            return
        }
        continuation.resume(throwing: error)
    }

    private static func displayName(from components: PersonNameComponents?) -> String {
        guard let components else { return "" }
        return PersonNameComponentsFormatter().string(from: components)
    }
}

@MainActor
private enum GoogleSocialAuthClient {
    static func signIn() async throws -> SocialAuthUser {
        guard let clientID = FirebaseApp.app()?.options.clientID, !clientID.isEmpty else {
            throw SocialAuthError.missingConfiguration
        }
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              var presenter = scene.windows.first(where: \.isKeyWindow)?.rootViewController else {
            throw SocialAuthError.invalidUserResponse
        }
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let userID = result.user.userID, !userID.isEmpty else {
                throw SocialAuthError.invalidUserResponse
            }
            return SocialAuthUser(
                provider: "GOOGLE",
                oauthID: userID,
                nickname: result.user.profile?.name ?? "",
                profileImageURL: result.user.profile?.imageURL(withDimension: 256)?.absoluteString ?? ""
            )
        } catch let error as NSError where error.domain == kGIDSignInErrorDomain && error.code == GIDSignInError.canceled.rawValue {
            throw SocialAuthError.cancelled
        }
    }
}
