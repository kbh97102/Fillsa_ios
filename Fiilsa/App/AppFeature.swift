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
        case loginClosed
        case loginNonMemberSelected
        case homeTypingSelected
        case shareSelected(quote: String, author: String)
        case quoteDetailSelected(MemberQuotesResponse)
        case memoSelected(savedMemo: String, memberQuoteSeq: Int)
        case backToMain
        case onboardingGuideFinished
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

            case .loginClosed:
                state.screen = .main
                state.selectedTab = .home
                return .none

            case .loginNonMemberSelected:
                state.screen = .onboardingGuide
                return .none

            case .homeTypingSelected:
                state.screen = .typing
                return .none

            case let .shareSelected(quote, author):
                state.screen = .share(quote: quote, author: author)
                return .none

            case let .quoteDetailSelected(data):
                state.screen = .quoteDetail(data)
                return .none

            case let .memoSelected(savedMemo, memberQuoteSeq):
                state.screen = .memoInsert(savedMemo: savedMemo, memberQuoteSeq: memberQuoteSeq)
                return .none

            case .backToMain:
                state.screen = .main
                return .none

            case .onboardingGuideFinished:
                state.screen = .main
                state.selectedTab = .home
                return .none

            case let .selectedTabChanged(tab):
                state.selectedTab = tab
                return .none
            }
        }
    }
}
