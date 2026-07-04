import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var screen: AppScreen = .splash
        var splash = SplashFeature.State()
        var login = LoginFeature.State()
        var home = HomeFeature.State()
        var quoteList = QuoteListFeature.State()
        var calendar = CalendarFeature.State()
        var myPage = MyPageFeature.State()
        var notice = NoticeFeature.State()
        var alert = AlertFeature.State()
        var memoInsert = MemoInsertFeature.State()
        var typing = TypingFeature.State()
        var share = ShareFeature.State()
        var generalPopup = GeneralPopupFeature.State()
        var selectedTab: AppTab = .home
        var isHandlingSessionExpiration = false
    }

    enum Action: Equatable {
        case task
        case splash(SplashFeature.Action)
        case login(LoginFeature.Action)
        case home(HomeFeature.Action)
        case quoteList(QuoteListFeature.Action)
        case calendar(CalendarFeature.Action)
        case myPage(MyPageFeature.Action)
        case notice(NoticeFeature.Action)
        case alert(AlertFeature.Action)
        case memoInsert(MemoInsertFeature.Action)
        case typing(TypingFeature.Action)
        case share(ShareFeature.Action)
        case generalPopup(GeneralPopupFeature.Action)
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
        case sessionExpired(SessionExpirationEvent)
        case sessionExpiredHandled
    }

    @Dependency(\.sessionClient) var sessionClient
    @Dependency(\.sessionExpirationClient) var sessionExpirationClient

    var body: some Reducer<State, Action> {
        Scope(state: \.splash, action: \.splash) {
            SplashFeature()
        }

        Scope(state: \.login, action: \.login) {
            LoginFeature()
        }

        Scope(state: \.notice, action: \.notice) {
            NoticeFeature()
        }

        Scope(state: \.alert, action: \.alert) {
            AlertFeature()
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

        Scope(state: \.myPage, action: \.myPage) {
            MyPageFeature()
        }

        Scope(state: \.memoInsert, action: \.memoInsert) {
            MemoInsertFeature()
        }

        Scope(state: \.typing, action: \.typing) {
            TypingFeature()
        }

        Scope(state: \.share, action: \.share) {
            ShareFeature()
        }

        Scope(state: \.generalPopup, action: \.generalPopup) {
            GeneralPopupFeature()
        }

        Reduce { state, action in
            switch action {
            case .task:
                return .run { send in
                    for await event in sessionExpirationClient.events() {
                        await send(.sessionExpired(event))
                    }
                }
                .cancellable(id: "sessionExpiration", cancelInFlight: true)

            case let .splash(.delegate(.move(destination))):
                switch destination {
                case let .login(isOnboarding):
                    state.screen = .login(isOnboarding: isOnboarding)
                    state.login = LoginFeature.State(isOnboarding: isOnboarding)
                case .home:
                    state.screen = .main
                    state.selectedTab = .home
                    return .send(.generalPopup(.loadIfNeeded))
                }
                return .none

            case .splash:
                return .none

            case .login(.delegate(.close)):
                state.screen = .main
                state.selectedTab = .home
                return .send(.generalPopup(.loadIfNeeded))

            case .login(.delegate(.moveHome)):
                state.screen = .main
                state.selectedTab = .home
                state.myPage = MyPageFeature.State()
                state.home = HomeFeature.State()
                return .send(.generalPopup(.loadIfNeeded))

            case .login(.delegate(.moveOnboardingGuide)):
                state.screen = .onboardingGuide
                return .none

            case .login:
                return .none

            case .notice(.delegate(.back)):
                state.screen = .main
                return .none

            case let .notice(.delegate(.noticeSelected(notice))):
                state.screen = .noticeDetail(notice)
                return .none

            case .notice:
                return .none

            case .alert(.delegate(.back)):
                state.screen = .main
                return .none

            case .alert(.delegate(.resignCompleted)):
                state.screen = .main
                state.selectedTab = .home
                state.home = HomeFeature.State()
                state.quoteList = QuoteListFeature.State()
                state.calendar = CalendarFeature.State()
                state.myPage = MyPageFeature.State()
                state.alert = AlertFeature.State()
                return .none

            case .alert:
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

            case .share(.delegate(.back)):
                state.screen = .main
                return .none

            case .share:
                return .none

            case .generalPopup:
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

            case .home(.likeUpdated(.success)):
                guard state.screen == .main, state.selectedTab == .quoteList else {
                    state.quoteList.hasLoaded = false
                    return .none
                }
                return .send(.quoteList(.refresh))

            case .home, .quoteList, .calendar:
                return .none

            case .myPage(.delegate(.homeSelected)):
                state.screen = .main
                state.selectedTab = .home
                return .send(.generalPopup(.loadIfNeeded))

            case .myPage(.delegate(.loginSelected)):
                state.screen = .login(isOnboarding: false)
                state.login = LoginFeature.State(isOnboarding: false)
                return .none

            case .myPage(.delegate(.noticeSelected)):
                state.screen = .notice
                state.notice = NoticeFeature.State()
                return .none

            case .myPage(.delegate(.alertSelected)):
                state.screen = .alert
                state.alert = AlertFeature.State()
                return .none

            case .myPage:
                return .none

            case .loginClosed:
                state.screen = .main
                state.selectedTab = .home
                return .send(.generalPopup(.loadIfNeeded))

            case .loginNonMemberSelected:
                state.screen = .onboardingGuide
                return .none

            case .loginSelected:
                state.screen = .login(isOnboarding: false)
                state.login = LoginFeature.State(isOnboarding: false)
                return .none

            case .homeTabSelected:
                state.screen = .main
                state.selectedTab = .home
                return .send(.generalPopup(.loadIfNeeded))

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
                state.share = ShareFeature.State(quote: quote, author: author)
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
                return .send(.generalPopup(.loadIfNeeded))

            case let .selectedTabChanged(tab):
                state.selectedTab = tab
                if tab == .quoteList {
                    return .send(.quoteList(.refresh))
                }
                if tab == .home || tab == .myPage {
                    return .send(.generalPopup(.loadIfNeeded))
                }
                return .none

            case .sessionExpired:
                guard !state.isHandlingSessionExpiration else {
                    return .none
                }
                state.isHandlingSessionExpiration = true
                return .run { send in
                    try await sessionClient.logout()
                    await send(.sessionExpiredHandled)
                } catch: { _, send in
                    await send(.sessionExpiredHandled)
                }

            case .sessionExpiredHandled:
                state.isHandlingSessionExpiration = false
                state.screen = .main
                state.selectedTab = .home
                state.home = HomeFeature.State()
                state.quoteList = QuoteListFeature.State()
                state.calendar = CalendarFeature.State()
                state.myPage = MyPageFeature.State()
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
