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
                store: Store(initialState: launchState) {
                    AppFeature()
                }
            )
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
}
