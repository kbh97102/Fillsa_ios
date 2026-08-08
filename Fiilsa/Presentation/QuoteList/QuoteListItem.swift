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
        VStack(spacing: 0) {
            header
            bodyContent
                .frame(height: 162)
        }
        .frame(width: 150, height: 200)
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
        .frame(maxWidth: .infinity, minHeight: 38, maxHeight: 38)
        .background(FillsaColor.secondaryContainer)
    }

    private var bodyContent: some View {
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
                .frame(width: 150, height: 106)

                if hasMemo {
                    indicator
                        .padding(.top, 2)
                }

                Spacer(minLength: 0)

                QuoteListItemBottomSection(hasMemo: hasMemo, isLike: isLike)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 10)
            }
        }
        .frame(width: 150, height: 162)
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
    let hasMemo: Bool
    let isLike: Bool

    var body: some View {
        HStack(spacing: 6) {
            if hasMemo {
                badge {
                    Image(systemName: "note.text")
                        .font(.system(size: 11, weight: .semibold))
                    Text("메모")
                }
            } else {
                Color.clear
            }

            if isLike {
                badge {
                    CalendarIcon(kind: .heart)
                        .frame(width: 12, height: 12)
                    Text("좋아요")
                }
            } else {
                Color.clear
            }
        }
    }

    private func badge<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 4) {
            content()
                .font(FillsaTypography.body4)
                .foregroundStyle(FillsaColor.onBackground1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(FillsaColor.backgroundContainer.opacity(0.6))
        )
    }
}

#Preview {
    QuoteListItem(data: QuoteListSampleData.items[0])
        .frame(width: 150, height: 162)
        .padding()
        .background(FillsaColor.background)
}
