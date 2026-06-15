//
//  MemoSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct MemoSection: View {
    let memo: String
    let onClick: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "note.text")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(FillsaColor.gray700)

                Text("메모")
                    .font(FillsaTypography.body2)
                    .foregroundStyle(FillsaColor.gray700)
            }

            Button(action: onClick) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(FillsaColor.white)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(FillsaColor.purple02, lineWidth: 1)
                        }

                    Text(memo.isEmpty ? "메모를 남겨주세요." : memo)
                        .font(FillsaTypography.body3)
                        .foregroundStyle(memo.isEmpty ? FillsaColor.gray300 : FillsaColor.gray700)
                        .padding(10)
                }
                .aspectRatio(320 / 458, contentMode: .fit)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    MemoSection(memo: "", onClick: {})
        .padding()
        .background(FillsaColor.background)
}
