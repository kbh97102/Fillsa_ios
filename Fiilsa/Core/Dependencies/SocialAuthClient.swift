import AuthenticationServices
import ComposableArchitecture
import CryptoKit
import Foundation
import UIKit

struct SocialAuthUser: Equatable {
    let provider: String
    let oauthID: String
    let nickname: String
    let profileImageURL: String
}

struct SocialAuthClient {
    var signInWithGoogle: @Sendable () async throws -> SocialAuthUser
    var signInWithKakao: @Sendable () async throws -> SocialAuthUser
}

extension SocialAuthClient: DependencyKey {
    static let liveValue = SocialAuthClient(
        signInWithGoogle: {
            try await WebSocialAuthClient(config: .current).signInWithGoogle()
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

    func signInWithGoogle() async throws -> SocialAuthUser {
        guard !config.googleClientID.isEmpty,
              let redirectURI = URL(string: config.googleRedirectURI),
              let callbackScheme = redirectURI.scheme else {
            throw SocialAuthError.missingConfiguration
        }

        let verifier = Self.codeVerifier()
        let challenge = Self.codeChallenge(from: verifier)

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: config.googleClientID),
            URLQueryItem(name: "redirect_uri", value: config.googleRedirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid email profile"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        guard let authURL = components?.url else {
            throw SocialAuthError.missingConfiguration
        }

        let callbackURL = try await authenticate(url: authURL, callbackScheme: callbackScheme)
        let code = try authorizationCode(from: callbackURL)
        let tokenData = try await requestForm(
            url: URL(string: "https://oauth2.googleapis.com/token")!,
            items: [
                "grant_type": "authorization_code",
                "code": code,
                "client_id": config.googleClientID,
                "redirect_uri": config.googleRedirectURI,
                "code_verifier": verifier
            ]
        )

        guard let token = try JSONSerialization.jsonObject(with: tokenData) as? [String: Any],
              let idToken = token["id_token"] as? String,
              let payload = Self.jwtPayload(idToken) else {
            throw SocialAuthError.invalidTokenResponse
        }

        return SocialAuthUser(
            provider: "GOOGLE",
            oauthID: payload["sub"] as? String ?? "",
            nickname: payload["name"] as? String ?? "",
            profileImageURL: payload["picture"] as? String ?? ""
        )
    }

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

    private static func codeVerifier() -> String {
        let bytes = (0..<32).map { _ in UInt8.random(in: 0...255) }
        return Data(bytes).base64URLEncodedString()
    }

    private static func codeChallenge(from verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URLEncodedString()
    }

    private static func jwtPayload(_ jwt: String) -> [String: Any]? {
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2,
              let data = Data(base64URLEncoded: String(parts[1])),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return object
    }

    private static func percentEncode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
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

private extension Data {
    init?(base64URLEncoded value: String) {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = 4 - base64.count % 4
        if padding < 4 {
            base64 += String(repeating: "=", count: padding)
        }
        self.init(base64Encoded: base64)
    }

    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
