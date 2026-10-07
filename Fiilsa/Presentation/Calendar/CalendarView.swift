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
                HomeHeader(
                    myPage: openMyPage,
                    streakCount: viewStore.displayStreakCount
                )
                .padding(.horizontal, 20)
                .frame(height: 50)

                ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
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
                    .frame(height: 396)

                    CalendarCountSection(
                        likeCount: viewStore.monthlySummary.likeCount,
                        writingCount: viewStore.monthlySummary.typingCount,
                        countOnClick: {
                            viewStore.send(.countTapped)
                        }
                    )
                    .padding(.top, 10)

                    CalendarSelectedDaySection(
                        selectedDayRecord: selectedDayRecord(
                            from: viewStore.memberQuotes,
                            selectedDay: viewStore.selectedDay
                        ),
                        selectedDay: viewStore.selectedDay,
                        answer: Binding(
                            get: { viewStore.answerDraft },
                            set: { viewStore.send(.answerDraftChanged($0)) }
                        ),
                        recordedAnswer: viewStore.recordedAnswer,
                        isEditingAnswer: viewStore.isEditingAnswer,
                        recordAnswer: { viewStore.send(.answerRecordTapped) },
                        editAnswer: { viewStore.send(.answerEditTapped) },
                        onClick: {
                            viewStore.send(.bottomQuoteTapped)
                        }
                    )
                    .id("calendar.selectedDayAnswer")
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 10)
                .onAppear {
                    if ProcessInfo.processInfo.arguments.contains("ui-testing-calendar-answer-saved") {
                        scrollProxy.scrollTo("calendar.selectedDayAnswer", anchor: .bottom)
                    }
                }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FillsaColor.background.ignoresSafeArea())
            .onAppear {
                guard !ProcessInfo.processInfo.arguments.contains("ui-testing-calendar") else { return }
                viewStore.send(.onAppear)
            }
        }
    }

    private func selectedDayRecord(from memberQuotes: [MemberQuotesData], selectedDay: Date) -> MemberQuotesData? {
        let targetDate = FillsaCalendarDateSupport.quoteDateString(for: selectedDay)
        return memberQuotes.first { $0.quoteDate == targetDate }
    }
}

#Preview {
    CalendarView()
}
