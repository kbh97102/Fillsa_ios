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
                store: Store(initialState: initialState) {
                    AppFeature()
                }
            )
        }
    }

    private var initialState: AppFeature.State {
        var state = AppFeature.State()
        let arguments = ProcessInfo.processInfo.arguments

        guard arguments.contains("ui-testing-calendar") else { return state }

        state.screen = .main
        state.selectedTab = .calendar
        state.selectedTheme = arguments.contains("ui-testing-theme-dark") ? .dark : .light
        state.calendar.displayStreakCount = 100
        return state
    }
}
