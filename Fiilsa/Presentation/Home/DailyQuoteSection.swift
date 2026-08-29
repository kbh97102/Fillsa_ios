import SwiftUI

enum HomeQuoteCardSwipeAction: Equatable {
    case previous
    case next
    case none

    static func resolve(translationWidth: CGFloat, canNavigateForward: Bool) -> Self {
        if translationWidth > 150 {
            return .previous
        }
        if translationWidth < -150, canNavigateForward {
            return .next
        }
        return .none
    }
}

/// Figma `2929:13642` quote card. At the latest (today) quote, the left-swipe next action is unavailable.
struct HomeQuoteCard: View {
    let text: String
    let author: String
    let date: Date
    let next: () -> Void
    let before: () -> Void
    let navigate: () -> Void
    let authorTapped: () -> Void

    init(
        text: String,
        author: String,
        date: Date = Date(),
        next: @escaping () -> Void = {},
        before: @escaping () -> Void = {},
        navigate: @escaping () -> Void = {},
        authorTapped: @escaping () -> Void = {}
    ) {
        self.text = text
        self.author = author
        self.date = date
        self.next = next
        self.before = before
        self.navigate = navigate
        self.authorTapped = authorTapped
    }

    var body: some View {
        Button(action: navigate) {
            ZStack {
                FillsaColor.yellow01

                Image("home_quote_texture")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                VStack(spacing: 0) {
                    Text(text)
                        .font(.custom("GangwonEduAll-Light", size: 16).weight(.bold))
                        .foregroundStyle(FillsaColor.gray700)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 28)
                        .padding(.horizontal, 10)

                    Spacer()

                    Button(action: authorTapped) {
                        HStack(spacing: 2) {
                            Text(author)
                                .font(FillsaTypography.body4)
                                .underline()
                            Image("home_author_search")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                        }
                        .foregroundStyle(FillsaColor.gray700)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 15)
                }
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color(hex: 0xCBC0A8, alpha: 0.7), radius: 8, y: 0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture().onEnded { value in
                switch HomeQuoteCardSwipeAction.resolve(
                    translationWidth: value.translation.width,
                    canNavigateForward: canNavigateForward
                ) {
                case .previous:
                    before()
                case .next:
                    next()
                case .none:
                    break
                }
            }
        )
    }

    private var canNavigateForward: Bool {
        let calendar = FillsaCalendarDateSupport.calendar
        return calendar.startOfDay(for: date) < calendar.startOfDay(for: Date())
    }
}
