//
//  FiilsaApp.swift
//  Fiilsa
//
//  Created by 강보훈 on 6/13/26.
//

import SwiftUI
import ComposableArchitecture
import KakaoSDKAuth
import IssueReporting

@main
struct FiilsaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            if !isTesting {
                AppView(
                    store: appStore
                )
                .onOpenURL { url in
                    guard AuthApi.isKakaoTalkLoginUrl(url) else { return }
                    _ = AuthController.handleOpenUrl(url: url)
                }
            }
        }
    }

    private var launchState: AppFeature.State {
        let arguments = ProcessInfo.processInfo.arguments
        if let screenArgument = arguments.first(where: { $0.hasPrefix("-ui-testing-global-loading-screen=") }) {
            return globalLoadingState(for: String(screenArgument.dropFirst("-ui-testing-global-loading-screen=".count)))
        }
        var state = AppFeature.State()

        if arguments.contains("ui-testing-calendar") {
            state.memberAccess = .member
            state.screen = .main
            state.selectedTab = .calendar
            state.selectedTheme = arguments.contains("ui-testing-theme-dark") ? .dark : .light
            let selectedDay = Self.calendarUITestDate
            state.calendar.currentMonth = FillsaCalendarDateSupport.startOfMonth(for: selectedDay)
            state.calendar.selectedDay = selectedDay
            state.calendar.memberQuotes = Self.calendarUITestQuotes(
                completed: arguments.contains("ui-testing-calendar-completed")
            )
            if arguments.contains("ui-testing-calendar-answer-saved") {
                let answer = "오늘의 질문에 답을 기록했어요."
                state.calendar.memberQuotes.indices.forEach { index in
                    if state.calendar.memberQuotes[index].quoteDate == "2025-03-21" {
                        state.calendar.memberQuotes[index].answer = answer
                    }
                }
                state.calendar.answerDraft = answer
                state.calendar.recordedAnswer = answer
                state.calendar.isEditingAnswer = false
                state.calendar.isLoggedIn = true
            }
            let count = arguments.contains("ui-testing-calendar-completed") ? 4 : 3
            state.calendar.monthlySummary = MonthlySummaryData(
                typingCount: count,
                likeCount: arguments.contains("ui-testing-calendar-completed") ? 4 : 2,
                streakCount: 100
            )
            state.calendar.displayStreakCount = 100
            state.calendar.hasLoaded = true
            return state
        }

        if arguments.contains("-ui-testing-home") {
            state.memberAccess = .member
            let imageFixture = arguments.contains("-ui-testing-home-image-wide") ? "home-dialog-wide" :
                arguments.contains("-ui-testing-home-image-tall") ? "home-dialog-tall" : nil
            let imagePath = imageFixture.flatMap {
                Bundle.main.url(forResource: $0, withExtension: "png", subdirectory: "UITestFixtures") ??
                    Bundle.main.url(forResource: $0, withExtension: "png")
            }?.absoluteString ?? ""
            let homeQuote = arguments.contains("-ui-testing-home-long-quote")
                ? "사랑은 상대를 바꾸려는 마음이 아니라 서로 다른 시간을 이해하고 기다리며, 늦게 도착한 진심까지도 다치지 않게 받아들이는 오래된 연습이다. 그 연습은 오늘의 작은 친절에서 다시 시작된다."
                : "사랑이라는 선물은 억지로 줄 수 없고 받아들여지기를 기다릴 뿐이다."
            state.screen = .main
            state.selectedTab = .home
            state.selectedTheme = arguments.contains("ui-testing-theme-dark") ? .dark : .light
            state.home = HomeFeature.State(
                quote: DailyQuote(
                    likeYn: "N",
                    imagePath: imagePath,
                    dailyQuoteSeq: 1,
                    korQuote: homeQuote,
                    engQuote: "Love is a gift that waits to be received.",
                    korAuthor: "존우든",
                    engAuthor: "John Wooden",
                    authorUrl: "",
                    quoteDate: "2026-08-12"
                ),
                date: Self.homeUITestDate,
                isLoggedIn: true,
                hasLoaded: true
            )
            state.home.isStreakStateLoaded = true
            state.home.streakCount = 100
            state.home.completedWritingDates = ["2026-08-10", "2026-08-11"]
            if arguments.contains("-ui-testing-home-weekly-cache") {
                let week = Self.homeUITestWeek
                state.home.serverToday = week.endDate
                state.home.weeklyWindows[week.endDate] = week
                state.home.quote = week.day("2026-08-16")!.asDailyQuote
            }
            if arguments.contains("-ui-testing-home-zero-streak") {
                state.home.streakCount = nil
            }
            if arguments.contains("-ui-testing-home-calendar-open") {
                state.home.isCalendarPresented = true
                state.home.calendarDisplayedMonth = FillsaCalendarDateSupport.startOfMonth(for: Self.homeUITestDate)
            }
            if arguments.contains("-ui-testing-home-question-done") {
                state.home.answerDraft = "친구가 힘들 때 언제든 연락하라고 했는데, 한참 뒤에야 그 말이 진심이었다는 걸 믿고 먼저 연락한 적이 있어요."
                state.home.recordedAnswer = state.home.answerDraft
                state.home.isEditingAnswer = false
                state.home.toastMessage = "답변을 기록했어요."
            }
            if arguments.contains("-ui-testing-home-streak-tooltip") {
                state.home.isStreakStateLoaded = true
                state.home.isStreakTooltipPresented = true
            }
            if arguments.contains("-ui-testing-home-image-modal") {
                state.home.isImageDialogPresented = true
            }
            if arguments.contains("-ui-testing-global-loading") {
                state.activeLoadingCount = 1
            }
            return state
        }

        guard arguments.contains("-uiTestingQuoteList") else { return state }
        state.memberAccess = .member
        state.screen = .main
        state.selectedTab = .quoteList
        state.selectedTheme = arguments.contains("-uiTestingDark") ? .dark : .light
        state.quoteList.hasLoaded = true

        if arguments.contains("-uiTestingQuoteListFilteredEmpty") {
            state.quoteList.list = []
            state.quoteList.hasAppliedSearchCondition = true
        } else if arguments.contains("-uiTestingQuoteListGeneralEmpty") {
            state.quoteList.list = []
        } else {
            state.quoteList.list = QuoteListSampleData.items
        }

        return state
    }

    private func globalLoadingState(for screen: String) -> AppFeature.State {
        var state = AppFeature.State()
        state.selectedTheme = .light
        state.activeLoadingCount = 1

        switch screen {
        case "splash":
            state.splash.isReady = true
        case "login":
            state.memberAccess = .loginRequired
            state.screen = .login
            state.login = LoginFeature.State()
        case "onboardingGuide":
            state.screen = .onboardingGuide
        case "home":
            state.memberAccess = .member
            state.screen = .main
            state.home.date = Self.homeUITestDate
            state.home.hasLoaded = true
            state.home.isStreakStateLoaded = true
        case "quoteList":
            state.memberAccess = .member
            state.screen = .main
            state.selectedTab = .quoteList
            state.quoteList.hasLoaded = true
            state.quoteList.list = QuoteListSampleData.items
        case "calendar":
            state.memberAccess = .member
            state.screen = .main
            state.selectedTab = .calendar
            state.calendar.hasLoaded = true
        case "myPage":
            state.memberAccess = .member
            state.screen = .main
            state.selectedTab = .myPage
        case "typing":
            state.memberAccess = .member
            state.screen = .typing
            state.typing.hasLoaded = true
            state.typing.korQuote = "사랑이라는 선물은 억지로 줄 수 없고 받아들여지기를 기다릴 뿐이다."
            state.typing.korAuthor = "존 우든"
        case "share":
            state.memberAccess = .member
            state.screen = .share(quote: "사랑이라는 선물은 억지로 줄 수 없고 받아들여지기를 기다릴 뿐이다.", author: "존 우든")
            state.share = ShareFeature.State(quote: "사랑이라는 선물은 억지로 줄 수 없고 받아들여지기를 기다릴 뿐이다.", author: "존 우든")
        case "quoteDetail":
            state.memberAccess = .member
            state.screen = .quoteDetail(QuoteListSampleData.items[0])
        case "memoInsert":
            state.memberAccess = .member
            state.screen = .memoInsert(savedMemo: "", memberQuoteSeq: 1)
            state.memoInsert = MemoInsertFeature.State(savedMemo: "", memberQuoteSeq: 1)
        case "notice":
            state.memberAccess = .member
            state.screen = .notice
            state.notice.notices = NoticeSampleData.items
            state.notice.hasLoaded = true
        case "noticeDetail":
            state.memberAccess = .member
            state.screen = .noticeDetail(NoticeSampleData.items[0])
        case "alert":
            state.memberAccess = .member
            state.screen = .alert
        default:
            break
        }
        return state
    }

    private static let homeUITestDate: Date = {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(identifier: "Asia/Seoul")
        components.year = 2026
        components.month = 8
        components.day = 16
        return components.date ?? Date(timeIntervalSince1970: 0)
    }()

    private static let homeUITestWeek: MemberWeeklyQuoteResponse = {
        let days = (10...16).map { day in
            MemberQuoteDay(
                date: String(format: "2026-08-%02d", day),
                dayOfWeek: "",
                state: day == 16 ? "today" : "none",
                dailyQuoteSeq: day,
                korQuote: day == 16 ? "오늘의 명언" : String(format: "%d일의 명언", day),
                engQuote: "Quote for day \(day)",
                korAuthor: "존우든",
                engAuthor: "John Wooden",
                authorUrl: "",
                questionKo: "오늘의 질문",
                questionEn: "Question of the day",
                answer: nil,
                answeredAt: nil,
                likeYn: "N",
                imagePath: "",
                completed: false
            )
        }
        return MemberWeeklyQuoteResponse(startDate: "2026-08-10", endDate: "2026-08-16", days: days)
    }()

    private static let calendarUITestDate: Date = {
        FillsaCalendarDateSupport.calendar.date(
            from: DateComponents(year: 2025, month: 3, day: ProcessInfo.processInfo.arguments.contains("ui-testing-calendar-completed") ? 21 : 17)
        ) ?? Date(timeIntervalSince1970: 0)
    }()

    private static func calendarUITestQuotes(completed: Bool) -> [MemberQuotesData] {
        let selectedQuote = completed
            ? "영광은 먼지와 땀과 피로 얼굴이 얼룩진 채 경기장에 서 있는 사람의 것이다."
            : "인간은 자연에서 가장 연약한 한 줄기 갈대일 뿐이지만, 생각하는 갈대이다."
        let selectedDay = completed ? 21 : 17
        let recordedDays = completed ? [18, 19, 20, 21] : [18, 19, 20]

        return recordedDays.map { day in
            MemberQuotesData(
                dailyQuoteSeq: day,
                quoteDate: String(format: "2025-03-%02d", day),
                quote: day == selectedDay ? selectedQuote : "테스트 명언",
                author: "",
                completed: true,
                likeYn: completed || day != 18 ? "Y" : "N",
                todayCompleted: true
            )
        } + (completed ? [] : [
            MemberQuotesData(
                dailyQuoteSeq: selectedDay,
                quoteDate: String(format: "2025-03-%02d", selectedDay),
                quote: selectedQuote,
                author: "",
                completed: false,
                likeYn: "N",
                todayCompleted: false
            )
        ])
    }

    private var appStore: StoreOf<AppFeature> {
        if ProcessInfo.processInfo.arguments.contains(where: { $0.hasPrefix("-ui-testing-global-loading-screen=") }) {
            Store(initialState: launchState) {
                AppFeature()
            } withDependencies: {
                $0.settingsClient.isAlarmPermissionRequestedBefore = { true }
                $0.settingsClient.getAlarm = { false }
                $0.settingsClient.getShareDescriptionVisible = { false }
                $0.pushRegistrationClient.synchronize = { _ in }
                $0.sessionClient.isLoggedIn = { true }
            }
        } else if OnboardingGuideUITestLaunchConfiguration.isEnabled {
            OnboardingGuideUITestLaunchConfiguration.makeStore()
        } else if LoginUITestLaunchConfiguration.isEnabled {
            LoginUITestLaunchConfiguration.makeStore()
        } else if MyPageUITestLaunchConfiguration.isEnabled {
            MyPageUITestLaunchConfiguration.makeStore()
        } else if NoticeDetailUITestLaunchConfiguration.isEnabled {
            NoticeDetailUITestLaunchConfiguration.makeStore()
        } else if MemoUITestLaunchConfiguration.isEnabled {
            MemoUITestLaunchConfiguration.makeStore()
        } else if ProcessInfo.processInfo.arguments.contains("-ui-testing-home-image-size-upload") {
            Store(initialState: launchState) {
                AppFeature()
            } withDependencies: {
                $0.homeUseCases.postUploadImage = { fileURL, dailyQuoteSeq in
                    try HomeImageSizeFixture.acceptUpload(fileURL: fileURL, dailyQuoteSeq: dailyQuoteSeq)
                }
            }
        } else if ProcessInfo.processInfo.arguments.contains("-ui-testing-home") {
            Store(initialState: launchState) {
                AppFeature()
            } withDependencies: {
                $0.homeUseCases.saveAnswer = { answer, dailyQuoteSeq in
                    AnswerResponse(
                        memberQuoteSeq: dailyQuoteSeq,
                        answer: answer,
                        answeredAt: "2026-10-07T12:00:00"
                    )
                }
                $0.typingClient.getTyping = { _ in
                    MemberTypingQuoteResponse(
                        korQuote: nil,
                        engQuote: nil,
                        typingKorQuote: nil,
                        typingEngQuote: nil,
                        likeYn: "N"
                    )
                }
            }
        } else if ProcessInfo.processInfo.arguments.contains("ui-testing-calendar") {
            Store(initialState: launchState) {
                AppFeature()
            } withDependencies: {
                let isGuest = ProcessInfo.processInfo.arguments.contains("ui-testing-calendar-guest")
                $0.sessionClient.isLoggedIn = { !isGuest }
            }
        } else {
            Store(initialState: launchState) {
                AppFeature()
            }
        }
    }
}

private enum OnboardingGuideUITestLaunchConfiguration {
    private static let enabledArgument = "-ui-testing-onboarding-guide"
    private static let darkArgument = "-ui-testing-onboarding-guide-dark"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(enabledArgument)
    }

    static func makeStore() -> StoreOf<AppFeature> {
        Store(initialState: initialState) {
            AppFeature()
        }
    }

    private static var initialState: AppFeature.State {
        var state = AppFeature.State()
        state.screen = .onboardingGuide
        state.selectedTheme = ProcessInfo.processInfo.arguments.contains(darkArgument) ? .dark : .light
        return state
    }
}

private enum MemoUITestLaunchConfiguration {
    private static let enabledArgument = "-ui-testing-memo"
    private static let darkArgument = "-ui-testing-memo-dark"
    private static let filledArgument = "-ui-testing-memo-filled"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(enabledArgument)
    }

    static func makeStore() -> StoreOf<AppFeature> {
        Store(initialState: initialState) {
            AppFeature()
        }
    }

    private static var initialState: AppFeature.State {
        var state = AppFeature.State()
        let savedMemo = ProcessInfo.processInfo.arguments.contains(filledArgument)
            ? "명언을 보면 삶에 동기부여가 되어서 좋아요."
            : ""
        state.memberAccess = .member
        state.screen = .memoInsert(savedMemo: savedMemo, memberQuoteSeq: 1)
        state.selectedTheme = ProcessInfo.processInfo.arguments.contains(darkArgument) ? .dark : .light
        state.memoInsert = MemoInsertFeature.State(savedMemo: savedMemo, memberQuoteSeq: 1)
        return state
    }
}

private enum LoginUITestLaunchConfiguration {
    private static let enabledArgument = "-ui-testing-login"
    private static let darkArgument = "-ui-testing-login-dark"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(enabledArgument)
    }

    static func makeStore() -> StoreOf<AppFeature> {
        Store(initialState: initialState) {
            AppFeature()
        }
    }

    private static var initialState: AppFeature.State {
        var state = AppFeature.State()
        state.memberAccess = .loginRequired
        state.screen = .login
        state.selectedTheme = ProcessInfo.processInfo.arguments.contains(darkArgument) ? .dark : .light
        state.login = LoginFeature.State()
        return state
    }
}

private enum MyPageUITestLaunchConfiguration {
    private static let enabledArgument = "-ui-testing-my-page"
    private static let memberArgument = "-ui-testing-my-page-member"
    private static let darkArgument = "-ui-testing-my-page-dark"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(enabledArgument)
    }

    private static var isMember: Bool {
        ProcessInfo.processInfo.arguments.contains(memberArgument)
    }

    private static var selectedTheme: DarkModeType {
        ProcessInfo.processInfo.arguments.contains(darkArgument) ? .dark : .light
    }

    static func makeStore() -> StoreOf<AppFeature> {
        Store(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.settingsClient = SettingsClient(
                getAlarm: { false },
                setAlarm: { _ in },
                isAlarmPermissionRequestedBefore: { false },
                setAlarmPermissionRequestedBefore: { _ in },
                getDarkModeType: { selectedTheme },
                setDarkModeType: { _ in },
                getUserName: { isMember ? "필사" : "" },
                setUserName: { _ in },
                getImageURI: { "" },
                getShareDescriptionVisible: { true },
                setShareDescriptionVisible: { _ in },
                getTokenExpired: { "" },
                emitTokenExpired: { _ in }
            )
            $0.sessionClient = SessionClient(
                isFirstOpen: { false },
                setFirstOpen: { _ in },
                isLoggedIn: { isMember },
                getAccessToken: { "" },
                setAccessToken: { _ in },
                getRefreshToken: { "" },
                setRefreshToken: { _ in },
                logout: {}
            )
            $0.sessionExpirationClient = SessionExpirationClient(
                events: { AsyncStream { _ in } }
            )
            $0.pushRegistrationClient = PushRegistrationClient(
                synchronize: { _ in },
                synchronizeIfNeeded: {}
            )
            $0.pushTokenClient = PushTokenClient(
                currentToken: { nil },
                tokenUpdates: { AsyncStream { _ in } }
            )
        }
    }

    private static var initialState: AppFeature.State {
        var state = AppFeature.State()
        state.memberAccess = isMember ? .member : .loginRequired
        state.screen = isMember ? .main : .login
        state.selectedTab = .myPage
        state.selectedTheme = selectedTheme
        state.myPage = MyPageFeature.State(
            isLoggedIn: isMember,
            userName: isMember ? "필사" : "",
            imagePath: "",
            selectedTheme: selectedTheme
        )
        state.myPage.isThemeDialogPresented = ProcessInfo.processInfo.arguments.contains("-ui-testing-my-page-theme-dialog")
        return state
    }
}

private enum NoticeDetailUITestLaunchConfiguration {
    private static let enabledArgument = "-ui-testing-notice-detail"
    private static let darkArgument = "-ui-testing-notice-detail-dark"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(enabledArgument)
    }

    static func makeStore() -> StoreOf<AppFeature> {
        Store(initialState: initialState) {
            AppFeature()
        }
    }

    private static var initialState: AppFeature.State {
        var state = AppFeature.State()
        state.memberAccess = .member
        state.screen = .noticeDetail(NoticeSampleData.items[0])
        state.selectedTheme = ProcessInfo.processInfo.arguments.contains(darkArgument) ? .dark : .light
        return state
    }
}
