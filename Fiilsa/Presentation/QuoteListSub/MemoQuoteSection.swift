//
//  MemoQuoteSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct MemoQuoteSection: View {
    let quote: String
    let author: String

    var body: some View {
        VStack(spacing: 12) {
            Text(quote)
                .font(FillsaTypography.body2)
                .foregroundStyle(FillsaColor.gray700)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Text(author)
                .font(FillsaTypography.body2)
                .foregroundStyle(FillsaColor.gray700)
                .underline()
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FillsaColor.white)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(FillsaColor.purple02, lineWidth: 1)
        }
    }
}

#Preview {
    MemoQuoteSection(
        quote: "상황을 가장 잘 활용하는 사람이 가장 좋은 상황을 맞는다.",
        author: "존 우든"
    )
    .padding()
    .background(FillsaColor.background)
}
