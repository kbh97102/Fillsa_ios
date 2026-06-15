//
//  MemoInsertView.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import ComposableArchitecture
import SwiftUI

struct MemoInsertView: View {
    @State private var memo: String

    let store: StoreOf<MemoInsertFeature>

    init(
        store: StoreOf<MemoInsertFeature>
    ) {
        self.store = store
        self._memo = State(initialValue: store.withState { $0.savedMemo })
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    ViewStore(store, observe: { $0 }).send(.saveAndBack(memo))
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
                        ViewStore(store, observe: { $0 }).send(.saveAndBack(memo))
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
    MemoInsertView(
        store: Store(initialState: MemoInsertFeature.State(savedMemo: "", memberQuoteSeq: 1)) {
            MemoInsertFeature()
        }
    )
}
