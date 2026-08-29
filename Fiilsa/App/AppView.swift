import ComposableArchitecture
import Foundation
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                content(for: viewStore.screen, viewStore: viewStore)

                GeneralPopupView(
                    store: store.scope(state: \.generalPopup, action: \.generalPopup)
                )
            }
            .preferredColorScheme(viewStore.selectedTheme.colorScheme)
            .task {
                guard !ProcessInfo.processInfo.arguments.contains("ui-testing-calendar") else { return }
                await viewStore.send(.task).finish()
            }
        }
    }

    @ViewBuilder
    private func content(
        for screen: AppScreen,
        viewStore: ViewStore<AppFeature.State, AppFeature.Action>
    ) -> some View {
        switch screen {
        case .splash:
            SplashView(
                store: store.scope(state: \.splash, action: \.splash)
            )

        case .login:
            LoginView(
                store: store.scope(state: \.login, action: \.login)
            )

        case .onboardingGuide:
            OnboardingGuideView(
                finish: {
                    viewStore.send(.onboardingGuideFinished)
                }
            )

        case .main:
            mainTabContent(viewStore: viewStore)

        case .typing:
            TypingQuoteView(
                store: store.scope(state: \.typing, action: \.typing),
                share: { quote, author in
                    viewStore.send(.shareSelected(quote: quote, author: author))
                }
            )

        case .share:
            ShareView(
                store: store.scope(state: \.share, action: \.share)
            )

        case let .quoteDetail(data):
            QuoteDetailView(
                data: data,
                back: {
                    viewStore.send(.backToMain)
                },
                openMemo: { savedMemo, memberQuoteSeq in
                    viewStore.send(.memoSelected(savedMemo: savedMemo, memberQuoteSeq: memberQuoteSeq))
                }
            )

        case let .memoInsert(savedMemo, memberQuoteSeq):
            MemoInsertView(
                store: store.scope(state: \.memoInsert, action: \.memoInsert)
            )

        case .notice:
            NoticeView(
                store: store.scope(state: \.notice, action: \.notice)
            )

        case let .noticeDetail(notice):
            NoticeDetailView(
                notice: notice,
                back: {
                    viewStore.send(.noticeSelected)
                }
            )

        case .alert:
            AlertView(
                store: store.scope(state: \.alert, action: \.alert)
            )
        }
    }

    private func mainTabContent(
        viewStore: ViewStore<AppFeature.State, AppFeature.Action>
    ) -> some View {
        VStack(spacing: 0) {
            selectedContent(for: viewStore.selectedTab, viewStore: viewStore)

            if !hidesBottomNavigation(for: viewStore) {
                FillsaBottomNavigationBar(
                    selectedTab: viewStore.selectedTab,
                    select: { tab in
                        viewStore.send(.selectedTabChanged(tab))
                    }
                )
            }
        }
        .background(FillsaColor.background.ignoresSafeArea())
    }

    private func hidesBottomNavigation(
        for viewStore: ViewStore<AppFeature.State, AppFeature.Action>
    ) -> Bool {
        guard viewStore.selectedTab == .calendar else { return false }

        switch viewStore.selectedTheme {
        case .light:
            return true
        case .dark:
            return false
        case .system:
            return colorScheme == .light
        }
    }

    @ViewBuilder
    private func selectedContent(
        for tab: AppTab,
        viewStore: ViewStore<AppFeature.State, AppFeature.Action>
    ) -> some View {
        switch tab {
        case .home:
            HomeView(
                store: store.scope(state: \.home, action: \.home),
                openTyping: {
                    viewStore.send(.homeTypingSelected)
                },
                openTypingWithAnswer: { answer in
                    viewStore.send(.homeAnswerTypingSelected(answer))
                },
                openShare: { quote, author in
                    viewStore.send(.shareSelected(quote: quote, author: author))
                },
                openLogin: {
                    viewStore.send(.loginSelected)
                },
                openMyPage: {
                    viewStore.send(.selectedTabChanged(.myPage))
                }
            )
        case .quoteList:
            QuoteListView(
                store: store.scope(state: \.quoteList, action: \.quoteList),
                openDetail: { data in
                    viewStore.send(.quoteDetailSelected(data))
                },
                openMyPage: {
                    viewStore.send(.selectedTabChanged(.myPage))
                }
            )
        case .calendar:
            CalendarView(
                store: store.scope(state: \.calendar, action: \.calendar),
                openMyPage: {
                    viewStore.send(.selectedTabChanged(.myPage))
                }
            )
        case .myPage:
            MyPageView(
                store: store.scope(state: \.myPage, action: \.myPage)
            )
        }
    }
}

#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}

private extension DarkModeType {
    var colorScheme: ColorScheme? {
        switch self {
        case .dark:
            return .dark
        case .light:
            return .light
        case .system:
            return nil
        }
    }
}
