import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        enum MemberAccess: Equatable { case unknown, member, loginRequired }

        var memberAccess: MemberAccess = .unknown
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
        var selectedTheme: DarkModeType = .system
        var isHandlingSessionExpiration = false
        var activeLoadingCount = 0
        var isGlobalLoading: Bool { activeLoadingCount > 0 && screen != .splash }

        mutating func routeToLoginAndClearMemberState() {
            memberAccess = .loginRequired
            screen = .login
            login = LoginFeature.State()
            home = HomeFeature.State()
            quoteList = QuoteListFeature.State()
            calendar = CalendarFeature.State()
            myPage = MyPageFeature.State(selectedTheme: selectedTheme)
            notice = NoticeFeature.State()
            alert = AlertFeature.State()
            memoInsert = MemoInsertFeature.State()
            typing = TypingFeature.State()
            share = ShareFeature.State()
            generalPopup = GeneralPopupFeature.State()
            selectedTab = .home
        }
    }

    enum Action: Equatable {
        case task
        case loadingCountChanged(Int)
        case themeLoaded(DarkModeType)
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
        case memberAccessLost
        case memberAccessLostHandled
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
        case sessionExpirationIgnored
        case fcmTokenUpdated(String)
    }

    @Dependency(\.sessionClient) var sessionClient
    @Dependency(\.sessionExpirationClient) var sessionExpirationClient
    @Dependency(\.settingsClient) var settingsClient
    @Dependency(\.pushTokenClient) var pushTokenClient
    @Dependency(\.pushRegistrationClient) var pushRegistrationClient
    @Dependency(\.loadingClient) var loadingClient

    nonisolated private enum CancelID: Hashable { case loadingSubscription }

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
            if state.memberAccess != .member {
                switch action {
                case .home, .quoteList, .calendar, .notice, .alert, .memoInsert, .typing, .share,
                     .myPage, .homeTabSelected, .quoteListTabSelected, .homeTypingSelected,
                     .shareSelected, .quoteDetailSelected, .memoSelected, .noticeSelected,
                     .noticeDetailSelected, .alertSelected, .backToMain, .selectedTabChanged:
                    state.routeToLoginAndClearMemberState()
                    return .none
                default:
                    break
                }
            }
            switch action {
            case .task:
                let loadingSubscription: Effect<Action> = .run { send in
                    for await count in await loadingClient.counts() {
                        await send(.loadingCountChanged(count))
                    }
                }
                .cancellable(id: CancelID.loadingSubscription, cancelInFlight: true)
                guard !ProcessInfo.processInfo.arguments.contains("-uiTestingQuoteList"),
                      !ProcessInfo.processInfo.arguments.contains("-ui-testing-home"),
                      !ProcessInfo.processInfo.arguments.contains("-ui-testing-login"),
                      !ProcessInfo.processInfo.arguments.contains("-ui-testing-notice-detail"),
                      !ProcessInfo.processInfo.arguments.contains("-ui-testing-memo"),
                      !ProcessInfo.processInfo.arguments.contains("-ui-testing-onboarding-guide") else {
                    return loadingSubscription
                }
                return .merge(
                    loadingSubscription,
                    .run { send in
                        let selectedTheme = (try? await settingsClient.getDarkModeType()) ?? .system
                        await send(.themeLoaded(selectedTheme))
                    },
                    .run { send in
                        for await event in sessionExpirationClient.events() {
                            await send(.sessionExpired(event))
                        }
                    }
                    .cancellable(id: "sessionExpiration", cancelInFlight: true),
                    .run { _ in
                        await pushRegistrationClient.synchronizeIfNeeded()
                    },
                    .run { send in
                        for await token in pushTokenClient.tokenUpdates() {
                            await send(.fcmTokenUpdated(token))
                        }
                    }
                    .cancellable(id: "fcmTokenUpdates", cancelInFlight: true)
                )

            case let .loadingCountChanged(count):
                state.activeLoadingCount = count
                return .none

            case let .themeLoaded(selectedTheme):
                state.selectedTheme = selectedTheme
                state.myPage.selectedTheme = selectedTheme
                return .none

            case let .fcmTokenUpdated(token):
                return .run { _ in
                    await pushRegistrationClient.synchronize(token)
                }

            case let .splash(.delegate(.move(destination))):
                guard state.screen == .splash, state.memberAccess == .unknown else { return .none }
                switch destination {
                case .login:
                    state.routeToLoginAndClearMemberState()
                case .home:
                    state.memberAccess = .member
                    state.screen = .main
                    state.selectedTab = .home
                    return .send(.generalPopup(.loadIfNeeded))
                }
                return .none

            case .splash:
                return .none

            case .login(.delegate(.moveHome)):
                state.memberAccess = .member
                state.screen = .main
                state.selectedTab = .home
                state.myPage = MyPageFeature.State(selectedTheme: state.selectedTheme)
                state.home = HomeFeature.State()
                return .send(.generalPopup(.loadIfNeeded))

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

            case .calendar(.delegate(.memberAccessLost)):
                return .send(.memberAccessLost)

            case .home(.likeUpdated(.success)):
                guard state.screen == .main, state.selectedTab == .quoteList else {
                    state.quoteList.hasLoaded = false
                    return .none
                }
                return .send(.quoteList(.refresh))

            case .home(.answerSaved(_, .success)):
                state.calendar.hasLoaded = false
                return .none

            case .calendar(.answerSaved(_, .success)):
                state.home.hasLoaded = false
                return .none

            case .home, .quoteList, .calendar:
                return .none

            case .myPage(.delegate(.homeSelected)):
                state.screen = .main
                state.selectedTab = .home
                return .send(.generalPopup(.loadIfNeeded))

            case .myPage(.delegate(.memberAccessLost)):
                return .send(.memberAccessLost)

            case .myPage(.delegate(.loggedOut)):
                state.routeToLoginAndClearMemberState()
                return .none

            case .myPage(.delegate(.noticeSelected)):
                state.screen = .notice
                state.notice = NoticeFeature.State()
                return .none

            case .myPage(.delegate(.alertSelected)):
                state.screen = .alert
                state.alert = AlertFeature.State()
                return .none

            case let .myPage(.themeSelected(theme)):
                state.selectedTheme = theme
                return .none

            case .myPage(.delegate(.resignCompleted)):
                state.routeToLoginAndClearMemberState()
                return .none

            case .myPage:
                return .none

            case .memberAccessLost:
                guard state.memberAccess == .member, !state.isHandlingSessionExpiration else { return .none }
                state.isHandlingSessionExpiration = true
                return .run { send in
                    try? await sessionClient.logout()
                    await send(.memberAccessLostHandled)
                }

            case .memberAccessLostHandled:
                state.isHandlingSessionExpiration = false
                state.routeToLoginAndClearMemberState()
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
                state.typing = typingState(from: state.home)
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
                guard state.memberAccess == .member else {
                    state.routeToLoginAndClearMemberState()
                    return .none
                }
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

            case let .sessionExpired(event):
                guard state.memberAccess == .member, !state.isHandlingSessionExpiration else {
                    return .none
                }
                state.isHandlingSessionExpiration = true
                return .run { send in
                    if let currentToken = try? await sessionClient.getAccessToken(), !currentToken.isEmpty {
                        guard event.failedAccessTokenFingerprint == SessionExpirationEvent.fingerprint(of: currentToken) else {
                            await send(.sessionExpirationIgnored)
                            return
                        }
                    }
                    try? await sessionClient.logout()
                    await send(.sessionExpiredHandled)
                }

            case .sessionExpirationIgnored:
                state.isHandlingSessionExpiration = false
                return .none

            case .sessionExpiredHandled:
                state.isHandlingSessionExpiration = false
                state.routeToLoginAndClearMemberState()
                return .none
            }
        }
    }

    private func typingState(from home: HomeFeature.State) -> TypingFeature.State {
        TypingFeature.State(
            dailyQuoteSeq: home.quote.dailyQuoteSeq,
            korQuote: home.quote.korQuote ?? "",
            engQuote: home.quote.engQuote ?? "",
            korAuthor: home.quote.korAuthor ?? "",
            engAuthor: home.quote.engAuthor ?? "",
            likeYn: home.quote.likeYn,
            quoteDate: FillsaCalendarDateSupport.quoteDateString(for: home.date),
            dayOfWeek: dayOfWeekString(for: home.date)
        )
    }

    private func endOfMonth(for date: Date) -> Date {
        let startOfMonth = FillsaCalendarDateSupport.startOfMonth(for: date)
        let nextMonth = FillsaCalendarDateSupport.addMonths(1, to: startOfMonth)
        return FillsaCalendarDateSupport.calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? startOfMonth
    }

    private func dayOfWeekString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).uppercased()
    }
}
