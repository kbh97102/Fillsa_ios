//
//  TypingQuoteView.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import ComposableArchitecture
import SwiftUI

struct TypingQuoteView: View {
    @State private var selectedLocale: HomeLocaleType = .kor

    let store: StoreOf<TypingFeature>
    let share: (String, String) -> Void

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                topSection(viewStore: viewStore)

                VStack(spacing: 0) {
                    TypingQuoteBodySection(
                        quote: quote(from: viewStore),
                        write: Binding(
                            get: {
                                selectedLocale == .kor ? viewStore.korTyping : viewStore.engTyping
                            },
                            set: {
                                if selectedLocale == .kor {
                                    viewStore.send(.korTypingChanged($0))
                                } else {
                                    viewStore.send(.engTypingChanged($0))
                                }
                            }
                        )
                    )
                    .padding(.top, 20)

                    Spacer()

                    bottomSection(viewStore: viewStore)
                }
                .padding(.horizontal, 20)
            }
            .background(FillsaColor.white.ignoresSafeArea())
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }

    private func topSection(viewStore: ViewStore<TypingFeature.State, TypingFeature.Action>) -> some View {
        HStack {
            Button {
                viewStore.send(.saveAndBack)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(FillsaColor.gray700)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Spacer()

            HomeLocaleSwitch(selected: $selectedLocale)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 7)
    }

    private func bottomSection(viewStore: ViewStore<TypingFeature.State, TypingFeature.Action>) -> some View {
        HStack {
            HomeInteractionButtonSection(
                copy: {
                    UIPasteboard.general.string = "\(quote(from: viewStore))\n\(author(from: viewStore))"
                },
                share: {
                    share(quote(from: viewStore), author(from: viewStore))
                },
                isLike: viewStore.likeYn == "Y",
                setIsLike: { _ in }
            )
            .frame(maxWidth: 180)

            Spacer()

            Button {
                viewStore.send(.saveAndBack)
            } label: {
                Text("저장하기")
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
        }
        .padding(.bottom, 24)
    }

    private func quote(from viewStore: ViewStore<TypingFeature.State, TypingFeature.Action>) -> String {
        selectedLocale == .kor ? viewStore.korQuote : viewStore.engQuote
    }

    private func author(from viewStore: ViewStore<TypingFeature.State, TypingFeature.Action>) -> String {
        selectedLocale == .kor ? viewStore.korAuthor : viewStore.engAuthor
    }
}

#Preview {
    TypingQuoteView(
        store: Store(
            initialState: TypingFeature.State(
                dailyQuoteSeq: 1,
                korQuote: "상황을 가장 잘 활용하는 사람이 가장 좋은 상황을 맞는다.",
                engQuote: "Things turn out best for the people who make the best of the way things turn out.",
                korAuthor: "존 우든",
                engAuthor: "John Wooden"
            )
        ) {
            TypingFeature()
        },
        share: { _, _ in }
    )
}
