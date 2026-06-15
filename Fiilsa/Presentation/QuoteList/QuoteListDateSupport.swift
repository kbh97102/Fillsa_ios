//
//  QuoteListDateSupport.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import Foundation

enum QuoteListDateSupport {
    static let calendar = FillsaCalendarDateSupport.calendar

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
