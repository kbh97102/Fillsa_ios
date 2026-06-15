//
//  QuoteListEmptySection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct QuoteListEmptySection: View {
    var body: some View {
        VStack(spacing: 0) {
            QuoteListEmptyIcon()
                .frame(width: 100, height: 100)

            Text("텅 비었어요!")
                .font(FillsaTypography.subtitle1)
                .foregroundStyle(FillsaColor.purple01)
                .padding(.top, 20)

            Text("필사하거나 좋아요한 문장이 여기에 보여요 :)")
                .font(FillsaTypography.body2)
                .foregroundStyle(FillsaColor.gray700)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    QuoteListEmptySection()
        .padding()
        .background(FillsaColor.background)
}
