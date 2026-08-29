//
//  CalendarRecordIndicators.swift
//  Fiilsa
//

import Foundation

enum CalendarRecordIndicator: Equatable {
    case heart
    case flame
}

enum CalendarRecordIndicators {
    /// The Calendar Figma language uses a flame for a completed daily writing
    /// and a heart for a liked quote. `todayCompleted` mirrors `completed` in
    /// the local store, so preserving both safely supports historic payloads.
    static func resolve(for quote: MemberQuotesData?) -> [CalendarRecordIndicator] {
        guard let quote else { return [] }

        var indicators: [CalendarRecordIndicator] = []
        if quote.likeYn == "Y" {
            indicators.append(.heart)
        }
        if CalendarWritingCompletion.isCompleted(quote) {
            indicators.append(.flame)
        }
        return indicators
    }
}

enum CalendarWritingCompletion {
    static func isCompleted(_ quote: MemberQuotesData?) -> Bool {
        quote?.completed == true || quote?.todayCompleted == true
    }
}
