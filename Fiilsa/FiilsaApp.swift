//
//  FiilsaApp.swift
//  Fiilsa
//
//  Created by 강보훈 on 6/13/26.
//

import SwiftUI
import ComposableArchitecture
import KakaoSDKAuth

@main
struct FiilsaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            AppView(
                store: appStore
            )
            .onOpenURL { url in
                guard AuthApi.isKakaoTalkLoginUrl(url) else { return }
                _ = AuthController.handleOpenUrl(url: url)
            }
        }
    }

    private var launchState: AppFeature.State {
        let arguments = ProcessInfo.processInfo.arguments
        var state = AppFeature.State()

        if arguments.contains("ui-testing-calendar") {
            state.screen = .main
            state.selectedTab = .calendar
            state.selectedTheme = arguments.contains("ui-testing-theme-dark") ? .dark : .light
            let selectedDay = Self.calendarUITestDate
            state.calendar.currentMonth = FillsaCalendarDateSupport.startOfMonth(for: selectedDay)
            state.calendar.selectedDay = selectedDay
            state.calendar.memberQuotes = Self.calendarUITestQuotes(
                completed: arguments.contains("ui-testing-calendar-completed")
            )
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
            state.screen = .main
            state.selectedTab = .home
            state.selectedTheme = arguments.contains("ui-testing-theme-dark") ? .dark : .light
            state.home = HomeFeature.State(
                quote: DailyQuote(
                    likeYn: "N",
                    imagePath: "",
                    dailyQuoteSeq: 1,
                    korQuote: "사랑이라는 선물은 억지로 줄 수 없고 받아들여지기를 기다릴 뿐이다.",
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
            return state
        }

        guard arguments.contains("-uiTestingQuoteList") else { return state }
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

    private static let homeUITestDate: Date = {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(identifier: "Asia/Seoul")
        components.year = 2026
        components.month = 8
        components.day = 12
        return components.date ?? Date(timeIntervalSince1970: 0)
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
        if OnboardingGuideUITestLaunchConfiguration.isEnabled {
            OnboardingGuideUITestLaunchConfiguration.makeStore()
        } else if LoginUITestLaunchConfiguration.isEnabled {
            LoginUITestLaunchConfiguration.makeStore()
        } else if MyPageUITestLaunchConfiguration.isEnabled {
            MyPageUITestLaunchConfiguration.makeStore()
        } else if NoticeDetailUITestLaunchConfiguration.isEnabled {
            NoticeDetailUITestLaunchConfiguration.makeStore()
        } else if MemoUITestLaunchConfiguration.isEnabled {
            MemoUITestLaunchConfiguration.makeStore()
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
        state.screen = .login(isOnboarding: false)
        state.selectedTheme = ProcessInfo.processInfo.arguments.contains(darkArgument) ? .dark : .light
        state.login = LoginFeature.State(isOnboarding: false)
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
        state.screen = .main
        state.selectedTab = .myPage
        state.selectedTheme = selectedTheme
        state.myPage = MyPageFeature.State(
            isLoggedIn: isMember,
            userName: isMember ? "필사" : "",
            imagePath: "",
            selectedTheme: selectedTheme
        )
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
        state.screen = .noticeDetail(NoticeSampleData.items[0])
        state.selectedTheme = ProcessInfo.processInfo.arguments.contains(darkArgument) ? .dark : .light
        return state
    }
}
