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

        case .login:
            PlaceholderScreen(title: "Login")

        case .onboardingGuide:
            PlaceholderScreen(title: "Onboarding guide")

        case .main:
            mainTabContent(viewStore: viewStore)
        }
    }

    private func mainTabContent(
        viewStore: ViewStore<AppFeature.State, AppFeature.Action>
    ) -> some View {
        VStack(spacing: 0) {
            selectedContent(for: viewStore.selectedTab)

            Picker(
                "",
                selection: viewStore.binding(
                    get: \.selectedTab,
                    send: AppFeature.Action.selectedTabChanged
                )
            ) {
                ForEach(AppTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(FillsaColor.background)
        }
        .background(FillsaColor.background.ignoresSafeArea())
    }

    @ViewBuilder
    private func selectedContent(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .quoteList:
            QuoteListView()
        case .calendar:
            CalendarView()
        case .myPage:
            PlaceholderScreen(title: "My page")
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
