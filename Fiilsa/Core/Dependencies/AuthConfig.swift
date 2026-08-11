import Foundation

struct AuthConfig: Equatable {
    let kakaoNativeAppKey: String

    static var current: AuthConfig {
        let info = Bundle.main.infoDictionary ?? [:]
        return AuthConfig(
            kakaoNativeAppKey: value(for: "KAKAO_NATIVE_APP_KEY", in: info)
        )
    }

    private static func value(for key: String, in info: [String: Any]) -> String {
        let rawValue = info[key] as? String ?? ""
        return rawValue.contains("$(") ? "" : rawValue
    }
}
