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

struct HomeHeader: View {
    let myPage: () -> Void
    let streakCount: Int?

    init(myPage: @escaping () -> Void, streakCount: Int? = nil) {
        self.myPage = myPage
        self.streakCount = streakCount
    }

    var body: some View {
        HStack {
            Image("home_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 26.666)

            Spacer()

            if let streakCount {
                HStack(spacing: 2) {
                    Image("home_flame")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text("\(streakCount)일")
                        .font(FillsaTypography.subtitle1)
                        .foregroundStyle(FillsaColor.gray700)
                }
                .padding(.trailing, 10)
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
}

struct HomeDateControls: View {
    let date: Date
    let completedWritingDates: Set<String>

    var body: some View {
        HStack(spacing: 9) {
            HomeMonthSelector(date: date)
            HomeWeekStrip(selectedDate: date, completedWritingDates: completedWritingDates)
        }
    }
}

struct HomeMonthSelector: View {
    let date: Date

    var body: some View {
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

    init(
        selectedDate: Date,
        completedWritingDates: Set<String>,
        calendar: Calendar = .current
    ) {
        self.selectedDate = selectedDate
        self.completedWritingDates = completedWritingDates
        self.calendar = calendar
    }

    var body: some View {
        HStack(spacing: 5) {
            ForEach(days, id: \.self) { day in
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
        }
    }

    private var days: [Date] {
        (-2...4).compactMap { calendar.date(byAdding: .day, value: $0, to: selectedDate) }
    }

    private func foreground(for date: Date) -> Color {
        switch dayState(for: date) {
        case .selected:
            FillsaColor.gray700
        case .completed:
            FillsaColor.white
        case .default:
            FillsaColor.gray400
        }
    }

    private func background(for date: Date) -> Color {
        switch dayState(for: date) {
        case .selected:
            FillsaColor.white
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
    let recordAnswer: () -> Void

    private let question = "누군가의 호의를 한참 뒤에야 받아들인 적 있나요?"
    private let placeholder = "오늘의 질문을 보고 떠오른 생각을 자유롭게 기록해보세요."

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("오늘의 질문")
                .font(FillsaTypography.subtitle2)
                .foregroundStyle(FillsaColor.purple01)

            Text(question)
                .font(FillsaTypography.body3)
                .foregroundStyle(Color(hex: 0x211F1B))

            ZStack(alignment: .topLeading) {
                TextEditor(text: limitedAnswer)
                    .font(FillsaTypography.body4)
                    .foregroundStyle(FillsaColor.gray700)
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityIdentifier("home.answer")
                    .accessibilityLabel("오늘의 답변")
                    .accessibilityHint("최대 200자까지 입력할 수 있습니다.")

                if answer.isEmpty {
                    Text(placeholder)
                        .font(FillsaTypography.body4)
                        .foregroundStyle(FillsaColor.gray400)
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 174, maxHeight: 174)
            .background(Color.white.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).stroke(Color(hex: 0xDED4BD), lineWidth: 1))

            Text("\(answer.count) / \(HomeAnswerInput.maximumCharacterCount)")
                .font(FillsaTypography.body4)
                .foregroundStyle(Color(hex: 0x8D877D))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, -1)

            Button(action: recordAnswer) {
                HStack(spacing: 4) {
                    Image("home_answer_record")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                    Text("내 답변 기록하기")
                        .font(FillsaTypography.subtitle1)
                }
                .foregroundStyle(FillsaColor.white)
                .frame(maxWidth: .infinity)
                .frame(height: 49)
                .background(FillsaColor.purple01)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.recordAnswer")
            .accessibilityLabel("내 답변 기록하기")
            .accessibilityHint("기존 명언 필사 화면으로 이동합니다. 입력한 답변은 아직 저장되지 않습니다.")
        }
    }

    private var limitedAnswer: Binding<String> {
        Binding(
            get: { answer },
            set: { answer = HomeAnswerInput.limit($0) }
        )
    }
}

/// Figma `2929:15503` action row. Each callback preserves the Home feature's existing action flow.
struct HomeQuoteActionRow: View {
    let copy: () -> Void
    let share: () -> Void
    let isLike: Bool
    let setIsLike: (Bool) -> Void
    let registerImage: () -> Void

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
            .fill(Color(hex: 0x9D8961).opacity(0.25))
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
            .foregroundStyle(Color(hex: 0x565149))
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
            .foregroundStyle(Color(hex: 0x565149))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }
}
