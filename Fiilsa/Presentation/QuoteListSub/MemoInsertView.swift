//
//  MemoInsertView.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct MemoInsertView: View {
    @State private var memo: String

    let memberQuoteSeq: Int
    let back: (String) -> Void

    init(
        savedMemo: String,
        memberQuoteSeq: Int,
        back: @escaping (String) -> Void
    ) {
        self._memo = State(initialValue: savedMemo)
        self.memberQuoteSeq = memberQuoteSeq
        self.back = back
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    back(memo)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(FillsaColor.gray700)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.vertical, 9)

            VStack(spacing: 0) {
                TextEditor(text: $memo)
                    .font(FillsaTypography.body1)
                    .foregroundStyle(FillsaColor.gray700)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .overlay(alignment: .topLeading) {
                        if memo.isEmpty {
                            Text("메모를 남겨주세요.")
                                .font(FillsaTypography.body1)
                                .foregroundStyle(FillsaColor.gray300)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                    }

                HStack {
                    Button {
                        back(memo)
                    } label: {
                        Text("나가기")
                            .font(FillsaTypography.body3)
                            .foregroundStyle(FillsaColor.gray700)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(FillsaColor.gray700, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.vertical, 6)
            }
            .padding(.horizontal, 5)
        }
        .padding(.horizontal, 15)
        .background(FillsaColor.white.ignoresSafeArea())
    }
}

#Preview {
    MemoInsertView(savedMemo: "", memberQuoteSeq: 1, back: { _ in })
}
