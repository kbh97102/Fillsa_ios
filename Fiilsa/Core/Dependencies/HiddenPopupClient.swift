import ComposableArchitecture
import Foundation

struct HiddenPopupClient {
    var add: @Sendable (_ seq: Int) async throws -> Void
    var isHidden: @Sendable (_ seq: Int) async throws -> Bool
    var clearAll: @Sendable () async throws -> Void
    var clearAllIfNeeded: @Sendable () async throws -> Void
}

extension HiddenPopupClient: DependencyKey {
    static let liveValue: HiddenPopupClient = {
        let repository = LiveRepositories.local
        let dailyResetStore = HiddenPopupDailyResetStore()

        return HiddenPopupClient(
            add: { seq in
                try await AddHiddenPopupUseCase(localRepository: repository)(seq: seq)
            },
            isHidden: { seq in
                try await CheckPopupIsHiddenUseCase(localRepository: repository)(seq: seq)
            },
            clearAll: {
                try await ClearAllHiddenPopupUseCase(localRepository: repository)()
            },
            clearAllIfNeeded: {
                guard await dailyResetStore.shouldClearTodayHiddenPopups() else { return }
                try await ClearAllHiddenPopupUseCase(localRepository: repository)()
                await dailyResetStore.markCleared()
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

private struct HiddenPopupDailyResetStore {
    private let userDefaults: UserDefaults
    private let calendar: Calendar

    init(
        userDefaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.userDefaults = userDefaults
        self.calendar = calendar
    }

    func shouldClearTodayHiddenPopups(now: Date = Date()) -> Bool {
        guard let lastCleared = userDefaults.object(forKey: Key.lastClearedDate) as? Date else {
            return true
        }
        return !calendar.isDate(lastCleared, inSameDayAs: now)
    }

    func markCleared(now: Date = Date()) {
        userDefaults.set(now, forKey: Key.lastClearedDate)
    }

    private enum Key {
        static let lastClearedDate = "HIDDEN_POPUP_LAST_CLEARED_DATE"
    }
}
