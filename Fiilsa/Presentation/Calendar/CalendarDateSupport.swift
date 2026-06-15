//
//  CalendarDateSupport.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import Foundation

enum FillsaCalendarDateSupport {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.firstWeekday = 1
        return calendar
    }()

    static let startDay = calendar.date(from: DateComponents(year: 2025, month: 6, day: 10)) ?? Date()

    static let startMonth = calendar.date(from: DateComponents(year: 2025, month: 6, day: 1)) ?? Date()

    static func startOfMonth(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    static func addMonths(_ value: Int, to date: Date) -> Date {
        calendar.date(byAdding: .month, value: value, to: date) ?? date
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    static func isSameMonth(_ lhs: Date, _ rhs: Date) -> Bool {
        let left = calendar.dateComponents([.year, .month], from: lhs)
        let right = calendar.dateComponents([.year, .month], from: rhs)
        return left.year == right.year && left.month == right.month
    }

    static func monthTitle(for date: Date) -> String {
        monthFormatter.string(from: date)
    }

    static func dayString(for date: Date) -> String {
        String(calendar.component(.day, from: date))
    }

    static func shortWeekdayString(for date: Date) -> String {
        "(\(shortWeekdayFormatter.string(from: date)))"
    }

    static func quoteDateString(for date: Date) -> String {
        quoteDateFormatter.string(from: date)
    }

    static func daysForMonthGrid(currentMonth: Date) -> [Date] {
        let monthStart = startOfMonth(for: currentMonth)
        let weekday = calendar.component(.weekday, from: monthStart)
        let leadingDays = weekday - calendar.firstWeekday
        let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: monthStart) ?? monthStart

        return (0..<42).compactMap {
            calendar.date(byAdding: .day, value: $0, to: gridStart)
        }
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy. MM"
        return formatter
    }()

    private static let shortWeekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E"
        return formatter
    }()

    private static let quoteDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
