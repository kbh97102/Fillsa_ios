import ComposableArchitecture

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var selectedTab: AppTab = .home
    }

    enum Action: Equatable {
        case selectedTabChanged(AppTab)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .selectedTabChanged(tab):
                state.selectedTab = tab
                return .none
            }
        }
    }
}
