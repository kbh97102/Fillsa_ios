protocol PushRegistrationRepository {
    func registerPushDevice(_ request: PushRegistrationRequest) async throws
}
