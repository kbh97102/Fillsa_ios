import ComposableArchitecture
import SwiftUI

struct NoticeView: View {
    let store: StoreOf<NoticeFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                HeaderSection(
                    title: "공지사항",
                    back: {
                        viewStore.send(.backTapped)
                    }
                )
                .background(FillsaColor.background)

                NoticeListSection(
                    items: viewStore.notices,
                    select: { notice in
                        viewStore.send(.noticeTapped(notice))
                    }
                )
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FillsaColor.background.ignoresSafeArea())
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

#Preview {
    NoticeView(
        store: Store(initialState: NoticeFeature.State(notices: NoticeSampleData.items, hasLoaded: true)) {
            NoticeFeature()
        }
    )
}
