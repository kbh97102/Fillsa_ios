//
//  CalendarView.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI
import ComposableArchitecture

struct CalendarView: View {
    let store: StoreOf<CalendarFeature>

    init(
        store: StoreOf<CalendarFeature> = Store(initialState: CalendarFeature.State()) {
            CalendarFeature()
        }
    ) {
        self.store = store
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
                            currentMonth: Binding(
                                get: { viewStore.currentMonth },
                                set: { viewStore.send(.monthChanged($0)) }
                            ),
                            selectedDay: Binding(
                                get: { viewStore.selectedDay },
                                set: { viewStore.send(.daySelected($0)) }
                            ),
                            changeMonth: {
                                viewStore.send(.monthChanged($0))
                            },
                            selectDay: {
                                viewStore.send(.daySelected($0))
                            }
                        )
                        .frame(height: calendarHeight)

                        CalendarCountSection(
                            likeCount: viewStore.monthlySummary.likeCount,
                            typingCount: viewStore.monthlySummary.typingCount,
                            todayCompleteCount: viewStore.monthlySummary.streakCount,
                            countOnClick: {
                                viewStore.send(.countTapped)
                            }
                        )
                        .padding(.top, 15)

                        CalendarSelectedQuoteSection(
                            selectedDayQuote: selectedDayQuote(
                                from: viewStore.memberQuotes,
                                selectedDay: viewStore.selectedDay
                            ),
                            selectedDay: viewStore.selectedDay,
                            onClick: {
                                viewStore.send(.bottomQuoteTapped)
                            }
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

    private func selectedDayQuote(from memberQuotes: [MemberQuotesData], selectedDay: Date) -> String {
        let targetDate = FillsaCalendarDateSupport.quoteDateString(for: selectedDay)
        return memberQuotes.first { $0.quoteDate == targetDate }?.quote ?? ""
    }
}

#Preview {
    CalendarView()
}
