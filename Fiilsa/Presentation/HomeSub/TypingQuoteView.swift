//
//  TypingQuoteView.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import ComposableArchitecture
import SwiftUI

struct TypingQuoteView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedLocale: HomeLocaleType = .kor

    let store: StoreOf<TypingFeature>
    let isInputEnabled: Bool
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
                        ),
                        isInputEnabled: isInputEnabled
                    )
                    .padding(.top, 20)

                    Spacer()

                    bottomSection(viewStore: viewStore)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FillsaColor.background.ignoresSafeArea())
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
                    .foregroundStyle(FillsaColor.onBackground1)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Spacer()

            HomeLocaleSwitch(selected: $selectedLocale)
        }
        .frame(maxWidth: .infinity)
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
                setIsLike: {
                    viewStore.send(.likeTapped($0))
                }
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
                            .fill(FillsaColor.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(colorScheme == .dark ? FillsaColor.white : FillsaColor.gray700, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
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
        isInputEnabled: true,
        share: { _, _ in }
    )
}
