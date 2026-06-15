//
//  CalendarView.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI
import ComposableArchitecture

struct CalendarView: View {
    @State private var currentMonth: Date
    @State private var selectedDay: Date

    let store: StoreOf<CalendarFeature>
    let openHome: () -> Void
    let openQuoteList: () -> Void

    init(
        store: StoreOf<CalendarFeature> = Store(initialState: CalendarFeature.State()) {
            CalendarFeature()
        },
        selectedDay: Date = Date(),
        openHome: @escaping () -> Void = {},
        openQuoteList: @escaping () -> Void = {}
    ) {
        self.store = store
        self.openHome = openHome
        self.openQuoteList = openQuoteList
        self._selectedDay = State(initialValue: selectedDay)
        self._currentMonth = State(initialValue: FillsaCalendarDateSupport.startOfMonth(for: selectedDay))
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                HomeTopBar()

                GeometryReader { proxy in
                    let calendarHeight = proxy.size.height * 0.75

                    VStack(spacing: 0) {
                        CalendarMonthSection(
                            memberQuotes: viewStore.memberQuotes,
                            currentMonth: $currentMonth,
                            selectedDay: $selectedDay,
                            changeMonth: {
                                viewStore.send(.monthChanged($0))
                            },
                            selectDay: { selectedDay = $0 }
                        )
                        .frame(height: calendarHeight)

                        CalendarCountSection(
                            likeCount: viewStore.monthlySummary.likeCount,
                            typingCount: viewStore.monthlySummary.typingCount,
                            todayCompleteCount: viewStore.monthlySummary.streakCount,
                            countOnClick: openQuoteList
                        )
                        .padding(.top, 15)

                        CalendarSelectedQuoteSection(
                            selectedDayQuote: selectedDayQuote(from: viewStore.memberQuotes),
                            selectedDay: selectedDay,
                            onClick: openHome
                        )
                        .padding(.top, 15)
                        .padding(.bottom, 30)
                    }
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

    private func selectedDayQuote(from memberQuotes: [MemberQuotesData]) -> String {
        let targetDate = FillsaCalendarDateSupport.quoteDateString(for: selectedDay)
        return memberQuotes.first { $0.quoteDate == targetDate }?.quote ?? ""
    }
}

#Preview {
    CalendarView()
}
