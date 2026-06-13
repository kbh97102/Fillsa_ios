struct LoginResponse: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let memberSeq: Int
    let nickname: String
    let profileImageUrl: String
}

struct TokenInfo: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
}

