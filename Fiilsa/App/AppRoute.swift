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

