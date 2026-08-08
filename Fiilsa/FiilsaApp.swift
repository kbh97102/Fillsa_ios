//
//  FiilsaApp.swift
//  Fiilsa
//
//  Created by 강보훈 on 6/13/26.
//

import SwiftUI
import ComposableArchitecture

@main
struct FiilsaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            AppView(
                store: appStore
            )
        }
    }

    private var appStore: StoreOf<AppFeature> {
        if MyPageUITestLaunchConfiguration.isEnabled {
            MyPageUITestLaunchConfiguration.makeStore()
        } else {
            Store(initialState: AppFeature.State()) {
                AppFeature()
            }
        }
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
