//
//  CalendarDayCell.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let quoteData: MemberQuotesData?
    let isSelected: Bool
    let isEnabled: Bool
    let isCurrentMonth: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            VStack(spacing: 0) {
                Text(FillsaCalendarDateSupport.dayString(for: date))
                    .font(FillsaTypography.body3)
                    .foregroundStyle(dayTextColor)

                HStack(spacing: 2) {
                    ForEach(CalendarRecordIndicators.resolve(for: quoteData), id: \.self) { indicator in
                        CalendarIcon(
                            kind: indicator == .heart ? .heart : .flame,
                            size: .compact
                        )
                        .frame(width: 12, height: 12)
                    }
                }
                .frame(minHeight: 12)
                .padding(.top, 3)
                .padding(.horizontal, 5)
            }
            .frame(width: 36, height: 50)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(FillsaColor.purple01)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .frame(width: 36, height: 50)
    }

    private var dayTextColor: Color {
        if isEnabled {
            isSelected ? FillsaColor.onPrimaryContainer : FillsaColor.onBackground1
        } else {
            isCurrentMonth ? FillsaColor.gray400 : FillsaColor.gray400
        }
    }
}

#Preview {
    CalendarDayCell(
        date: Date(),
        quoteData: MemberQuotesData(
            dailyQuoteSeq: 1,
            quoteDate: FillsaCalendarDateSupport.quoteDateString(for: Date()),
            quote: "quote",
            author: "author",
            completed: true,
            likeYn: "Y",
            todayCompleted: true
        ),
        isSelected: true,
        isEnabled: true,
        isCurrentMonth: true,
        onClick: {}
    )
    .frame(width: 52, height: 64)
    .background(FillsaColor.backgroundContainer)
}
