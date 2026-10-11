import ComposableArchitecture
import UserNotifications

@Reducer
struct SplashFeature {
    @ObservableState
    struct State: Equatable {
        var hasCheckedPermission = false
        var hasPlayedAnimation = false
        var isReady = false
        var isResolvingDestination = false
    }

    enum Action: Equatable {
        case onAppear
        case permissionChecked
        case animationCompleted
        case ready(SplashDestination)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case move(SplashDestination)
        }
    }

    @Dependency(\.notificationPermissionClient) var notificationPermissionClient
    @Dependency(\.pushRegistrationClient) var pushRegistrationClient
    @Dependency(\.sessionClient) var sessionClient
    @Dependency(\.settingsClient) var settingsClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let wasRequested = (try? await settingsClient.isAlarmPermissionRequestedBefore()) ?? false
                    if !wasRequested {
                        let allowed = await notificationPermissionClient.requestAuthorization()
                        try? await settingsClient.setAlarmPermissionRequestedBefore(true)
                        try? await settingsClient.setAlarm(allowed)
                        if allowed {
                            try? await notificationPermissionClient.scheduleDailyQuoteNotification()
                        } else {
                            await notificationPermissionClient.cancelDailyQuoteNotification()
                        }
                    } else if ((try? await settingsClient.getAlarm()) ?? false) {
                        let status = await notificationPermissionClient.authorizationStatus()
                        switch status {
                        case .authorized, .provisional, .ephemeral:
                            try? await notificationPermissionClient.scheduleDailyQuoteNotification()
                        default:
                            await notificationPermissionClient.cancelDailyQuoteNotification()
                            try? await settingsClient.setAlarm(false)
                        }
                    }
                    await send(.permissionChecked)
                    await pushRegistrationClient.synchronize(nil)
                }

            case .permissionChecked:
                state.hasCheckedPermission = true
                guard state.hasCheckedPermission, state.hasPlayedAnimation,
                      !state.isReady, !state.isResolvingDestination else {
                    return .none
                }
                state.isResolvingDestination = true
                return resolveDestination()

            case .animationCompleted:
                state.hasPlayedAnimation = true
                guard state.hasCheckedPermission, state.hasPlayedAnimation,
                      !state.isReady, !state.isResolvingDestination else {
                    return .none
                }
                state.isResolvingDestination = true
                return resolveDestination()

            case let .ready(destination):
                state.isReady = true
                state.isResolvingDestination = false
                return .send(.delegate(.move(destination)))

            case .delegate:
                return .none
            }
        }
    }

    private func resolveDestination() -> Effect<Action> {
        .run { send in
            let isFirstOpen = (try? await sessionClient.isFirstOpen()) ?? true
            if isFirstOpen {
                try? await sessionClient.setFirstOpen(false)
            }
            let isLoggedIn = (try? await sessionClient.isLoggedIn()) ?? false
            await send(.ready(isLoggedIn ? .home : .login))
        }
    }
}

enum SplashDestination: Equatable {
    case login
    case home
}
