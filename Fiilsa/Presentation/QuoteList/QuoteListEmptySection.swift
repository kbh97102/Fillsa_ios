//
//  QuoteListEmptySection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct QuoteListEmptySection: View {
    @Environment(\.colorScheme) private var colorScheme
    let emptyState: QuoteListFeature.EmptyState

    var body: some View {
        VStack(spacing: 0) {
            icon
                .frame(width: 100, height: 100)

            Text(title)
                .font(FillsaTypography.subtitle1)
                .foregroundStyle(titleColor)
                .padding(.top, 20)

            Text(subtitle)
                .font(FillsaTypography.body2)
                .foregroundStyle(FillsaColor.onBackground1)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier(emptyState == .general ? "quoteList.empty.general" : "quoteList.empty.searchResult")
    }

    @ViewBuilder
    private var icon: some View {
        switch emptyState {
        case .general:
            Image("quote_list_empty_general")
                .resizable()
                .scaledToFit()
                .accessibilityIdentifier("quoteList.empty.general.icon")
        case .searchResult:
            Image("quote_list_empty_calendar")
                .resizable()
                .scaledToFit()
        }
    }

    private var title: String {
        switch emptyState {
        case .general: "텅 비었어요!"
        case .searchResult: "조회 결과가 없어요 :("
        }
    }

    private var subtitle: String {
        switch emptyState {
        case .general: "필사하거나 좋아요한 문장이 여기에 보여요 :)"
        case .searchResult: "기간을 다시 선택해주세요."
        }
    }

    private var titleColor: Color {
        switch emptyState {
        case .general:
            colorScheme == .dark ? FillsaColor.white : FillsaColor.purple01
        case .searchResult:
            FillsaColor.purple01
        }
    }
}

#Preview {
    QuoteListEmptySection(emptyState: .general)
        .padding()
        .background(FillsaColor.background)
}
