import ComposableArchitecture
import Foundation
import SwiftUI
import UIKit

struct AppView: View {
    let store: StoreOf<AppFeature>
    @State private var isKeyboardPresented = false

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                content(for: viewStore.screen, viewStore: viewStore)
                    .allowsHitTesting(!viewStore.isGlobalLoading)

                GeneralPopupView(
                    store: store.scope(state: \.generalPopup, action: \.generalPopup)
                )
                .allowsHitTesting(!viewStore.isGlobalLoading)

                if viewStore.isGlobalLoading {
                    GlobalLoadingOverlay()
                }
            }
            .preferredColorScheme(viewStore.selectedTheme.colorScheme)
            .task {
                guard !ProcessInfo.processInfo.arguments.contains("ui-testing-calendar"),
                      !ProcessInfo.processInfo.arguments.contains("-ui-testing-global-loading") else { return }
                await viewStore.send(.task).finish()
            }
            .onChange(of: viewStore.isGlobalLoading) { _, isLoading in
                if isLoading {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                isKeyboardPresented = true
                if ProcessInfo.processInfo.arguments.contains("-ui-testing-global-loading-on-keyboard") {
                    viewStore.send(.loadingCountChanged(1))
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                isKeyboardPresented = false
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
                isInputEnabled: !viewStore.isGlobalLoading,
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

            if viewStore.selectedTab != .home || !isKeyboardPresented {
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
                },
                openMyPage: {
                    viewStore.send(.selectedTabChanged(.myPage))
                },
                openCalendar: {
                    viewStore.send(.selectedTabChanged(.calendar))
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

private struct GlobalLoadingOverlay: View {
    @State private var rotation = 0.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.2)

                Image("global_loading_spinner")
                    .resizable()
                    .frame(width: 112, height: 112)
                    .rotationEffect(.degrees(rotation))
                    .frame(width: 120, height: 120)
                    .accessibilityLabel("로딩 중")
                    .accessibilityIdentifier("globalLoading.spinner")
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
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
