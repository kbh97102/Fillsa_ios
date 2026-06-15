//
//  QuoteListDurationCalendarSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct QuoteListDurationCalendarSection: View {
    let displayCalendar: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date
    let onApply: (Date, Date) -> Void

    @State private var currentMonth = FillsaCalendarDateSupport.startOfMonth(for: Date())
    @State private var lastClickWasStart = false

    private let weekColumns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        if displayCalendar {
            VStack(spacing: 0) {
                title
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
                    ForEach(days, id: \.self) { date in
                        QuoteListRangeDayCell(
                            date: date,
                            currentMonth: currentMonth,
                            startDate: startDate,
                            endDate: endDate,
                            onClick: { select(date) }
                        )
                    }
                }
                .padding(.bottom, 8)

                Spacer()
                    .frame(height: 22)

                Button {
                    onApply(startDate, endDate)
                } label: {
                    Text("확인")
                        .font(FillsaTypography.subtitle1)
                        .foregroundStyle(FillsaColor.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: 0x5E67FD))
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .padding(.top, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(FillsaColor.white)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(FillsaColor.purple01, lineWidth: 1)
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var title: some View {
        ZStack {
            if currentMonth > FillsaCalendarDateSupport.startMonth {
                HStack {
                    Button {
                        currentMonth = FillsaCalendarDateSupport.addMonths(-1, to: currentMonth)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(FillsaColor.gray700)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
            }

            Text(QuoteListDateSupport.monthTitle(currentMonth))
                .font(FillsaTypography.heading4)
                .foregroundStyle(FillsaColor.gray700)

            if currentMonth < FillsaCalendarDateSupport.startOfMonth(for: Date()) {
                HStack {
                    Spacer()

                    Button {
                        currentMonth = FillsaCalendarDateSupport.addMonths(1, to: currentMonth)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(FillsaColor.gray700)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var days: [Date] {
        FillsaCalendarDateSupport.daysForMonthGrid(currentMonth: currentMonth)
    }

    private func select(_ date: Date) {
        guard FillsaCalendarDateSupport.isSameMonth(date, currentMonth) else { return }

        if FillsaCalendarDateSupport.isSameDay(date, startDate)
            || FillsaCalendarDateSupport.isSameDay(date, endDate) {
            return
        }

        if date < startDate {
            endDate = startDate
            startDate = date
            lastClickWasStart = true
        } else if date > endDate {
            endDate = date
            lastClickWasStart = false
        } else if date > startDate && date < endDate {
            if lastClickWasStart {
                endDate = date
                lastClickWasStart = false
            } else {
                startDate = date
                lastClickWasStart = true
            }
        }
    }
}

private struct QuoteListRangeDayCell: View {
    let date: Date
    let currentMonth: Date
    let startDate: Date
    let endDate: Date
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            ZStack {
                rangeBackground

                if isRangeEdge {
                    Circle()
                        .fill(FillsaColor.purple01)
                        .padding(4)
                }

                Text(QuoteListDateSupport.dayString(date))
                    .font(.system(size: 16, weight: isRangeEdge ? .bold : .regular))
                    .foregroundStyle(textColor)
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .disabled(!FillsaCalendarDateSupport.isSameMonth(date, currentMonth))
    }

    @ViewBuilder
    private var rangeBackground: some View {
        if isInRange || isRangeEdge {
            RoundedRectangle(cornerRadius: backgroundCornerRadius)
                .fill(FillsaColor.purple02)
                .padding(.vertical, 6)
                .padding(.leading, isStartDate && !isEndDate ? 6 : 0)
                .padding(.trailing, isEndDate && !isStartDate ? 6 : 0)
        }
    }

    private var isStartDate: Bool {
        FillsaCalendarDateSupport.isSameDay(date, startDate)
    }

    private var isEndDate: Bool {
        FillsaCalendarDateSupport.isSameDay(date, endDate)
    }

    private var isRangeEdge: Bool {
        isStartDate || isEndDate
    }

    private var isInRange: Bool {
        date > startDate && date < endDate
    }

    private var backgroundCornerRadius: CGFloat {
        if isStartDate && isEndDate { return 16 }
        if isInRange { return 0 }
        return 16
    }

    private var textColor: Color {
        if isRangeEdge { return FillsaColor.white }
        if FillsaCalendarDateSupport.isSameMonth(date, currentMonth) { return FillsaColor.gray700 }
        return FillsaColor.gray400.opacity(0.4)
    }
}

#Preview {
    @Previewable @State var startDate = Date()
    @Previewable @State var endDate = FillsaCalendarDateSupport.calendar.date(byAdding: .day, value: 10, to: Date()) ?? Date()

    QuoteListDurationCalendarSection(
        displayCalendar: true,
        startDate: $startDate,
        endDate: $endDate,
        onApply: { _, _ in }
    )
    .padding()
    .background(FillsaColor.background)
}
