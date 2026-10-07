//
//  CalendarSelectedQuoteSection.swift
//  Fiilsa
//

import SwiftUI

/// Figma selected and expanded calendar states (2985:22510, 2987:22796).
struct CalendarSelectedDaySection: View {
    let selectedDayRecord: MemberQuotesData?
    let selectedDay: Date
    @Binding var answer: String
    let recordedAnswer: String?
    let isEditingAnswer: Bool
    let recordAnswer: () -> Void
    let editAnswer: () -> Void
    let onClick: () -> Void
    let onCopy: () -> Void
    let onShare: () -> Void
    let onLike: () -> Void
    let onImage: () -> Void

    private var presentation: CalendarSelectedDayPresentation {
        CalendarSelectedDayPresentation.resolve(for: selectedDayRecord)
    }

    var body: some View {
        VStack(spacing: presentation == .incomplete ? -16 : 10) {
            if presentation == .incomplete {
                CalendarNoWritingMessage()
                    .frame(height: 100)
            }

            CalendarSelectedQuoteSection(
                selectedDayQuote: selectedDayRecord?.quote ?? "",
                selectedDay: selectedDay,
                isCompleted: presentation == .completed,
                onClick: onClick,
                onCopy: onCopy,
                onShare: onShare,
                onLike: onLike,
                onImage: onImage
            )

            if presentation == .completed {
                CalendarQuestionAnswerSection(
                    answer: $answer,
                    question: selectedDayRecord?.questionKo ?? "누군가의 호의를 한참 뒤에야 받아들인 적 있나요?",
                    recordedAnswer: recordedAnswer,
                    isEditing: isEditingAnswer,
                    recordAnswer: recordAnswer,
                    editAnswer: editAnswer
                )
            }
        }
        .padding(.top, presentation == .completed ? 10 : 0)
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
                .foregroundStyle(FillsaColor.dynamic(light: FillsaColor.purple01, dark: FillsaColor.yellow02))
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
    let onClick: () -> Void
    let onCopy: () -> Void
    let onShare: () -> Void
    let onLike: () -> Void
    let onImage: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(
        selectedDayQuote: String,
        selectedDay: Date,
        isCompleted: Bool = false,
        onClick: @escaping () -> Void = {},
        onCopy: @escaping () -> Void = {},
        onShare: @escaping () -> Void = {},
        onLike: @escaping () -> Void = {},
        onImage: @escaping () -> Void = {}
    ) {
        self.selectedDayQuote = selectedDayQuote
        self.selectedDay = selectedDay
        self.isCompleted = isCompleted
        self.onClick = onClick
        self.onCopy = onCopy
        self.onShare = onShare
        self.onLike = onLike
        self.onImage = onImage
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onClick) {
                quoteContent
                    .frame(height: 80)
                    .frame(height: isCompleted ? 90 : 80, alignment: .top)
            }
            .buttonStyle(.plain)

            if isCompleted {
                CalendarQuoteActionRow(
                    onCopy: onCopy,
                    onShare: onShare,
                    onLike: onLike,
                    onImage: onImage
                )
                    .frame(height: 43)
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
        colorScheme == .dark && !isCompleted ? FillsaColor.yellow02 : .clear
    }
}

private struct CalendarQuoteActionRow: View {
    let onCopy: () -> Void
    let onShare: () -> Void
    let onLike: () -> Void
    let onImage: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(FillsaColor.gray500)
                .frame(height: 1)

            HStack(spacing: 0) {
                action("home_action_copy", "복사", identifier: "calendar.copy", action: onCopy)
                    .frame(width: 70)
                divider
                action("home_action_share", "공유", identifier: "calendar.share", action: onShare)
                    .frame(width: 70)
                divider
                likeAction
                    .frame(width: 70)
                divider
                action("home_action_camera", "이미지 등록", identifier: "calendar.image", action: onImage)
                    .frame(width: 107)
            }
            .frame(height: 42)
        }
        .foregroundStyle(FillsaColor.dynamic(light: HomeFigmaColorToken.lightActionText.color, dark: FillsaColor.gray400))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("명언 작업")
    }

    private func action(_ icon: String, _ title: String, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(icon)
                    .resizable()
                    .renderingMode(icon == "home_action_camera" ? .template : .original)
                    .foregroundStyle(icon == "home_action_camera" ? FillsaColor.purple01 : FillsaColor.gray400)
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text(title)
                    .font(FillsaTypography.body4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }

    private var likeAction: some View {
        Button(action: onLike) {
            HStack(spacing: 4) {
                Image("home_action_like")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text("좋아요")
                    .font(FillsaTypography.body4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("calendar.like")
    }

    private var divider: some View {
        Rectangle()
            .fill(FillsaColor.dynamic(light: FillsaColor.gray200, dark: FillsaColor.gray500))
            .frame(width: 1, height: 28)
    }
}

private struct CalendarQuestionAnswerSection: View {
    @Binding var answer: String
    let question: String
    let recordedAnswer: String?
    let isEditing: Bool
    let recordAnswer: () -> Void
    let editAnswer: () -> Void

    var body: some View {
        HomeQuestionAnswerCard(answer: $answer, question: question,
                               recordedAnswer: recordedAnswer, isEditing: isEditing,
                               recordAnswer: recordAnswer, editAnswer: editAnswer)
    }
}

#Preview {
    CalendarSelectedDaySection(
        selectedDayRecord: nil,
        selectedDay: Date(),
        answer: .constant(""),
        recordedAnswer: nil,
        isEditingAnswer: true,
        recordAnswer: {},
        editAnswer: {},
        onClick: {},
        onCopy: {},
        onShare: {},
        onLike: {},
        onImage: {}

    )
    .padding(20)
    .background(FillsaColor.background)
}
