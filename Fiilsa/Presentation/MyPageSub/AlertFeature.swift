import ComposableArchitecture
import UserNotifications

@Reducer
struct AlertFeature {
    @ObservableState
    struct State: Equatable {
        var isAlarmOn = false
        var isProcessing = false
        var toastMessage: String?
    }

    enum Action: Equatable {
        case onAppear
        case loaded(alarm: Bool)
        case alarmToggled(Bool)
        case alarmUpdateCompleted(Result<Bool, AlertError>)
        case toastDismissed
        case backTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case back
        }
    }

    enum AlertError: Error, Equatable {
        case denied
        case failed
    }

    @Dependency(\.settingsClient) private var settingsClient
    @Dependency(\.notificationPermissionClient) private var notificationPermissionClient
    @Dependency(\.pushRegistrationClient) private var pushRegistrationClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let alarm = (try? await settingsClient.getAlarm()) ?? false
                    await send(.loaded(alarm: alarm))
                }

            case let .loaded(alarm):
                state.isAlarmOn = alarm
                return .none

            case let .alarmToggled(isOn):
                state.isProcessing = true

                if isOn {
                    return .run { send in
                        do {
                            let status = await notificationPermissionClient.authorizationStatus()
                            let allowed: Bool

                            switch status {
                            case .authorized, .provisional, .ephemeral:
                                allowed = true

                            case .notDetermined:
                                allowed = await notificationPermissionClient.requestAuthorization()
                                try? await settingsClient.setAlarmPermissionRequestedBefore(true)

                            case .denied:
                                allowed = false

                            @unknown default:
                                allowed = false
                            }

                            guard allowed else {
                                await notificationPermissionClient.cancelDailyQuoteNotification()
                                try await settingsClient.setAlarm(false)
                                await send(.alarmUpdateCompleted(.failure(.denied)))
                                await pushRegistrationClient.synchronize(nil)
                                return
                            }

                            try await notificationPermissionClient.scheduleDailyQuoteNotification()
                            try await settingsClient.setAlarm(true)
                            await send(.alarmUpdateCompleted(.success(true)))
                            await pushRegistrationClient.synchronize(nil)
                        } catch {
                            await notificationPermissionClient.cancelDailyQuoteNotification()
                            try? await settingsClient.setAlarm(false)
                            await send(.alarmUpdateCompleted(.failure(.failed)))
                            await pushRegistrationClient.synchronize(nil)
                        }
                    }
                }

                return .run { send in
                    await notificationPermissionClient.cancelDailyQuoteNotification()
                    do {
                        try await settingsClient.setAlarm(false)
                        await send(.alarmUpdateCompleted(.success(false)))
                        await pushRegistrationClient.synchronize(nil)
                    } catch {
                        await send(.alarmUpdateCompleted(.failure(.failed)))
                    }
                }

            case let .alarmUpdateCompleted(.success(isOn)):
                state.isAlarmOn = isOn
                state.isProcessing = false
                state.toastMessage = isOn ? "알림이 설정되었습니다." : "알림이 해제되었습니다."
                return .none

            case let .alarmUpdateCompleted(.failure(error)):
                state.isAlarmOn = false
                state.isProcessing = false
                switch error {
                case .denied:
                    state.toastMessage = "알림 권한이 필요합니다."
                case .failed:
                    state.toastMessage = "알림 설정에 실패했습니다."
                }
                return .none

            case .toastDismissed:
                state.toastMessage = nil
                return .none

            case .backTapped:
                return .send(.delegate(.back))

            case .delegate:
                return .none
            }
        }
    }
}
