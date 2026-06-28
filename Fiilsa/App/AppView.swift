import ComposableArchitecture
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            content(for: viewStore.screen, viewStore: viewStore)
                .preferredColorScheme(viewStore.myPage.selectedTheme.colorScheme)
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

        case let .login(isOnboarding):
            LoginView(
                isOnboarding: isOnboarding,
                close: {
                    viewStore.send(.loginClosed)
                },
                moveHome: {
                    viewStore.send(.loginClosed)
                },
                moveOnboardingGuide: {
                    viewStore.send(.loginNonMemberSelected)
                }
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

        case let .share(quote, author):
            ShareView(
                quote: quote,
                author: author,
                back: {
                    viewStore.send(.backToMain)
                }
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
                back: {
                    viewStore.send(.backToMain)
                }
            )
        }
    }

    private func mainTabContent(
        viewStore: ViewStore<AppFeature.State, AppFeature.Action>
    ) -> some View {
        VStack(spacing: 0) {
            selectedContent(for: viewStore.selectedTab, viewStore: viewStore)

            FillsaBottomNavigationBar(
                selectedTab: viewStore.selectedTab,
                select: { tab in
                    viewStore.send(.selectedTabChanged(tab))
                }
            )
        }
        .background(FillsaColor.background.ignoresSafeArea())
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
                openShare: { quote, author in
                    viewStore.send(.shareSelected(quote: quote, author: author))
                },
                openLogin: {
                    viewStore.send(.loginSelected)
                }
            )
        case .quoteList:
            QuoteListView(
                store: store.scope(state: \.quoteList, action: \.quoteList),
                openDetail: { data in
                    viewStore.send(.quoteDetailSelected(data))
                }
            )
        case .calendar:
            CalendarView(
                store: store.scope(state: \.calendar, action: \.calendar)
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
