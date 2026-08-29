//
//  CalendarSelectedQuoteSection.swift
//  Fiilsa
//

import SwiftUI

struct CalendarSelectedDaySection: View {
    let selectedDayQuote: String
    let selectedDay: Date
    let isWritingCompleted: Bool
    let onClick: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            if !isWritingCompleted {
                CalendarNoWritingMessage()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            CalendarSelectedQuoteSection(
                selectedDayQuote: selectedDayQuote,
                selectedDay: selectedDay,
                onClick: onClick
            )
        }
        .frame(height: isWritingCompleted ? 80 : 165)
    }
}

private struct CalendarNoWritingMessage: View {
    var body: some View {
        HStack(spacing: 0) {
            Image("calendar_empty_handwriting")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)

            Text("필사하지 않은 날이에요.\n아래 필사를 선택하여 기록해주세요!")
                .font(FillsaTypography.body3)
                .foregroundStyle(FillsaColor.purple01)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 0)
                .padding(.trailing, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CalendarSelectedQuoteSection: View {
    let selectedDayQuote: String
    let selectedDay: Date
    let onClick: () -> Void

    @Environment(\.colorScheme) private var colorScheme

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
                        .foregroundStyle(selectedDateColor)

                    Text(FillsaCalendarDateSupport.shortWeekdayString(for: selectedDay))
                        .font(FillsaTypography.body4)
                        .foregroundStyle(selectedDateColor)
                }
                .padding(.vertical, 16)
                .padding(.leading, 20)

                Text(selectedDayQuote)
                    .font(FillsaTypography.body3)
                    .foregroundStyle(FillsaColor.onBackground1)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    .padding(.trailing, 10)
                    .padding(.vertical, 10)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(cardFill)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(cardBorder, lineWidth: 1)
            }
            .frame(height: 80)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(FillsaAccessibilityIdentifier.calendarSelectedQuote)
    }

    private var selectedDateColor: Color {
        colorScheme == .dark ? FillsaColor.white : FillsaColor.purple01
    }

    private var cardFill: Color {
        colorScheme == .dark ? FillsaColor.gray600 : FillsaColor.yellow01
    }

    private var cardBorder: Color {
        colorScheme == .dark ? FillsaColor.yellow02 : FillsaColor.purple01
    }
}

#Preview {
    CalendarSelectedDaySection(
        selectedDayQuote: "상황을 가장 잘 활용하는 사람이 가장 좋은 상황을 맞는다.",
        selectedDay: Date(),
        isWritingCompleted: false,
        onClick: {}
    )
    .padding()
    .background(FillsaColor.background)
}
