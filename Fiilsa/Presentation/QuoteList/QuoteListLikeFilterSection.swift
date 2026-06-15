//
//  QuoteListLikeFilterSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct QuoteListLikeFilterSection: View {
    let isLike: Bool
    let setIsLike: (Bool) -> Void

    var body: some View {
        Button {
            setIsLike(!isLike)
        } label: {
            HStack(spacing: 0) {
                CalendarIcon(kind: .heart)
                    .frame(width: 16, height: 16)

                Text("좋아요")
                    .font(FillsaTypography.body2)
                    .foregroundStyle(FillsaColor.gray700)
                    .padding(.leading, 4)

                QuoteListCheckBox(isChecked: isLike)
                    .frame(width: 20, height: 20)
                    .padding(.leading, 8)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct QuoteListCheckBox: View {
    let isChecked: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .stroke(isChecked ? FillsaColor.purple01 : FillsaColor.gray400, lineWidth: 1.5)
                .background {
                    if isChecked {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(FillsaColor.purple01)
                    }
                }

            if isChecked {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(FillsaColor.white)
            }
        }
    }
}

#Preview {
    QuoteListLikeFilterSection(isLike: true, setIsLike: { _ in })
        .padding()
        .background(FillsaColor.background)
}
