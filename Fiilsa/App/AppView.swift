import ComposableArchitecture
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            content(for: viewStore.screen, viewStore: viewStore)
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
                korQuote: "상황을 가장 잘 활용하는 사람이 가장 좋은 상황을 맞는다.",
                engQuote: "Things turn out best for the people who make the best of the way things turn out.",
                korAuthor: "존 우든",
                engAuthor: "John Wooden",
                back: {
                    viewStore.send(.backToMain)
                },
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
                savedMemo: savedMemo,
                memberQuoteSeq: memberQuoteSeq,
                back: { _ in
                    viewStore.send(.backToMain)
                }
            )

        case .notice:
            NoticeView(
                items: NoticeSampleData.items,
                back: {
                    viewStore.send(.backToMain)
                },
                select: { notice in
                    viewStore.send(.noticeDetailSelected(notice))
                }
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
                openTyping: {
                    viewStore.send(.homeTypingSelected)
                },
                openShare: { quote, author in
                    viewStore.send(.shareSelected(quote: quote, author: author))
                }
            )
        case .quoteList:
            QuoteListView(
                list: QuoteListSampleData.items,
                openDetail: { data in
                    viewStore.send(.quoteDetailSelected(data))
                }
            )
        case .calendar:
            CalendarView(
                memberQuotes: CalendarSampleData.memberQuotes,
                monthlySummary: CalendarSampleData.monthlySummary,
                openHome: {
                    viewStore.send(.homeTabSelected)
                },
                openQuoteList: {
                    viewStore.send(.quoteListTabSelected)
                }
            )
        case .myPage:
            MyPageView(
                openHome: {
                    viewStore.send(.homeTabSelected)
                },
                openLogin: {
                    viewStore.send(.loginSelected)
                },
                openNotice: {
                    viewStore.send(.noticeSelected)
                },
                openAlert: {
                    viewStore.send(.alertSelected)
                }
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
