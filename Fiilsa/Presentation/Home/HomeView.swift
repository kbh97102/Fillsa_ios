//
//  Home.swift
//  Fiilsa
//
//  Created by 강보훈 on 6/14/26.
//

import Foundation
import SwiftUI


struct HomeView: View {
    @State private var selectedLocale: HomeLocaleType = .kor
    @State private var isLike = false

    let date: Date
    let korQuote: String
    let engQuote: String
    let korAuthor: String
    let engAuthor: String

    init(
        date: Date = Date(),
        korQuote: String = "",
        engQuote: String = "",
        korAuthor: String = "",
        engAuthor: String = ""
    ) {
        self.date = date
        self.korQuote = korQuote
        self.engQuote = engQuote
        self.korAuthor = korAuthor
        self.engAuthor = engAuthor
    }

    var body: some View {
        VStack(spacing: 0) {
            HomeTopBar()

            HStack(alignment: .center, spacing: 20) {
                DateSection(date: date)

                HomeImageSection()
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)

            HStack {
                Spacer()

                HomeLocaleSwitch(selected: $selectedLocale)
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)

            DailyQuoteSection(
                text: quote,
                author: author,
                date: date
            )
            .padding(.top, 20)
            .padding(.horizontal, 20)

            HomeInteractionButtonSection(
                isLike: isLike,
                setIsLike: { isLike = $0 }
            )
            .padding(.top, 28)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FillsaColor.background.ignoresSafeArea())
    }

    private var quote: String {
        selectedLocale == .kor ? korQuote : engQuote
    }

    private var author: String {
        selectedLocale == .kor ? korAuthor : engAuthor
    }
}


#Preview {
    HomeView(
        korQuote: "상황을 가장 잘 활용하는 사람이 가장 좋은 상황을 맞는다.",
        engQuote: "Things turn out best for the people who make the best of the way things turn out.",
        korAuthor: "존 우든",
        engAuthor: "John Wooden"
    )
}
