//
//  QuoteListView.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct QuoteListView: View {
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var displayCalendar = false
    @State private var likeFilter = false

    let list: [MemberQuotesResponse]

    init(
        list: [MemberQuotesResponse] = [],
        startDate: Date = FillsaCalendarDateSupport.startDay,
        endDate: Date = Date()
    ) {
        self.list = list
        self._startDate = State(initialValue: startDate)
        self._endDate = State(initialValue: endDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            HomeTopBar()

            VStack(spacing: 0) {
                QuoteListDateSelectSection(
                    startDate: startDate,
                    endDate: endDate,
                    isCalendarDisplayed: displayCalendar,
                    onClick: { displayCalendar.toggle() }
                )
                .padding(.top, 20)

                QuoteListDurationCalendarSection(
                    displayCalendar: displayCalendar,
                    startDate: $startDate,
                    endDate: $endDate,
                    onApply: { start, end in
                        startDate = start
                        endDate = end
                        displayCalendar = false
                    }
                )
                .padding(.top, displayCalendar ? -6 : 0)
                .zIndex(1)

                HStack {
                    Spacer()

                    QuoteListLikeFilterSection(
                        isLike: likeFilter,
                        setIsLike: { likeFilter = $0 }
                    )
                }
                .padding(.top, 20)

                QuoteListSection(
                    list: filteredList,
                    onClick: { _ in }
                )
                .padding(.top, 10)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FillsaColor.background.ignoresSafeArea())
    }

    private var filteredList: [MemberQuotesResponse] {
        guard likeFilter else { return list }
        return list.filter { $0.likeYn == "Y" }
    }
}

#Preview {
    QuoteListView(list: QuoteListSampleData.items)
}
