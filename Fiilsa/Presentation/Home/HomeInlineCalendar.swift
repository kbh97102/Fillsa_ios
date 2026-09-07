import SwiftUI

struct HomeCalendarDay: Identifiable, Equatable {
    let date: Date
    let isInDisplayedMonth: Bool

    var id: Date { date }
}

enum HomeCalendarMonthRange {
    static var start: Date { FillsaCalendarDateSupport.startMonth }
    static var end: Date { FillsaCalendarDateSupport.startOfMonth(for: Date()) }

    static func isSelectable(_ date: Date) -> Bool {
        let month = FillsaCalendarDateSupport.startOfMonth(for: date)
        return month >= start && month <= end
    }
}

enum HomeCalendarGrid {
    static func days(
        displayedMonth: Date,
        calendar: Calendar = FillsaCalendarDateSupport.calendar
    ) -> [HomeCalendarDay] {
        FillsaCalendarDateSupport.daysForMonthGrid(currentMonth: displayedMonth).map { date in
            HomeCalendarDay(
                date: date,
                isInDisplayedMonth: calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
            )
        }
    }
}

/// Figma `2929:16227` calendar popup within the open state `2929:16221`.
struct HomeInlineCalendar: View {
    let displayedMonth: Date
    let selectedDate: Date
    let selectDate: (Date) -> Void
    let changeMonth: (Date) -> Void

    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
    private let columns = Array(repeating: GridItem(.fixed(32), spacing: 0), count: 7)
    private let calendar = FillsaCalendarDateSupport.calendar

    var body: some View {
        VStack(spacing: 0) {
            monthHeader
                .frame(height: 42)

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(FillsaTypography.body4)
                        .foregroundStyle(FillsaColor.gray500)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.top, 6)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(HomeCalendarGrid.days(displayedMonth: displayedMonth)) { day in
                    dayCell(day)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .frame(width: 248, height: 335, alignment: .top)
        .background(FillsaColor.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: 0xE7E2D7), lineWidth: 1)
        }
        .shadow(color: FillsaColor.gray700.opacity(0.14), radius: 12, y: 5)
        .accessibilityIdentifier("home.calendarPopup")
    }

    private var monthHeader: some View {
        HStack(spacing: 4) {
            monthMoveButton(systemName: "chevron.left", delta: -1)

            Spacer(minLength: 0)

            Menu {
                ForEach(yearRange, id: \.self) { year in
                    let target = month(year: year, month: displayedMonthNumber)
                    if HomeCalendarMonthRange.isSelectable(target) {
                        Button("\(year)년") { changeMonth(target) }
                    }
                }
            } label: {
                dropdownLabel("\(displayedYear)년", width: 62)
            }

            Menu {
                ForEach(1...12, id: \.self) { month in
                    let target = self.month(year: displayedYear, month: month)
                    if HomeCalendarMonthRange.isSelectable(target) {
                        Button("\(month)월") { changeMonth(target) }
                    }
                }
            } label: {
                dropdownLabel("\(displayedMonthNumber)월", width: 54)
            }

            Spacer(minLength: 0)

            monthMoveButton(systemName: "chevron.right", delta: 1)
        }
    }

    private func monthMoveButton(systemName: String, delta: Int) -> some View {
        let target = FillsaCalendarDateSupport.addMonths(delta, to: displayedMonth)
        return Button {
            changeMonth(target)
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(FillsaColor.gray700)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .disabled(!HomeCalendarMonthRange.isSelectable(target))
    }

    private func dropdownLabel(_ title: String, width: CGFloat) -> some View {
        HStack(spacing: 3) {
            Text(title)
                .font(FillsaTypography.subtitle2)
                .foregroundStyle(FillsaColor.gray700)
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(FillsaColor.gray500)
        }
        .frame(width: width, height: 28)
        .background(FillsaColor.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: 0xE7E2D7), lineWidth: 1))
        .shadow(color: FillsaColor.gray700.opacity(0.12), radius: 2, y: 1)
    }

    private func dayCell(_ day: HomeCalendarDay) -> some View {
        let isSelected = calendar.isDate(day.date, inSameDayAs: selectedDate)
        let isFuture = calendar.startOfDay(for: day.date) > calendar.startOfDay(for: Date())
        let isBeforeStart = calendar.startOfDay(for: day.date) < calendar.startOfDay(for: FillsaCalendarDateSupport.startDay)

        return Button {
            selectDate(day.date)
        } label: {
            Text(String(calendar.component(.day, from: day.date)))
                .font(FillsaTypography.body4)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(
                    isSelected
                        ? FillsaColor.white
                        : day.isInDisplayedMonth && !isFuture && !isBeforeStart
                            ? FillsaColor.gray700
                            : FillsaColor.gray300
                )
                .frame(width: 32, height: 32)
                .background {
                    if isSelected {
                        Circle().fill(FillsaColor.gray700).frame(width: 28, height: 28)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(!day.isInDisplayedMonth || isFuture || isBeforeStart)
        .accessibilityLabel(Self.accessibilityFormatter.string(from: day.date))
    }

    private var displayedYear: Int { calendar.component(.year, from: displayedMonth) }
    private var displayedMonthNumber: Int { calendar.component(.month, from: displayedMonth) }

    private var yearRange: ClosedRange<Int> {
        let startYear = calendar.component(.year, from: FillsaCalendarDateSupport.startDay)
        let currentYear = calendar.component(.year, from: Date())
        return startYear...currentYear
    }

    private func month(year: Int, month: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? displayedMonth
    }

    private static let accessibilityFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter
    }()
}
