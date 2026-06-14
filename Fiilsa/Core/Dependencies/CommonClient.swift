import ComposableArchitecture

struct CommonClient {
    var getNotice: @Sendable (_ page: Int, _ size: Int) async throws -> PageResponseNoticeResponse
    var getMemberStreaks: @Sendable () async throws -> MemberStreakResponse
    var getPopupGeneral: @Sendable () async throws -> PopupResponse
    var getPopupVersionUpdate: @Sendable (_ currentVersion: String) async throws -> PopupResponse
    var deleteResign: @Sendable () async throws -> Int
}

extension CommonClient: DependencyKey {
    static let liveValue: CommonClient = {
        let repository = LiveRepositories.common

        return CommonClient(
            getNotice: { page, size in
                try await repository.getNotice(page: page, size: size)
            },
            getMemberStreaks: {
                try await repository.getMemberStreaks()
            },
            getPopupGeneral: {
                try await repository.getPopupGeneral()
            },
            getPopupVersionUpdate: { currentVersion in
                try await repository.getPopupVersionUpdate(currentVersion: currentVersion)
            },
            deleteResign: {
                try await repository.deleteResign()
            }
        )
    }()
}

extension DependencyValues {
    var commonClient: CommonClient {
        get { self[CommonClient.self] }
        set { self[CommonClient.self] = newValue }
    }
}
