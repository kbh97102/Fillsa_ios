struct LoginRequest: Codable, Equatable {
    let loginData: LoginData
    let syncData: [DailySyncData]
}

struct LoginData: Codable, Equatable {
    let deviceData: DeviceData
    let userData: UserData
}

struct DeviceData: Codable, Equatable {
    let deviceId: String
    let osType: String
    let appVersion: String
    let osVersion: String
    let deviceModel: String
}

struct UserData: Codable, Equatable {
    let oAuthProvider: String
    let oAuthId: String
    let nickname: String
    let profileImageUrl: String
}

struct DailySyncData: Codable, Equatable {
    let dailyQuoteSeq: Int
    let typingQuoteRequest: TypingQuoteRequest
    let memoRequest: MemoRequest
    let likeRequest: LikeRequest
}

struct TokenRefreshRequest: Codable, Equatable {
    let deviceId: String
    let refreshToken: String
}

