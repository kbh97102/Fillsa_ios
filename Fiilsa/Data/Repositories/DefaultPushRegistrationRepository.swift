import Foundation

struct DefaultPushRegistrationRepository: PushRegistrationRepository {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClientFactory.authenticated(deviceIDProvider: { DeviceIDProvider.current() })) {
        self.apiClient = apiClient
    }

    func registerPushDevice(_ requestBody: PushRegistrationRequest) async throws {
        let request = APIRequest(
            method: .put,
            path: APIEndpoint.pushDevice,
            body: requestBody
        )
        _ = try await apiClient.send(request, responseType: EmptyResponse.self)
    }
}
