struct NoticeResponse: Codable, Equatable, Identifiable {
    var id: Int { noticeSeq }

    let noticeSeq: Int
    let title: String
    let content: String
    let createdAt: String
}

struct PageResponseNoticeResponse: Codable, Equatable {
    let content: [NoticeResponse]
    let totalElements: Int
    let totalPages: Int
    let currentPage: Int
}

struct PopupResponse: Codable, Equatable {
    let popupSeq: Int
    let popupType: String
    let title: String?
    let content: String?
    let imageUrl: String?
}

struct MemberStreakResponse: Codable, Equatable {
    let currentStreak: Int
    let isTodayWritten: Bool
}

struct WritingStatusDto: Codable, Equatable {
    let currentStreak: Int
    let isTodayWritten: Bool
}

struct ErrorResponse: Codable, Equatable, Error {
    let timestamp: String
    let httpStatus: Int
    let errorCode: Int
    let message: String

    static let tokenExpired = ErrorResponse(timestamp: "", httpStatus: 403, errorCode: 403, message: "")
    static let defaultError = ErrorResponse(timestamp: "", httpStatus: 499, errorCode: -1, message: "Error")
    static let networkError = ErrorResponse(timestamp: "", httpStatus: 404, errorCode: 404, message: "Network Error")
}

