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
    let openTyping: () -> Void
    let openShare: (String, String) -> Void

    @State private var isImageDialogPresented = false

    init(
        date: Date = Date(),
        korQuote: String = "상황을 가장 잘 활용하는 사람이 가장 좋은 상황을 맞는다.",
        engQuote: String = "Things turn out best for the people who make the best of the way things turn out.",
        korAuthor: String = "존 우든",
        engAuthor: String = "John Wooden",
        openTyping: @escaping () -> Void = {},
        openShare: @escaping (String, String) -> Void = { _, _ in }
    ) {
        self.date = date
        self.korQuote = korQuote
        self.engQuote = engQuote
        self.korAuthor = korAuthor
        self.engAuthor = engAuthor
        self.openTyping = openTyping
        self.openShare = openShare
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HomeTopBar()

                HStack(alignment: .center, spacing: 20) {
                    DateSection(date: date)

                    HomeImageSection(
                        onClick: {
                            isImageDialogPresented = true
                        }
                    )
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
                    date: date,
                    navigate: openTyping
                )
                .padding(.top, 20)
                .padding(.horizontal, 20)

                HomeInteractionButtonSection(
                    copy: {
                        UIPasteboard.general.string = "\(quote)\n\(author)"
                    },
                    share: {
                        openShare(quote, author)
                    },
                    isLike: isLike,
                    setIsLike: { isLike = $0 }
                )
                .padding(.top, 28)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FillsaColor.background.ignoresSafeArea())

            if isImageDialogPresented {
                HomeImageDialog(
                    quote: quote,
                    author: author,
                    imagePath: "",
                    dismiss: {
                        isImageDialogPresented = false
                    },
                    delete: {}
                )
            }
        }
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
