//
//  QuoteListSampleData.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

enum QuoteListSampleData {
    static let items: [MemberQuotesResponse] = [
        MemberQuotesResponse(
            memberQuoteSeq: 1,
            quoteDate: "2026-06-15",
            quoteDayOfWeek: "MONDAY",
            korQuote: "상황을 가장 잘 활용하는 사람이 가장 좋은 상황을 맞는다.",
            engQuote: nil,
            korAuthor: "존 우든",
            engAuthor: "John Wooden",
            authorUrl: "",
            memo: "오늘도 한 줄을 남겼다.",
            memoYn: "Y",
            likeYn: "Y",
            imagePath: ""
        ),
        MemberQuotesResponse(
            memberQuoteSeq: 2,
            quoteDate: "2026-06-14",
            quoteDayOfWeek: "SUNDAY",
            korQuote: "작은 반복이 하루를 바꾼다.",
            engQuote: nil,
            korAuthor: "",
            engAuthor: "",
            authorUrl: "",
            memo: "",
            memoYn: "N",
            likeYn: "N",
            imagePath: ""
        ),
    ]
}
