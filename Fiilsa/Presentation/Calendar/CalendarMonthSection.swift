//
//  CalendarMonthSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct CalendarMonthSection: View {
    let memberQuotes: [MemberQuotesData]
    @Binding var currentMonth: Date
    @Binding var selectedDay: Date
    let changeMonth: (Date) -> Void
    let selectDay: (Date) -> Void

    /// Figma 2985:21952: seven 36pt columns with six 11pt gutters fit the
    /// 320pt calendar shell without letting a flexible grid redistribute cells.
    private let weekColumns = Array(repeating: GridItem(.fixed(36), spacing: 11), count: 7)
    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        VStack(spacing: 0) {
            CalendarMonthTitle(
                currentMonth: currentMonth,
                goToPrevious: moveToPreviousMonth,
                goToNext: moveToNextMonth
            )
            .frame(height: 30)
            .padding(.top, 8)
            .padding(.horizontal, 16)

            LazyVGrid(columns: weekColumns, spacing: 0) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(FillsaTypography.subtitle2)
                        .foregroundStyle(FillsaColor.onBackground1)
                        .frame(width: 36, height: 40)
                }
            }
            .frame(height: 40)
            .padding(.top, 10)

            LazyVGrid(columns: weekColumns, spacing: 0) {
                ForEach(days, id: \.self) { day in
                    CalendarDayCell(
                        date: day,
                        quoteData: quoteData(for: day),
                        isSelected: FillsaCalendarDateSupport.isSameDay(day, selectedDay),
                        isEnabled: isEnabled(day),
                        isCurrentMonth: FillsaCalendarDateSupport.isSameMonth(day, currentMonth),
                        onClick: {
                            selectDay(day)
                        }
                    )
                }
            }
            .frame(height: 300)
            .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FillsaColor.dynamic(light: FillsaColor.white.opacity(0.5), dark: FillsaColor.gray600))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(FillsaColor.dynamic(light: FillsaColor.yellow02, dark: FillsaColor.gray500), lineWidth: 1)
        }
        .frame(width: 320)
        .accessibilityIdentifier(FillsaAccessibilityIdentifier.calendarMonthCard)
    }

    private var days: [Date] {
        FillsaCalendarDateSupport.daysForMonthGrid(currentMonth: currentMonth)
    }

    private func quoteData(for date: Date) -> MemberQuotesData? {
        let targetDate = FillsaCalendarDateSupport.quoteDateString(for: date)
        return memberQuotes.first { $0.quoteDate == targetDate }
    }

    private func isEnabled(_ date: Date) -> Bool {
        FillsaCalendarDateSupport.isSameMonth(date, currentMonth)
            && FillsaCalendarDateSupport.calendar.startOfDay(for: date) >= FillsaCalendarDateSupport.calendar.startOfDay(for: FillsaCalendarDateSupport.startDay)
            && FillsaCalendarDateSupport.calendar.startOfDay(for: date) <= FillsaCalendarDateSupport.calendar.startOfDay(for: Date())
    }

    private func moveToPreviousMonth() {
        let target = FillsaCalendarDateSupport.addMonths(-1, to: currentMonth)
        guard target >= FillsaCalendarDateSupport.startMonth else { return }
        changeMonth(target)
    }

    private func moveToNextMonth() {
        let target = FillsaCalendarDateSupport.addMonths(1, to: currentMonth)
        guard target <= FillsaCalendarDateSupport.startOfMonth(for: Date()) else { return }
        changeMonth(target)
    }
}

private struct CalendarMonthTitle: View {
    let currentMonth: Date
    let goToPrevious: () -> Void
    let goToNext: () -> Void

    var body: some View {
        ZStack {
            if displayBeforeButton {
                HStack {
                    CalendarNavigationButton(isPrevious: true, action: goToPrevious)
                    Spacer()
                }
            }

            Text(FillsaCalendarDateSupport.monthTitle(for: currentMonth))
                .font(FillsaTypography.heading4)
                .foregroundStyle(FillsaColor.purple01)

            if displayNextButton {
                HStack {
                    Spacer()
                    CalendarNavigationButton(isPrevious: false, action: goToNext)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var displayBeforeButton: Bool {
        currentMonth > FillsaCalendarDateSupport.startMonth
    }

    private var displayNextButton: Bool {
        currentMonth < FillsaCalendarDateSupport.startOfMonth(for: Date())
    }
}

private struct CalendarNavigationButton: View {
    let isPrevious: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("icn_calendar_navigation_arrow")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .rotationEffect(isPrevious ? .degrees(180) : .degrees(0))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var currentMonth = Date()
    @Previewable @State var selectedDay = Date()

    CalendarMonthSection(
        memberQuotes: [],
        currentMonth: $currentMonth,
        selectedDay: $selectedDay,
        changeMonth: { _ in },
        selectDay: { _ in }
    )
    .frame(height: 430)
    .padding(20)
    .background(FillsaColor.background)
}
