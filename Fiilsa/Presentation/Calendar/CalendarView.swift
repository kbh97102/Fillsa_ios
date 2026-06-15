//
//  CalendarView.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct CalendarView: View {
    @State private var currentMonth: Date
    @State private var selectedDay: Date

    let memberQuotes: [MemberQuotesData]
    let monthlySummary: MonthlySummaryData

    init(
        memberQuotes: [MemberQuotesData] = [],
        monthlySummary: MonthlySummaryData = MonthlySummaryData(typingCount: 0, likeCount: 0, streakCount: 0),
        selectedDay: Date = Date()
    ) {
        self.memberQuotes = memberQuotes
        self.monthlySummary = monthlySummary
        self._selectedDay = State(initialValue: selectedDay)
        self._currentMonth = State(initialValue: FillsaCalendarDateSupport.startOfMonth(for: selectedDay))
    }

    var body: some View {
        VStack(spacing: 0) {
            HomeTopBar()

            GeometryReader { proxy in
                let calendarHeight = proxy.size.height * 0.75

                VStack(spacing: 0) {
                    CalendarMonthSection(
                        memberQuotes: memberQuotes,
                        currentMonth: $currentMonth,
                        selectedDay: $selectedDay,
                        changeMonth: { _ in },
                        selectDay: { selectedDay = $0 }
                    )
                    .frame(height: calendarHeight)

                    CalendarCountSection(
                        likeCount: monthlySummary.likeCount,
                        typingCount: monthlySummary.typingCount,
                        todayCompleteCount: monthlySummary.streakCount
                    )
                    .padding(.top, 15)

                    CalendarSelectedQuoteSection(
                        selectedDayQuote: selectedDayQuote,
                        selectedDay: selectedDay
                    )
                    .padding(.top, 15)
                    .padding(.bottom, 30)
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FillsaColor.background.ignoresSafeArea())
    }

    private var selectedDayQuote: String {
        let targetDate = FillsaCalendarDateSupport.quoteDateString(for: selectedDay)
        return memberQuotes.first { $0.quoteDate == targetDate }?.quote ?? ""
    }
}

#Preview {
    CalendarView(
        memberQuotes: [
            MemberQuotesData(
                dailyQuoteSeq: 1,
                quoteDate: FillsaCalendarDateSupport.quoteDateString(for: Date()),
                quote: "상황을 가장 잘 활용하는 사람이 가장 좋은 상황을 맞는다.",
                author: "John Wooden",
                completed: true,
                likeYn: "Y",
                todayCompleted: true
            )
        ],
        monthlySummary: MonthlySummaryData(typingCount: 3, likeCount: 5, streakCount: 2)
    )
}
