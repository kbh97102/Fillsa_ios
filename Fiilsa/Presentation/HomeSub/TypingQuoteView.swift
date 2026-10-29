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
                    TypingPromptSection()
                    ScrollView(.vertical) {
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
                            isInputEnabled: isInputEnabled && !viewStore.isSaving && viewStore.saveResult == nil
                        )
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollDismissesKeyboard(.never)
                    .accessibilityIdentifier("typing.quoteScroll")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 20)

                    bottomSection(viewStore: viewStore)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FillsaColor.dynamic(light: .white, dark: FillsaColor.gray700).ignoresSafeArea())
            .disabled(viewStore.isSaving || viewStore.saveResult != nil)
            .accessibilityHidden(viewStore.saveResult != nil)
            .overlay {
                if let result = viewStore.saveResult {
                    TypingResultPopup(
                        result: result,
                        confirm: { viewStore.send(.resultConfirmed) },
                        cancel: { viewStore.send(.resultCancelled) }
                    )
                    .ignoresSafeArea()
                }
            }
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
                Image("typing_back")
                    .rotationEffect(.degrees(180))
                    .padding(6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로가기")

            Spacer()

            HomeLocaleSwitch(selected: $selectedLocale)
                .accessibilityIdentifier("typing.locale")
        }
        .frame(maxWidth: .infinity)
        .padding(.leading, 9)
        .padding(.trailing, 15)
        .padding(.vertical, 3)
    }

    private func bottomSection(viewStore: ViewStore<TypingFeature.State, TypingFeature.Action>) -> some View {
        HStack {
            HStack(spacing: 40) {
                Button {
                    UIPasteboard.general.string = "\(quote(from: viewStore))\n\(author(from: viewStore))"
                } label: {
                    Image("typing_copy").padding(2.4)
                }
                .accessibilityLabel("복사")

                Button {
                    share(quote(from: viewStore), author(from: viewStore))
                } label: {
                    Image("typing_share")
                        .padding(.leading, 3.5)
                        .padding(.trailing, 4.5)
                        .padding(.vertical, 2.5)
                }
                .accessibilityLabel("공유")

                Button {
                    viewStore.send(.likeTapped(viewStore.likeYn != "Y"))
                } label: {
                    if viewStore.likeYn == "Y" {
                        HeartActionIcon(isFilled: true)
                            .frame(width: 24, height: 24)
                    } else {
                        Image("typing_like")
                    }
                }
                .accessibilityLabel(viewStore.likeYn == "Y" ? "좋아요 취소" : "좋아요")
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                viewStore.send(.saveTapped)
            } label: {
                Text("저장하기")
                    .font(FillsaTypography.body3)
                    .padding(.vertical, max(0, (21 - saveFontLineHeight) / 2))
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
        .padding(.vertical, 6)
    }

    private var saveFontLineHeight: CGFloat {
        UIFont(name: "Pretendard-Regular", size: 14)?.lineHeight ?? 14
    }

    private func quote(from viewStore: ViewStore<TypingFeature.State, TypingFeature.Action>) -> String {
        selectedLocale == .kor ? viewStore.korQuote : viewStore.engQuote
    }

    private func author(from viewStore: ViewStore<TypingFeature.State, TypingFeature.Action>) -> String {
        selectedLocale == .kor ? viewStore.korAuthor : viewStore.engAuthor
    }
}

struct TypingPromptSection: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Image(colorScheme == .dark ? "typing_prompt_dark" : "typing_prompt_light")
                .renderingMode(.original)
                .accessibilityHidden(true)
            Text("오늘의 문장을 따라 써주세요.")
                .font(FillsaTypography.subtitle1)
                .foregroundStyle(FillsaColor.purple01)
                .multilineTextAlignment(.center)
                .padding(.vertical, max(0, (24 - fontLineHeight) / 2))
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("typing.prompt")
    }

    private var fontLineHeight: CGFloat {
        UIFont(name: "Pretendard-Bold", size: 16)?.lineHeight ?? 16
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
