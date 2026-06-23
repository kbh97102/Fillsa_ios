//
//  QuoteListView.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import ComposableArchitecture
import SwiftUI

struct QuoteListView: View {
    @State private var displayCalendar = false

    let store: StoreOf<QuoteListFeature>
    let openDetail: (MemberQuotesResponse) -> Void

    init(
        store: StoreOf<QuoteListFeature> = Store(initialState: QuoteListFeature.State()) {
            QuoteListFeature()
        },
        openDetail: @escaping (MemberQuotesResponse) -> Void = { _ in }
    ) {
        self.store = store
        self.openDetail = openDetail
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                HomeTopBar()

                VStack(spacing: 0) {
                    QuoteListDateSelectSection(
                        startDate: viewStore.startDate,
                        endDate: viewStore.endDate,
                        isCalendarDisplayed: displayCalendar,
                        onClick: { displayCalendar.toggle() }
                    )
                    .padding(.top, 20)

                    QuoteListDurationCalendarSection(
                        displayCalendar: displayCalendar,
                        startDate: viewStore.binding(
                            get: \.startDate,
                            send: { .dateRangeChanged($0, viewStore.endDate) }
                        ),
                        endDate: viewStore.binding(
                            get: \.endDate,
                            send: { .dateRangeChanged(viewStore.startDate, $0) }
                        ),
                        onApply: { start, end in
                            displayCalendar = false
                            viewStore.send(.dateRangeChanged(start, end))
                        }
                    )
                    .padding(.top, displayCalendar ? -6 : 0)
                    .zIndex(1)

                    HStack {
                        Spacer()

                        QuoteListLikeFilterSection(
                            isLike: viewStore.likeFilter,
                            setIsLike: {
                                viewStore.send(.likeFilterChanged($0))
                            }
                        )
                    }
                    .padding(.top, 20)

                    QuoteListSection(
                        list: viewStore.list,
                        onClick: openDetail,
                        loadMore: {
                            viewStore.send(.loadNextPage)
                        }
                    )
                    .padding(.top, 10)
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FillsaColor.background.ignoresSafeArea())
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

#Preview {
    QuoteListView()
}
