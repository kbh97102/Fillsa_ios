import ComposableArchitecture

struct HiddenPopupClient {
    var add: @Sendable (_ seq: Int) async throws -> Void
    var isHidden: @Sendable (_ seq: Int) async throws -> Bool
    var clearAll: @Sendable () async throws -> Void
}

extension HiddenPopupClient: DependencyKey {
    static let liveValue: HiddenPopupClient = {
        let repository = LiveRepositories.local

        return HiddenPopupClient(
            add: { seq in
                try await AddHiddenPopupUseCase(localRepository: repository)(seq: seq)
            },
            isHidden: { seq in
                try await CheckPopupIsHiddenUseCase(localRepository: repository)(seq: seq)
            },
            clearAll: {
                try await ClearAllHiddenPopupUseCase(localRepository: repository)()
            }
        )
    }()
}

extension DependencyValues {
    var hiddenPopupClient: HiddenPopupClient {
        get { self[HiddenPopupClient.self] }
        set { self[HiddenPopupClient.self] = newValue }
    }
}
