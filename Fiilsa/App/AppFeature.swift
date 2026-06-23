import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var screen: AppScreen = .splash
        var splash = SplashFeature.State()
        var home = HomeFeature.State()
        var quoteList = QuoteListFeature.State()
        var calendar = CalendarFeature.State()
        var notice = NoticeFeature.State()
        var memoInsert = MemoInsertFeature.State()
        var typing = TypingFeature.State()
        var selectedTab: AppTab = .home
    }

    enum Action: Equatable {
        case splash(SplashFeature.Action)
        case home(HomeFeature.Action)
        case quoteList(QuoteListFeature.Action)
        case calendar(CalendarFeature.Action)
        case notice(NoticeFeature.Action)
        case memoInsert(MemoInsertFeature.Action)
        case typing(TypingFeature.Action)
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

        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }

        Scope(state: \.quoteList, action: \.quoteList) {
            QuoteListFeature()
        }

        Scope(state: \.calendar, action: \.calendar) {
            CalendarFeature()
        }

        Scope(state: \.memoInsert, action: \.memoInsert) {
            MemoInsertFeature()
        }

        Scope(state: \.typing, action: \.typing) {
            TypingFeature()
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

            case .memoInsert(.delegate(.back)):
                state.screen = .main
                state.selectedTab = .quoteList
                state.quoteList = QuoteListFeature.State()
                return .none

            case .memoInsert:
                return .none

            case .typing(.delegate(.back)):
                state.screen = .main
                state.selectedTab = .home
                state.home = HomeFeature.State()
                return .none

            case .typing:
                return .none

            case let .calendar(.delegate(.homeSelected(date))):
                state.screen = .main
                state.selectedTab = .home
                state.home = HomeFeature.State()
                state.home.date = date
                return .none

            case let .calendar(.delegate(.quoteListSelected(date))):
                state.screen = .main
                state.selectedTab = .quoteList
                state.quoteList = QuoteListFeature.State()
                state.quoteList.startDate = FillsaCalendarDateSupport.startOfMonth(for: date)
                state.quoteList.endDate = min(endOfMonth(for: date), Date())
                return .none

            case .home, .quoteList, .calendar:
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
                state.typing = TypingFeature.State(
                    dailyQuoteSeq: state.home.quote.dailyQuoteSeq,
                    korQuote: state.home.quote.korQuote ?? "",
                    engQuote: state.home.quote.engQuote ?? "",
                    korAuthor: state.home.quote.korAuthor ?? "",
                    engAuthor: state.home.quote.engAuthor ?? "",
                    likeYn: state.home.quote.likeYn
                )
                return .none

            case let .shareSelected(quote, author):
                state.screen = .share(quote: quote, author: author)
                return .none

            case let .quoteDetailSelected(data):
                state.screen = .quoteDetail(data)
                return .none

            case let .memoSelected(savedMemo, memberQuoteSeq):
                state.screen = .memoInsert(savedMemo: savedMemo, memberQuoteSeq: memberQuoteSeq)
                state.memoInsert = MemoInsertFeature.State(
                    savedMemo: savedMemo,
                    memberQuoteSeq: memberQuoteSeq
                )
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

    private func endOfMonth(for date: Date) -> Date {
        let startOfMonth = FillsaCalendarDateSupport.startOfMonth(for: date)
        let nextMonth = FillsaCalendarDateSupport.addMonths(1, to: startOfMonth)
        return FillsaCalendarDateSupport.calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? startOfMonth
    }
}
