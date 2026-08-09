//
//  QuoteListItem.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct QuoteListItem: View {
    let data: MemberQuotesResponse
    @State private var selectedPage = 0

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                header
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height * 38 / 200
                    )

                bodyContent(cardSize: proxy.size)
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height * 162 / 200
                    )
            }
        }
        .aspectRatio(150 / 200, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            Color.clear
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("quoteList.cardFrame.\(data.id)")
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text(data.quoteDate.replacingOccurrences(of: "-", with: "."))
                .font(FillsaTypography.body4)
                .bold()
                .foregroundStyle(FillsaColor.onSecondaryContainer1)
                .lineLimit(1)

            Text(QuoteListDateSupport.koreanWeekday(data.quoteDayOfWeek))
                .font(FillsaTypography.body4)
                .foregroundStyle(FillsaColor.onSecondaryContainer1)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FillsaColor.secondaryContainer)
    }

    private func bodyContent(cardSize: CGSize) -> some View {
        ZStack {
            backgroundImage

            VStack(spacing: 0) {
                TabView(selection: $selectedPage) {
                    pagerText(quote)
                        .tag(0)

                    if hasMemo {
                        pagerText(data.memo ?? "")
                            .tag(1)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .frame(
                    width: cardSize.width,
                    height: cardSize.height * 106 / 200
                )

                if hasMemo {
                    indicator
                        .padding(.top, 2)
                }

                Spacer(minLength: 0)

                QuoteListItemBottomSection(
                    quoteID: String(data.id),
                    hasMemo: hasMemo,
                    isLike: isLike
                )
                .frame(
                    width: max(0, cardSize.width - 16),
                    height: cardSize.height * 20 / 200
                )
                .padding(.bottom, cardSize.height * 10 / 200)
            }
            .frame(
                width: cardSize.width,
                height: cardSize.height * 162 / 200
            )
        }
        .clipped()
    }

    @ViewBuilder
    private var backgroundImage: some View {
        if let imagePath = data.imagePath,
           !imagePath.isEmpty,
           let url = URL(string: imagePath) {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                        .overlay(FillsaColor.gray700.opacity(0.3))
                default:
                    defaultBackground
                }
            }
            .clipped()
        } else {
            defaultBackground
        }
    }

    private var defaultBackground: some View {
        Image("quote_list_card_photo")
            .resizable()
            .scaledToFill()
            .overlay(FillsaColor.gray700.opacity(0.3))
            .clipped()
    }

    private func pagerText(_ text: String) -> some View {
        Text(text)
            .font(FillsaTypography.subtitle2)
            .foregroundStyle(FillsaColor.white)
            .multilineTextAlignment(.center)
            .lineLimit(5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var indicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<2, id: \.self) { index in
                Circle()
                    .fill(selectedPage == index ? FillsaColor.yellow02 : FillsaColor.gray200)
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var quote: String {
        if let korQuote = data.korQuote, !korQuote.isEmpty {
            return korQuote
        }
        return data.engQuote ?? ""
    }

    private var hasMemo: Bool {
        data.memoYn == "Y"
    }

    private var isLike: Bool {
        data.likeYn == "Y"
    }
}

private struct QuoteListItemBottomSection: View {
    let quoteID: String
    let hasMemo: Bool
    let isLike: Bool

    var body: some View {
        HStack(spacing: 6) {
            if hasMemo {
                badge(identifier: "quoteList.card.\(quoteID).memoBadge") {
                    Image(systemName: "note.text")
                        .font(.system(size: 11, weight: .semibold))
                    Text("메모")
                }
            } else {
                Color.clear
            }

            if isLike {
                badge(identifier: "quoteList.card.\(quoteID).likeBadge") {
                    CalendarIcon(kind: .heart)
                        .frame(width: 12, height: 12)
                    Text("좋아요")
                }
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func badge<Content: View>(
        identifier: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 4) {
            content()
                .font(FillsaTypography.body4)
                .foregroundStyle(FillsaColor.onBackground1)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background(
            Capsule()
                .fill(FillsaColor.backgroundContainer.opacity(0.6))
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }
}

#Preview {
    QuoteListItem(data: QuoteListSampleData.items[0])
        .frame(width: 150, height: 162)
        .padding()
        .background(FillsaColor.background)
}
