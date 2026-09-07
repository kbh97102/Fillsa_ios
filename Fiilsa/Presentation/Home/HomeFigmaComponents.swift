import Foundation
import SwiftUI

enum HomeCompletionDateKey {
    static func make(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else {
            return ""
        }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}

enum HomeWeekStripDayState: Equatable {
    case selected
    case completed
    case `default`

    static func resolve(isSelected: Bool, isCompleted: Bool) -> Self {
        if isSelected {
            return .selected
        }
        if isCompleted {
            return .completed
        }
        return .default
    }
}

enum HomeFigmaColorToken: Equatable {
    case primary
    case yellow01
    case white
    case gray700
    case gray600
    case gray500
    case gray400
    case gray200
    case lightAnswerBorder
    case lightAnswerCount
    case lightActionText
    case lightActionDivider
    case clear

    var color: Color {
        switch self {
        case .primary: FillsaColor.primary
        case .yellow01: FillsaColor.yellow01
        case .white: FillsaColor.white
        case .gray700: FillsaColor.gray700
        case .gray600: FillsaColor.gray600
        case .gray500: FillsaColor.gray500
        case .gray400: FillsaColor.gray400
        case .gray200: FillsaColor.gray200
        case .lightAnswerBorder: Color(hex: 0xDED4BD)
        case .lightAnswerCount: Color(hex: 0x8D877D)
        case .lightActionText: Color(hex: 0x565149)
        case .lightActionDivider: Color(hex: 0x9D8961)
        case .clear: .clear
        }
    }
}

/// Figma `3039:26518` color contract. Keeping the choices pure makes dark-mode
/// reviewable without relying on a screenshot-only assertion.
struct HomeFigmaPalette: Equatable {
    let rootBackground: HomeFigmaColorToken
    let cardBackground: HomeFigmaColorToken
    let cardBorder: HomeFigmaColorToken
    let primaryText: HomeFigmaColorToken
    let actionText: HomeFigmaColorToken
    let weekdayDefault: HomeFigmaColorToken
    let answerFieldBackground: HomeFigmaColorToken
    let answerFieldBorder: HomeFigmaColorToken
    let answerPlaceholder: HomeFigmaColorToken
    let answerCount: HomeFigmaColorToken
    let actionDivider: HomeFigmaColorToken
    let mainDivider: HomeFigmaColorToken
    let mainDividerOpacity: Double
    let answerFieldOpacity: Double

    static func resolve(isDark: Bool) -> Self {
        if isDark {
            return Self(
                rootBackground: .gray700,
                cardBackground: .gray600,
                cardBorder: .gray500,
                primaryText: .white,
                actionText: .gray200,
                weekdayDefault: .gray400,
                answerFieldBackground: .gray600,
                answerFieldBorder: .gray500,
                answerPlaceholder: .gray400,
                answerCount: .gray400,
                actionDivider: .gray500,
                mainDivider: .gray500,
                mainDividerOpacity: 0.55,
                answerFieldOpacity: 1
            )
        }

        return Self(
            rootBackground: .primary,
            cardBackground: .yellow01,
            cardBorder: .clear,
            primaryText: .gray700,
            actionText: .lightActionText,
            weekdayDefault: .gray400,
            answerFieldBackground: .white,
            answerFieldBorder: .lightAnswerBorder,
            answerPlaceholder: .gray400,
            answerCount: .lightAnswerCount,
            actionDivider: .lightActionDivider,
            mainDivider: .gray700,
            mainDividerOpacity: 0.16,
            answerFieldOpacity: 0.5
        )
    }
}

struct HomeHeader: View {
    let myPage: () -> Void
    let streakCount: Int?
    let isStreakStateLoaded: Bool
    let streakStatus: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    init(
        myPage: @escaping () -> Void,
        streakCount: Int? = nil,
        isStreakStateLoaded: Bool = true,
        streakStatus: @escaping () -> Void = {}
    ) {
        self.myPage = myPage
        self.streakCount = streakCount
        self.isStreakStateLoaded = isStreakStateLoaded
        self.streakStatus = streakStatus
    }

    var body: some View {
        HStack {
            Image("home_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 26.666)

            Spacer()

            if isStreakStateLoaded {
                Button(action: streakStatus) {
                    if let streakCount {
                        HStack(spacing: 2) {
                            Image("home_flame")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text("\(streakCount)일")
                                .font(FillsaTypography.subtitle1)
                                .foregroundStyle(palette.primaryText.color)
                        }
                    } else {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundStyle(FillsaColor.purple01)
                            .frame(width: 24, height: 24)
                    }
                }
                .buttonStyle(.plain)
                .padding(.trailing, 10)
                .accessibilityIdentifier("home.streakStatus")
            }

            Button(action: myPage) {
                Image("home_profile")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
    }

    private var palette: HomeFigmaPalette {
        .resolve(isDark: colorScheme == .dark)
    }
}

struct HomeDateControls: View {
    let date: Date
    let completedWritingDates: Set<String>
    let selectCalendar: () -> Void
    let selectDate: (Date) -> Void

    init(
        date: Date,
        completedWritingDates: Set<String>,
        selectCalendar: @escaping () -> Void = {},
        selectDate: @escaping (Date) -> Void = { _ in }
    ) {
        self.date = date
        self.completedWritingDates = completedWritingDates
        self.selectCalendar = selectCalendar
        self.selectDate = selectDate
    }

    var body: some View {
        HStack(spacing: 9) {
            HomeMonthSelector(date: date, select: selectCalendar)
            HomeWeekStrip(
                selectedDate: date,
                completedWritingDates: completedWritingDates,
                selectDate: selectDate
            )
        }
    }
}

struct HomeMonthSelector: View {
    let date: Date
    let select: () -> Void

    init(date: Date, select: @escaping () -> Void = {}) {
        self.date = date
        self.select = select
    }

    var body: some View {
        Button(action: select) {
            HStack(spacing: 2) {
                Image("home_calendar_selected")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                Text(Self.monthFormatter.string(from: date))
                    .font(FillsaTypography.body4)
                    .fontWeight(.bold)
                    .foregroundStyle(FillsaColor.gray700)
            }
            .frame(width: 73, height: 30)
            .background(FillsaColor.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.calendarTrigger")
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM"
        return formatter
    }()
}

struct HomeWeekStrip: View {
    let selectedDate: Date
    let completedWritingDates: Set<String>
    let calendar: Calendar
    let selectDate: (Date) -> Void

    init(
        selectedDate: Date,
        completedWritingDates: Set<String>,
        calendar: Calendar = .current,
        selectDate: @escaping (Date) -> Void = { _ in }
    ) {
        self.selectedDate = selectedDate
        self.completedWritingDates = completedWritingDates
        self.calendar = calendar
        self.selectDate = selectDate
    }

    var body: some View {
        HStack(spacing: 5) {
            ForEach(days, id: \.self) { day in
                Button { selectDate(day) } label: {
                    Text(Self.dayFormatter.string(from: day))
                        .font(FillsaTypography.body4)
                        .foregroundStyle(foreground(for: day))
                        .frame(width: 30, height: 30)
                        .background(background(for: day))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(border(for: day), lineWidth: 1))
                        .overlay(alignment: .top) {
                            if dayState(for: day) == .completed {
                                Image("home_completed_streak")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .offset(y: -10)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    static func visibleDates(endingAt date: Date, calendar: Calendar = .current) -> [Date] {
        (-6...0).compactMap { calendar.date(byAdding: .day, value: $0, to: date) }
    }

    private var days: [Date] {
        Self.visibleDates(endingAt: selectedDate, calendar: calendar)
    }

    private func foreground(for date: Date) -> Color {
        switch dayState(for: date) {
        case .selected:
            FillsaColor.white
        case .completed:
            FillsaColor.white
        case .default:
            FillsaColor.gray400
        }
    }

    private func background(for date: Date) -> Color {
        switch dayState(for: date) {
        case .selected:
            FillsaColor.purple01
        case .completed:
            FillsaColor.purple01
        case .default:
            .clear
        }
    }

    private func border(for date: Date) -> Color {
        switch dayState(for: date) {
        case .selected, .completed:
            FillsaColor.purple01
        case .default:
            FillsaColor.gray400
        }
    }

    private func dayState(for date: Date) -> HomeWeekStripDayState {
        HomeWeekStripDayState.resolve(isSelected: isSelected(date), isCompleted: isComplete(date))
    }

    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    private func isComplete(_ date: Date) -> Bool {
        completedWritingDates.contains(HomeCompletionDateKey.make(for: date, calendar: calendar))
    }

    private static let dayFormatter: DateFormatter = { let f = DateFormatter(); f.locale = Locale(identifier: "ko_KR"); f.dateFormat = "d"; return f }()
}

enum HomeAnswerInput {
    static let maximumCharacterCount = 200

    static func limit(_ answer: String) -> String {
        String(answer.prefix(maximumCharacterCount))
    }

    static func remaining(for answer: String) -> Int {
        max(0, maximumCharacterCount - limit(answer).count)
    }
}

/// Figma `2929:13630`. The prompt remains the established static copy until Home has a question data source.
struct HomeQuestionAnswerCard: View {
    @Binding var answer: String
    let recordedAnswer: String?
    let isEditing: Bool
    let recordAnswer: () -> Void
    let editAnswer: () -> Void
    @FocusState private var isAnswerFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    private let question = "누군가의 호의를 한참 뒤에야 받아들인 적 있나요?"
    private let placeholder = "오늘의 질문을 보고 떠오른 생각을 자유롭게 기록해보세요."

    init(
        answer: Binding<String>,
        recordedAnswer: String? = nil,
        isEditing: Bool = true,
        recordAnswer: @escaping () -> Void,
        editAnswer: @escaping () -> Void = {}
    ) {
        _answer = answer
        self.recordedAnswer = recordedAnswer
        self.isEditing = isEditing
        self.recordAnswer = recordAnswer
        self.editAnswer = editAnswer
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("오늘의 질문")
                .font(FillsaTypography.subtitle2)
                .foregroundStyle(FillsaColor.purple01)

            Text(question)
                .font(FillsaTypography.body3)
                .foregroundStyle(palette.primaryText.color)

            ZStack(alignment: .topLeading) {
                TextEditor(text: limitedAnswer)
                    .font(FillsaTypography.body4)
                    .foregroundStyle(palette.primaryText.color)
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityIdentifier("home.answer")
                    .accessibilityLabel("오늘의 답변")
                    .accessibilityHint("최대 200자까지 입력할 수 있습니다.")
                    .disabled(!isEditing)
                    .focused($isAnswerFocused)

                if answer.isEmpty {
                    Text(placeholder)
                        .font(FillsaTypography.body4)
                        .foregroundStyle(palette.answerPlaceholder.color)
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 174, maxHeight: 174)
            .background(palette.answerFieldBackground.color.opacity(palette.answerFieldOpacity))
            .clipShape(RoundedRectangle(cornerRadius: 17))
            .overlay(
                RoundedRectangle(cornerRadius: 17)
                    .stroke(
                        isAnswerFocused && isEditing ? FillsaColor.purple01 : palette.answerFieldBorder.color,
                        lineWidth: 1
                    )
            )

            Text("\(isEditing ? answer.count : 0) / \(HomeAnswerInput.maximumCharacterCount)")
                .font(FillsaTypography.body4)
                .foregroundStyle(palette.answerCount.color)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, -1)

            Button(action: isEditing ? recordAnswer : editAnswer) {
                HStack(spacing: 4) {
                    Image("home_answer_record")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                    Text(isEditing ? "내 답변 기록하기" : "내 답변 수정하기")
                        .font(FillsaTypography.subtitle1)
                }
                .foregroundStyle(isEditing ? FillsaColor.white : FillsaColor.purple01)
                .frame(maxWidth: .infinity)
                .frame(height: 49)
                .background(isEditing ? FillsaColor.purple01 : Color(hex: 0xD3D5FF))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(isEditing ? "home.answerRecord" : "home.answerEdit")
            .accessibilityLabel(isEditing ? "내 답변 기록하기" : "내 답변 수정하기")
            .accessibilityHint(isEditing ? "입력한 답변을 현재 홈 화면에 기록합니다." : "기록한 답변을 수정합니다.")
        }
    }

    private var limitedAnswer: Binding<String> {
        Binding(
            get: { answer },
            set: { answer = HomeAnswerInput.limit($0) }
        )
    }

    private var palette: HomeFigmaPalette {
        .resolve(isDark: colorScheme == .dark)
    }
}

/// Figma `2929:15503` action row. Each callback preserves the Home feature's existing action flow.
struct HomeQuoteActionRow: View {
    let copy: () -> Void
    let share: () -> Void
    let isLike: Bool
    let setIsLike: (Bool) -> Void
    let registerImage: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            action("home_action_copy", "복사", copy)
                .frame(width: 80)
            divider
            action("home_action_share", "공유", share)
                .frame(width: 80)
            divider
            likeAction
                .frame(width: 80)
            divider
            action("home_action_camera", "이미지 등록", registerImage)
                .frame(width: 90)
                .accessibilityIdentifier("home.registerImage")
        }
        .frame(height: 42)
    }

    private var divider: some View {
        Rectangle()
            .fill(palette.actionDivider.color.opacity(colorScheme == .dark ? 1 : 0.25))
            .frame(width: 1, height: 28)
    }

    private var likeAction: some View {
        Button {
            setIsLike(!isLike)
        } label: {
            HStack(spacing: 4) {
                if isLike {
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
            .foregroundStyle(palette.actionText.color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func action(_ icon: String, _ title: String, _ handler: @escaping () -> Void) -> some View {
        Button(action: handler) {
            HStack(spacing: 4) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text(title)
                    .font(FillsaTypography.body4)
            }
            .foregroundStyle(palette.actionText.color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var palette: HomeFigmaPalette {
        .resolve(isDark: colorScheme == .dark)
    }
}
