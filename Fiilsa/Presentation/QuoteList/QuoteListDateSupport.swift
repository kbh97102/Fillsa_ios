//
//  QuoteListDateSupport.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import Foundation

enum QuoteListDateSupport {
    static let calendar = FillsaCalendarDateSupport.calendar

    static var defaultStartDate: Date {
        let now = Date()
        let year = calendar.component(.year, from: now)
        if year <= 2025 {
            return calendar.date(from: DateComponents(year: 2025, month: 6, day: 1)) ?? FillsaCalendarDateSupport.startDay
        }
        return calendar.date(byAdding: .month, value: -6, to: now) ?? FillsaCalendarDateSupport.startDay
    }

    static func displayDate(_ date: Date) -> String {
        displayFormatter.string(from: date)
    }

    static func monthTitle(_ date: Date) -> String {
        FillsaCalendarDateSupport.monthTitle(for: date)
    }

    static func dayString(_ date: Date) -> String {
        FillsaCalendarDateSupport.dayString(for: date)
    }

    static func quoteDate(_ date: Date) -> String {
        FillsaCalendarDateSupport.quoteDateString(for: date)
    }

    static func date(from quoteDate: String) -> Date? {
        serverFormatter.date(from: quoteDate)
    }

    static func koreanWeekday(_ value: String) -> String {
        switch value {
        case "MONDAY": "(월)"
        case "TUESDAY": "(화)"
        case "WEDNESDAY": "(수)"
        case "THURSDAY": "(목)"
        case "FRIDAY": "(금)"
        case "SATURDAY": "(토)"
        case "SUNDAY": "(일)"
        default: ""
        }
    }

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    private static let serverFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
