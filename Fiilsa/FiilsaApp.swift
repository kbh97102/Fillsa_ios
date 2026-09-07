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
            state.calendar.displayStreakCount = 100
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
            if arguments.contains("-ui-testing-home-zero-streak") {
                state.home.isStreakStateLoaded = true
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
