//
//  Home.swift
//  Fiilsa
//
//  Created by 강보훈 on 6/14/26.
//

import Foundation
import ComposableArchitecture
import SwiftUI


struct HomeView: View {
    @State private var selectedLocale: HomeLocaleType = .kor

    let store: StoreOf<HomeFeature>
    let date: Date
    let openTyping: () -> Void
    let openShare: (String, String) -> Void

    @State private var isImageDialogPresented = false

    init(
        store: StoreOf<HomeFeature> = Store(initialState: HomeFeature.State()) {
            HomeFeature()
        },
        date: Date = Date(),
        openTyping: @escaping () -> Void = {},
        openShare: @escaping (String, String) -> Void = { _, _ in }
    ) {
        self.store = store
        self.date = date
        self.openTyping = openTyping
        self.openShare = openShare
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                VStack(spacing: 0) {
                    HomeTopBar()

                    HStack(alignment: .center, spacing: 20) {
                        DateSection(date: date)

                        HomeImageSection(
                            onClick: {
                                isImageDialogPresented = true
                            }
                        )
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)

                    HStack {
                        Spacer()

                        HomeLocaleSwitch(selected: $selectedLocale)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)

                    DailyQuoteSection(
                        text: quote(from: viewStore.quote),
                        author: author(from: viewStore.quote),
                        date: date,
                        navigate: openTyping
                    )
                    .padding(.top, 20)
                    .padding(.horizontal, 20)

                    HomeInteractionButtonSection(
                        copy: {
                            UIPasteboard.general.string = "\(quote(from: viewStore.quote))\n\(author(from: viewStore.quote))"
                        },
                        share: {
                            openShare(quote(from: viewStore.quote), author(from: viewStore.quote))
                        },
                        isLike: viewStore.quote.likeYn == "Y",
                        setIsLike: {
                            viewStore.send(.likeTapped($0))
                        }
                    )
                    .padding(.top, 28)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(FillsaColor.background.ignoresSafeArea())
                .onAppear {
                    viewStore.send(.onAppear)
                }

                if isImageDialogPresented {
                    HomeImageDialog(
                        quote: quote(from: viewStore.quote),
                        author: author(from: viewStore.quote),
                        imagePath: viewStore.quote.imagePath ?? "",
                        dismiss: {
                            isImageDialogPresented = false
                        },
                        delete: {}
                    )
                }
            }
        }
    }

    private func quote(from data: DailyQuote) -> String {
        selectedLocale == .kor ? data.korQuote ?? "" : data.engQuote ?? ""
    }

    private func author(from data: DailyQuote) -> String {
        selectedLocale == .kor ? data.korAuthor ?? "" : data.engAuthor ?? ""
    }
}


#Preview {
    HomeView()
}
