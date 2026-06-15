//
//  CalendarSelectedQuoteSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct CalendarSelectedQuoteSection: View {
    let selectedDayQuote: String
    let selectedDay: Date
    let onClick: () -> Void

    init(
        selectedDayQuote: String,
        selectedDay: Date,
        onClick: @escaping () -> Void = {}
    ) {
        self.selectedDayQuote = selectedDayQuote
        self.selectedDay = selectedDay
        self.onClick = onClick
    }

    var body: some View {
        Button(action: onClick) {
            HStack(alignment: .center, spacing: 0) {
                VStack(spacing: 0) {
                    Text(FillsaCalendarDateSupport.dayString(for: selectedDay))
                        .font(FillsaTypography.heading4)
                        .foregroundStyle(FillsaColor.purple01)

                    Text(FillsaCalendarDateSupport.shortWeekdayString(for: selectedDay))
                        .font(FillsaTypography.body4)
                        .foregroundStyle(FillsaColor.purple01)
                }
                .padding(.vertical, 16)
                .padding(.leading, 20)

                Text(selectedDayQuote)
                    .font(FillsaTypography.body3)
                    .foregroundStyle(FillsaColor.gray700)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    .padding(.trailing, 10)
                    .padding(.vertical, 10)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(FillsaColor.white)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CalendarSelectedQuoteSection(
        selectedDayQuote: "상황을 가장 잘 활용하는 사람이 가장 좋은 상황을 맞는다.",
        selectedDay: Date()
    )
    .padding()
    .background(FillsaColor.background)
}
