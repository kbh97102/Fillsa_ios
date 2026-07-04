import Foundation

struct AuthConfig: Equatable {
    let googleClientID: String
    let googleRedirectURI: String
    let kakaoRestAPIKey: String
    let kakaoRedirectURI: String

    static var current: AuthConfig {
        let info = Bundle.main.infoDictionary ?? [:]
        return AuthConfig(
            googleClientID: info["GOOGLE_CLIENT_ID"] as? String ?? "",
            googleRedirectURI: info["GOOGLE_REDIRECT_URI"] as? String ?? "",
            kakaoRestAPIKey: info["KAKAO_REST_API_KEY"] as? String ?? "",
            kakaoRedirectURI: info["KAKAO_REDIRECT_URI"] as? String ?? ""
        )
    }
}
