import ComposableArchitecture

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var screen: AppScreen = .splash
        var splash = SplashFeature.State()
        var selectedTab: AppTab = .home
    }

    enum Action: Equatable {
        case splash(SplashFeature.Action)
        case selectedTabChanged(AppTab)
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.splash, action: \.splash) {
            SplashFeature()
        }

        Reduce { state, action in
            switch action {
            case let .splash(.delegate(.move(destination))):
                switch destination {
                case let .login(isOnboarding):
                    state.screen = .login(isOnboarding: isOnboarding)
                case .home:
                    state.screen = .main
                    state.selectedTab = .home
                }
                return .none

            case .splash:
                return .none

            case let .selectedTabChanged(tab):
                state.selectedTab = tab
                return .none
            }
        }
    }
}
