import ComposableArchitecture

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var screen: AppScreen = .splash
        var splash = SplashFeature.State()
        var notice = NoticeFeature.State()
        var selectedTab: AppTab = .home
    }

    enum Action: Equatable {
        case splash(SplashFeature.Action)
        case notice(NoticeFeature.Action)
        case loginClosed
        case loginNonMemberSelected
        case loginSelected
        case homeTabSelected
        case quoteListTabSelected
        case homeTypingSelected
        case shareSelected(quote: String, author: String)
        case quoteDetailSelected(MemberQuotesResponse)
        case memoSelected(savedMemo: String, memberQuoteSeq: Int)
        case noticeSelected
        case noticeDetailSelected(NoticeResponse)
        case alertSelected
        case backToMain
        case onboardingGuideFinished
        case selectedTabChanged(AppTab)
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.splash, action: \.splash) {
            SplashFeature()
        }

        Scope(state: \.notice, action: \.notice) {
            NoticeFeature()
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

            case .notice(.delegate(.back)):
                state.screen = .main
                return .none

            case let .notice(.delegate(.noticeSelected(notice))):
                state.screen = .noticeDetail(notice)
                return .none

            case .notice:
                return .none

            case .loginClosed:
                state.screen = .main
                state.selectedTab = .home
                return .none

            case .loginNonMemberSelected:
                state.screen = .onboardingGuide
                return .none

            case .loginSelected:
                state.screen = .login(isOnboarding: false)
                return .none

            case .homeTabSelected:
                state.screen = .main
                state.selectedTab = .home
                return .none

            case .quoteListTabSelected:
                state.screen = .main
                state.selectedTab = .quoteList
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

            case .noticeSelected:
                state.screen = .notice
                state.notice = NoticeFeature.State()
                return .none

            case let .noticeDetailSelected(notice):
                state.screen = .noticeDetail(notice)
                return .none

            case .alertSelected:
                state.screen = .alert
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
