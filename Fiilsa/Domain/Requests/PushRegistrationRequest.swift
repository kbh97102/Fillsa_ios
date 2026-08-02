struct PushRegistrationRequest: Codable, Equatable {
    let deviceId: String
    let pushToken: String
    let agreed: Bool
}
