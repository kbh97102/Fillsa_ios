import Foundation

struct AuthConfig: Equatable {
    let kakaoRestAPIKey: String
    let kakaoRedirectURI: String

    static var current: AuthConfig {
        let info = Bundle.main.infoDictionary ?? [:]
        return AuthConfig(
            kakaoRestAPIKey: value(for: "KAKAO_REST_API_KEY", in: info),
            kakaoRedirectURI: value(for: "KAKAO_REDIRECT_URI", in: info)
        )
    }

    private static func value(for key: String, in info: [String: Any]) -> String {
        let rawValue = info[key] as? String ?? ""
        return rawValue.contains("$(") ? "" : rawValue
    }
}
