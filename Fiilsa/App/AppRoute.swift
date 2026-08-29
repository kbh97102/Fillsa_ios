import Foundation

enum AppTab: String, CaseIterable, Equatable, Identifiable {
    case home
    case quoteList
    case calendar
    case myPage

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:
            "Home"
        case .quoteList:
            "List"
        case .calendar:
            "Calendar"
        case .myPage:
            "My page"
        }
    }
}

enum AppScreen: Equatable {
    case splash
    case login(isOnboarding: Bool)
    case onboardingGuide
    case main
    case typing
    case share(quote: String, author: String)
    case quoteDetail(MemberQuotesResponse)
    case memoInsert(savedMemo: String, memberQuoteSeq: Int)
    case notice
    case noticeDetail(NoticeResponse)
    case alert
}
