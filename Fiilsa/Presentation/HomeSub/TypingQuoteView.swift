//
//  TypingQuoteView.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct TypingQuoteView: View {
    @State private var selectedLocale: HomeLocaleType = .kor
    @State private var korTyping = ""
    @State private var engTyping = ""
    @State private var isLike = false

    let korQuote: String
    let engQuote: String
    let korAuthor: String
    let engAuthor: String
    let back: () -> Void
    let share: (String, String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            topSection

            VStack(spacing: 0) {
                TypingQuoteBodySection(
                    quote: quote,
                    write: selectedLocale == .kor ? $korTyping : $engTyping
                )
                .padding(.top, 20)

                Spacer()

                bottomSection
            }
            .padding(.horizontal, 20)
        }
        .background(FillsaColor.white.ignoresSafeArea())
    }

    private var topSection: some View {
        HStack {
            Button(action: back) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(FillsaColor.gray700)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Spacer()

            HomeLocaleSwitch(selected: $selectedLocale)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 7)
    }

    private var bottomSection: some View {
        HStack {
            HomeInteractionButtonSection(
                copy: {
                    UIPasteboard.general.string = "\(quote)\n\(author)"
                },
                share: {
                    share(quote, author)
                },
                isLike: isLike,
                setIsLike: { isLike = $0 }
            )
            .frame(maxWidth: 180)

            Spacer()

            Button(action: back) {
                Text("저장하기")
                    .font(FillsaTypography.body3)
                    .foregroundStyle(FillsaColor.gray700)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(FillsaColor.gray700, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 24)
    }

    private var quote: String {
        selectedLocale == .kor ? korQuote : engQuote
    }

    private var author: String {
        selectedLocale == .kor ? korAuthor : engAuthor
    }
}

#Preview {
    TypingQuoteView(
        korQuote: "상황을 가장 잘 활용하는 사람이 가장 좋은 상황을 맞는다.",
        engQuote: "Things turn out best for the people who make the best of the way things turn out.",
        korAuthor: "존 우든",
        engAuthor: "John Wooden",
        back: {},
        share: { _, _ in }
    )
}
