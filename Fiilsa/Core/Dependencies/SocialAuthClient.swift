import AuthenticationServices
import ComposableArchitecture
import Foundation
import UIKit

struct SocialAuthUser: Equatable {
    let provider: String
    let oauthID: String
    let nickname: String
    let profileImageURL: String
}

struct SocialAuthClient {
    var signInWithApple: @Sendable () async throws -> SocialAuthUser
    var signInWithKakao: @Sendable () async throws -> SocialAuthUser
}

extension SocialAuthClient: DependencyKey {
    static let liveValue = SocialAuthClient(
        signInWithApple: {
            try await AppleSocialAuthClient().signIn()
        },
        signInWithKakao: {
            try await WebSocialAuthClient(config: .current).signInWithKakao()
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
    case cancelled
    case invalidCallback
    case invalidTokenResponse
    case invalidUserResponse
}

private struct WebSocialAuthClient {
    let config: AuthConfig

    func signInWithKakao() async throws -> SocialAuthUser {
        guard !config.kakaoRestAPIKey.isEmpty,
              let redirectURI = URL(string: config.kakaoRedirectURI),
              let callbackScheme = redirectURI.scheme else {
            throw SocialAuthError.missingConfiguration
        }

        var components = URLComponents(string: "https://kauth.kakao.com/oauth/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: config.kakaoRestAPIKey),
            URLQueryItem(name: "redirect_uri", value: config.kakaoRedirectURI),
            URLQueryItem(name: "response_type", value: "code")
        ]

        guard let authURL = components?.url else {
            throw SocialAuthError.missingConfiguration
        }

        let callbackURL = try await authenticate(url: authURL, callbackScheme: callbackScheme)
        let code = try authorizationCode(from: callbackURL)
        let tokenData = try await requestForm(
            url: URL(string: "https://kauth.kakao.com/oauth/token")!,
            items: [
                "grant_type": "authorization_code",
                "client_id": config.kakaoRestAPIKey,
                "redirect_uri": config.kakaoRedirectURI,
                "code": code
            ]
        )

        guard let token = try JSONSerialization.jsonObject(with: tokenData) as? [String: Any],
              let accessToken = token["access_token"] as? String else {
            throw SocialAuthError.invalidTokenResponse
        }

        var request = URLRequest(url: URL(string: "https://kapi.kakao.com/v2/user/me")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
              200..<300 ~= statusCode,
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SocialAuthError.invalidUserResponse
        }

        let account = object["kakao_account"] as? [String: Any]
        let profile = account?["profile"] as? [String: Any]

        return SocialAuthUser(
            provider: "KAKAO",
            oauthID: object["id"].map { String(describing: $0) } ?? "",
            nickname: profile?["nickname"] as? String ?? "",
            profileImageURL: profile?["profile_image_url"] as? String ?? ""
        )
    }

    private func authenticate(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
                WebAuthSessionStore.shared.currentSession = nil
                if let error = error as? ASWebAuthenticationSessionError,
                   error.code == .canceledLogin {
                    continuation.resume(throwing: SocialAuthError.cancelled)
                    return
                }
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: SocialAuthError.invalidCallback)
                    return
                }
                continuation.resume(returning: callbackURL)
            }
            session.presentationContextProvider = PresentationContextProvider.shared
            session.prefersEphemeralWebBrowserSession = true
            WebAuthSessionStore.shared.currentSession = session
            session.start()
        }
    }

    private func authorizationCode(from callbackURL: URL) throws -> String {
        let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
        guard let code = components?.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw SocialAuthError.invalidCallback
        }
        return code
    }

    private func requestForm(url: URL, items: [String: String]) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = items
            .map { key, value in
                "\(Self.percentEncode(key))=\(Self.percentEncode(value))"
            }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
              200..<300 ~= statusCode else {
            throw SocialAuthError.invalidTokenResponse
        }
        return data
    }

    private static func percentEncode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
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

private final class WebAuthSessionStore {
    static let shared = WebAuthSessionStore()
    var currentSession: ASWebAuthenticationSession?
}

private final class PresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = PresentationContextProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
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
