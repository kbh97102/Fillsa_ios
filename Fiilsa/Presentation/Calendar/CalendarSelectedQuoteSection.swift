//
//  CalendarSelectedQuoteSection.swift
//  Fiilsa
//

import SwiftUI

/// Figma selected and expanded calendar states (2985:22510, 2987:22796).
/// Calendar owns no quote mutation, sharing, image, or prompt-answer contract,
/// so the corresponding affordances are rendered disabled rather than routed to
/// a different feature or silently persisted as a quote transcript.
struct CalendarSelectedDaySection: View {
    let selectedDayRecord: MemberQuotesData?
    let selectedDay: Date
    let onClick: () -> Void

    private var presentation: CalendarSelectedDayPresentation {
        CalendarSelectedDayPresentation.resolve(for: selectedDayRecord)
    }

    var body: some View {
        VStack(spacing: 10) {
            if presentation == .incomplete {
                CalendarNoWritingMessage()
                    .frame(height: 100)
            }

            CalendarSelectedQuoteSection(
                selectedDayQuote: selectedDayRecord?.quote ?? "",
                selectedDay: selectedDay,
                isCompleted: presentation == .completed,
                isLiked: selectedDayRecord?.likeYn == "Y",
                onClick: onClick
            )

            if presentation == .completed {
                CalendarQuestionAnswerSection()
                    .padding(.top, 3)
            }
        }
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
                .padding(.trailing, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CalendarSelectedQuoteSection: View {
    let selectedDayQuote: String
    let selectedDay: Date
    let isCompleted: Bool
    let isLiked: Bool
    let onClick: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(
        selectedDayQuote: String,
        selectedDay: Date,
        isCompleted: Bool = false,
        isLiked: Bool = false,
        onClick: @escaping () -> Void = {}
    ) {
        self.selectedDayQuote = selectedDayQuote
        self.selectedDay = selectedDay
        self.isCompleted = isCompleted
        self.isLiked = isLiked
        self.onClick = onClick
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onClick) {
                quoteContent
                    .frame(height: isCompleted ? 91 : 80)
            }
            .buttonStyle(.plain)

            if isCompleted {
                CalendarUnavailableQuoteActionRow(isLiked: isLiked)
                    .frame(height: 42)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(cardFill)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(cardBorder, lineWidth: 1)
        }
        .accessibilityIdentifier(FillsaAccessibilityIdentifier.calendarSelectedQuote)
    }

    private var quoteContent: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(spacing: 0) {
                Text(FillsaCalendarDateSupport.dayString(for: selectedDay))
                    .font(FillsaTypography.heading4)
                    .foregroundStyle(selectedDateColor)

                Text(FillsaCalendarDateSupport.shortWeekdayString(for: selectedDay))
                    .font(FillsaTypography.body4)
                    .foregroundStyle(selectedDateColor)
            }
            .frame(width: 62)

            Text(selectedDayQuote)
                .font(FillsaTypography.body3)
                .foregroundStyle(FillsaColor.onBackground1)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 10)
        }
    }

    private var selectedDateColor: Color {
        colorScheme == .dark ? FillsaColor.white : FillsaColor.purple01
    }

    private var cardFill: Color {
        colorScheme == .dark ? FillsaColor.gray600 : FillsaColor.white
    }

    private var cardBorder: Color {
        colorScheme == .dark ? FillsaColor.gray500 : .clear
    }
}

private struct CalendarUnavailableQuoteActionRow: View {
    let isLiked: Bool

    var body: some View {
        HStack(spacing: 0) {
            action("home_action_copy", "복사")
            divider
            action("home_action_share", "공유")
            divider
            likeAction
            divider
            action("home_action_camera", "이미지 등록")
        }
        .foregroundStyle(FillsaColor.gray500)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("명언 작업")
        .accessibilityHint("캘린더에는 복사, 공유, 좋아요, 이미지 등록 동작 계약이 아직 없습니다.")
    }

    private func action(_ icon: String, _ title: String) -> some View {
        HStack(spacing: 4) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text(title)
                .font(FillsaTypography.body4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var likeAction: some View {
        HStack(spacing: 4) {
            if isLiked {
                HeartActionIcon(isFilled: true)
                    .frame(width: 16, height: 16)
            } else {
                Image("home_action_like")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
            Text("좋아요")
                .font(FillsaTypography.body4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(FillsaColor.gray200)
            .frame(width: 1, height: 28)
    }
}

private struct CalendarQuestionAnswerSection: View {
    @State private var answer = ""

    var body: some View {
        HomeQuestionAnswerCard(answer: $answer, recordAnswer: {
            // CalendarFeature has no answer-record persistence or navigation
            // contract. The Figma CTA remains visually present but has no side
            // effect until that separate product contract is introduced.
        })
        .accessibilityHint("답변은 최대 200자까지 입력할 수 있습니다. 저장 기능은 아직 제공되지 않습니다.")
    }
}

#Preview {
    CalendarSelectedDaySection(
        selectedDayRecord: nil,
        selectedDay: Date(),
        onClick: {}
    )
    .padding(20)
    .background(FillsaColor.background)
}
