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
    }

    @ViewBuilder
    private var icon: some View {
        switch emptyState {
        case .general:
            QuoteListEmptyIcon()
        case .searchResult:
            Image(systemName: "calendar")
                .resizable()
                .scaledToFit()
                .padding(24)
                .foregroundStyle(colorScheme == .dark ? FillsaColor.white : FillsaColor.purple01)
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
            FillsaColor.onBackground1
        }
    }
}

private struct QuoteListEmptyIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(FillsaColor.purple01, style: StrokeStyle(lineWidth: 4, dash: [6, 8]))

            Circle()
                .fill(FillsaColor.yellow02)
                .frame(width: 30, height: 30)

            Text("?")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(FillsaColor.yellow01)
        }
    }
}

#Preview {
    QuoteListEmptySection(emptyState: .general)
        .padding()
        .background(FillsaColor.background)
}
