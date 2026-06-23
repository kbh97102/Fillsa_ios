//
//  QuoteDetailView.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct QuoteDetailView: View {
    @State private var selectedLocale: HomeLocaleType = .kor
    @Environment(\.openURL) private var openURL

    let data: MemberQuotesResponse
    let back: () -> Void
    let openMemo: (String, Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HeaderSection(title: "메모", back: back)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if let imagePath = data.imagePath, !imagePath.isEmpty {
                        detailImage(imagePath)
                            .padding(.vertical, 20)
                    }

                    HStack {
                        Spacer()
                        HomeLocaleSwitch(selected: $selectedLocale)
                    }

                    MemoQuoteSection(
                        quote: quote,
                        author: author,
                        authorTapped: {
                            if let url = URL(string: data.authorUrl), !data.authorUrl.isEmpty {
                                openURL(url)
                            }
                        }
                    )
                        .padding(.top, 20)

                    MemoSection(
                        memo: data.memo ?? "",
                        onClick: {
                            openMemo(data.memo ?? "", data.memberQuoteSeq)
                        }
                    )
                    .padding(.top, 20)
                    .padding(.bottom, 50)
                }
            }
        }
        .padding(.horizontal, 20)
        .background(FillsaColor.background.ignoresSafeArea())
    }

    private func detailImage(_ imagePath: String) -> some View {
        AsyncImage(url: URL(string: imagePath)) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                LinearGradient(
                    colors: [Color(hex: 0xFEFED6), Color(hex: 0xE6B5C1), Color(hex: 0xC990CE)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .aspectRatio(320 / 350, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color(hex: 0x898989).opacity(0.5), radius: 23.2)
    }

    private var quote: String {
        if selectedLocale == .kor {
            return data.korQuote ?? ""
        }
        return data.engQuote ?? ""
    }

    private var author: String {
        if selectedLocale == .kor {
            return data.korAuthor ?? ""
        }
        return data.engAuthor ?? ""
    }
}

#Preview {
    QuoteDetailView(
        data: QuoteListSampleData.items[0],
        back: {},
        openMemo: { _, _ in }
    )
}
