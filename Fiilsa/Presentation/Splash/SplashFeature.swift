import ComposableArchitecture

@Reducer
struct SplashFeature {
    @ObservableState
    struct State: Equatable {
        var hasCheckedPermission = false
        var hasPlayedAnimation = false
        var isReady = false
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
                    }
                    await send(.permissionChecked)
                }

            case .permissionChecked:
                state.hasCheckedPermission = true
                guard state.hasCheckedPermission, state.hasPlayedAnimation, !state.isReady else {
                    return .none
                }
                return .run { send in
                    let isFirstOpen = (try? await sessionClient.isFirstOpen()) ?? true
                    if isFirstOpen {
                        try? await sessionClient.setFirstOpen(false)
                        await send(.ready(.login(isOnboarding: false)))
                    } else {
                        await send(.ready(.home))
                    }
                }

            case .animationCompleted:
                state.hasPlayedAnimation = true
                guard state.hasCheckedPermission, state.hasPlayedAnimation, !state.isReady else {
                    return .none
                }
                return .run { send in
                    let isFirstOpen = (try? await sessionClient.isFirstOpen()) ?? true
                    if isFirstOpen {
                        try? await sessionClient.setFirstOpen(false)
                        await send(.ready(.login(isOnboarding: false)))
                    } else {
                        await send(.ready(.home))
                    }
                }

            case let .ready(destination):
                state.isReady = true
                return .send(.delegate(.move(destination)))

            case .delegate:
                return .none
            }
        }
    }
}

enum SplashDestination: Equatable {
    case login(isOnboarding: Bool)
    case home
}
