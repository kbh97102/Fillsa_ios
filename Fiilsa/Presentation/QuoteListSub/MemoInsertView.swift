//
//  MemoInsertView.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import ComposableArchitecture
import SwiftUI

struct MemoInsertView: View {
    @Environment(\.colorScheme) private var colorScheme
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
                    Image(colorScheme == .dark ? "memo_back_dark" : "memo_back")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(180))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("memo.back")
                .frame(width: 62, height: 41)

                Spacer()
            }
            .frame(height: 41)

            TextEditor(text: $memo)
                .font(FillsaTypography.body1)
                .foregroundStyle(FillsaColor.onBackground1)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .accessibilityIdentifier("memo.editor")
                .overlay(alignment: .topLeading) {
                    if memo.isEmpty {
                        Text("메모를 남겨주세요.")
                            .font(FillsaTypography.body1)
                            .foregroundStyle(placeholderColor)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }
                .frame(height: 259)
                .padding(.horizontal, 15)

            HStack {
                Button {
                    ViewStore(store, observe: { $0 }).send(.saveAndBack(memo))
                } label: {
                    Text("나가기")
                        .font(FillsaTypography.body3)
                        .foregroundStyle(FillsaColor.gray700)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(FillsaColor.white, in: RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(FillsaColor.gray700, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("memo.exit")

                Spacer()
            }
            .frame(height: 50)
            .padding(.horizontal, 20)
        }
        .background(memoBackground.ignoresSafeArea())
    }

    private var memoBackground: Color {
        FillsaColor.dynamic(light: FillsaColor.white, dark: FillsaColor.gray700)
    }

    private var placeholderColor: Color {
        FillsaColor.dynamic(light: FillsaColor.gray300, dark: FillsaColor.gray400)
    }
}

#Preview {
    MemoInsertView(
        store: Store(initialState: MemoInsertFeature.State(savedMemo: "", memberQuoteSeq: 1)) {
            MemoInsertFeature()
        }
    )
}
