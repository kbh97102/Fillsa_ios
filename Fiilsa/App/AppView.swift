import ComposableArchitecture
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
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
    }

    @ViewBuilder
    private func selectedContent(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            PlaceholderScreen(title: "Home")
        case .quoteList:
            PlaceholderScreen(title: "List")
        case .calendar:
            PlaceholderScreen(title: "Calendar")
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

