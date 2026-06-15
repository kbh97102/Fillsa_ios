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

            ZStack {
                backgroundImage

                VStack(spacing: 0) {
                    TabView(selection: $selectedPage) {
                        pagerText(quote)
                            .tag(0)

                        pagerText(data.memo ?? "")
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .padding(.horizontal, 10)
                    .padding(.top, 10)

                    if hasMemo {
                        indicator
                    }

                    QuoteListItemBottomSection(hasMemo: hasMemo, isLike: isLike)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text(data.quoteDate.replacingOccurrences(of: "-", with: "."))
                .font(FillsaTypography.body4)
                .bold()
                .foregroundStyle(FillsaColor.gray700)
                .lineLimit(1)

            Text(QuoteListDateSupport.koreanWeekday(data.quoteDayOfWeek))
                .font(FillsaTypography.body4)
                .foregroundStyle(FillsaColor.gray700)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 27)
        .background(FillsaColor.purple02)
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
                default:
                    defaultBackground
                }
            }
            .overlay(FillsaColor.gray700.opacity(0.3))
            .clipped()
        } else {
            defaultBackground
                .overlay(FillsaColor.gray700.opacity(0.3))
        }
    }

    private var defaultBackground: some View {
        LinearGradient(
            stops: [
                .init(color: Color(hex: 0xFEFED6), location: 0),
                .init(color: Color(hex: 0xE6B5C1), location: 0.49),
                .init(color: Color(hex: 0xC990CE), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
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
        .padding(.top, 12)
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
        .padding(.horizontal, 8)
    }

    private func badge<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 4) {
            content()
                .font(FillsaTypography.body4)
                .foregroundStyle(FillsaColor.gray700)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(FillsaColor.white.opacity(0.6))
        )
    }
}

#Preview {
    QuoteListItem(data: QuoteListSampleData.items[0])
        .frame(width: 150, height: 162)
        .padding()
        .background(FillsaColor.background)
}
