//
//  Home.swift
//  Fiilsa
//
//  Created by 강보훈 on 6/14/26.
//

import Foundation
import ComposableArchitecture
import PhotosUI
import SwiftUI


struct HomeView: View {
    @State private var selectedLocale: HomeLocaleType = .kor
    @State private var selectedPhotoItem: PhotosPickerItem?

    let store: StoreOf<HomeFeature>
    let date: Date
    let openTyping: () -> Void
    let openShare: (String, String) -> Void
    let openLogin: () -> Void

    @Environment(\.openURL) private var openURL

    init(
        store: StoreOf<HomeFeature> = Store(initialState: HomeFeature.State()) {
            HomeFeature()
        },
        date: Date = Date(),
        openTyping: @escaping () -> Void = {},
        openShare: @escaping (String, String) -> Void = { _, _ in },
        openLogin: @escaping () -> Void = {}
    ) {
        self.store = store
        self.date = date
        self.openTyping = openTyping
        self.openShare = openShare
        self.openLogin = openLogin
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                VStack(spacing: 0) {
                    HomeTopBar()

                    HStack(alignment: .center, spacing: 20) {
                        DateSection(date: date)

                        HomeImageSection(
                            imageUri: viewStore.quote.imagePath ?? "",
                            isLogged: viewStore.isLoggedIn,
                            onClick: {
                                viewStore.send(.imageTapped)
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
                        date: viewStore.date,
                        next: {
                            viewStore.send(.nextTapped)
                        },
                        before: {
                            viewStore.send(.beforeTapped)
                        },
                        navigate: openTyping,
                        authorTapped: {
                            if let urlString = viewStore.quote.authorUrl,
                               let url = URL(string: urlString) {
                                openURL(url)
                            }
                        }
                    )
                    .padding(.top, 20)
                    .padding(.horizontal, 20)

                    HomeInteractionButtonSection(
                        copy: {
                            UIPasteboard.general.string = copyText(from: viewStore.quote)
                            viewStore.send(.copyCompleted)
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

                if viewStore.isImageDialogPresented {
                    HomeImageDialog(
                        quote: quote(from: viewStore.quote),
                        author: author(from: viewStore.quote),
                        imagePath: viewStore.quote.imagePath ?? "",
                        dismiss: {
                            viewStore.send(.imageDialogDismissed)
                        },
                        delete: {
                            viewStore.send(.deleteImageTapped)
                        },
                        selectedPhotoItem: $selectedPhotoItem
                    )
                }

                if let message = viewStore.toastMessage {
                    toast(message)
                        .transition(.opacity)
                        .onAppear {
                            Task {
                                try? await Task.sleep(nanoseconds: 1_600_000_000)
                                await viewStore.send(.toastDismissed).finish()
                            }
                        }
                }
            }
            .alert("로그인 후 사용하실 수 있습니다.", isPresented: Binding(
                get: { viewStore.isLoginRequiredDialogPresented },
                set: { if !$0 { viewStore.send(.loginRequiredDialogDismissed) } }
            )) {
                Button("로그인 하기") {
                    viewStore.send(.loginRequiredDialogDismissed)
                    openLogin()
                }
                Button("취소", role: .cancel) {}
            }
            .alert("이미지를 삭제하시겠습니까?", isPresented: Binding(
                get: { viewStore.isDeleteImageConfirmationPresented },
                set: { if !$0 { viewStore.send(.deleteImageCancelled) } }
            )) {
                Button("삭제하기", role: .destructive) {
                    viewStore.send(.deleteImageConfirmed)
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("삭제 후 이미지를 되돌릴 수 없습니다.")
            }
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else { return }
                Task {
                    guard let fileURL = await makeTemporaryImageFile(from: item) else { return }
                    await viewStore.send(.imagePicked(fileURL)).finish()
                    selectedPhotoItem = nil
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

    private func copyText(from data: DailyQuote) -> String {
        "\(quote(from: data)) - \(author(from: data))"
    }

    private func makeTemporaryImageFile(from item: PhotosPickerItem) async -> URL? {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private func toast(_ message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .font(FillsaTypography.body2)
                .foregroundStyle(FillsaColor.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(FillsaColor.black0C.opacity(0.84))
                )
                .padding(.bottom, 28)
        }
    }
}


#Preview {
    HomeView()
}
