import Foundation

protocol HomeRepository {
    func getDailyQuoteNoToken(quoteDate: String) async throws -> DailyQuoteNoToken
    func getDailyQuote(quoteDate: String) async throws -> DailyQuote
    func postLike(_ request: LikeRequest, dailyQuoteSeq: Int) async throws -> Int
    func postUploadImage(fileURL: URL, dailyQuoteSeq: Int) async throws -> MemberQuoteImageResponse
    func deleteUploadImage(dailyQuoteSeq: Int) async throws -> Int
}

