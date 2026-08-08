//
//  CalendarView.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI
import ComposableArchitecture
import Foundation

struct CalendarView: View {
    let store: StoreOf<CalendarFeature>
    let openMyPage: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(
        store: StoreOf<CalendarFeature> = Store(initialState: CalendarFeature.State()) {
            CalendarFeature()
        },
        openMyPage: @escaping () -> Void = {}
    ) {
        self.store = store
        self.openMyPage = openMyPage
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                HomeTopBar(
                    myPage: openMyPage,
                    displayStreak: colorScheme == .light,
                    streakCount: viewStore.displayStreakCount
                )
                .padding(.horizontal, 20)

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
                    .frame(width: 320, height: 396)

                    CalendarCountSection(
                        likeCount: viewStore.monthlySummary.likeCount,
                        typingCount: viewStore.monthlySummary.typingCount,
                        todayCompleteCount: viewStore.monthlySummary.streakCount,
                        countOnClick: {
                            viewStore.send(.countTapped)
                        }
                    )
                    .frame(width: 320)
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
                    .frame(width: 320)
                    .padding(.top, 15)
                }
                .frame(width: 320)
                .padding(.top, 20)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FillsaColor.background.ignoresSafeArea())
            .onAppear {
                guard !ProcessInfo.processInfo.arguments.contains("ui-testing-calendar") else { return }
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
