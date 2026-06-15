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

    private let weekColumns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        VStack(spacing: 0) {
            CalendarMonthTitle(
                currentMonth: currentMonth,
                goToPrevious: moveToPreviousMonth,
                goToNext: moveToNextMonth
            )
            .padding(.top, 8)
            .padding(.horizontal, 16)

            LazyVGrid(columns: weekColumns, spacing: 0) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(FillsaTypography.subtitle2)
                        .foregroundStyle(FillsaColor.gray700)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 18)
            .padding(.bottom, 8)

            LazyVGrid(columns: weekColumns, spacing: 0) {
                ForEach(days, id: \.self) { day in
                    CalendarDayCell(
                        date: day,
                        quoteData: quoteData(for: day),
                        isSelected: FillsaCalendarDateSupport.isSameDay(day, selectedDay),
                        isEnabled: isEnabled(day),
                        isCurrentMonth: FillsaCalendarDateSupport.isSameMonth(day, currentMonth),
                        onClick: {
                            selectedDay = day
                            selectDay(day)
                        }
                    )
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.bottom, 8)
        }
        .padding(.top, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FillsaColor.yellow01)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(FillsaColor.yellow02, lineWidth: 1)
        }
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
        currentMonth = target
        changeMonth(target)
    }

    private func moveToNextMonth() {
        let target = FillsaCalendarDateSupport.addMonths(1, to: currentMonth)
        guard target <= FillsaCalendarDateSupport.startOfMonth(for: Date()) else { return }
        currentMonth = target
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
            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(FillsaColor.purple01)
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
