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

                VStack(spacing: 0) {
                    HStack(spacing: 2) {
                        CalendarIcon(kind: .note)
                            .frame(width: 12, height: 12)
                            .opacity(quoteData?.completed == true ? 1 : 0)

                        CalendarIcon(kind: .heart)
                            .frame(width: 12, height: 12)
                            .opacity(quoteData?.likeYn == "Y" ? 1 : 0)
                    }
                    .frame(minHeight: 12)

                    HStack {
                        CalendarIcon(kind: .flame)
                            .frame(width: 12, height: 12)
                            .opacity(quoteData?.todayCompleted == true ? 1 : 0)
                    }
                    .frame(minHeight: 12)
                }
                .padding(.top, 3)
                .padding(.horizontal, 5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(FillsaColor.purple01)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .frame(minHeight: 44)
    }

    private var dayTextColor: Color {
        if isEnabled {
            isSelected ? FillsaColor.white : FillsaColor.gray700
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
    .background(FillsaColor.yellow01)
}
