//
//  CalendarView.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI
import ComposableArchitecture
import Foundation
import PhotosUI
import UIKit

struct CalendarView: View {
    @State private var selectedPhotoItem: PhotosPickerItem?
    let store: StoreOf<CalendarFeature>
    let openMyPage: () -> Void
    let openShare: (String, String) -> Void

    init(
        store: StoreOf<CalendarFeature> = Store(initialState: CalendarFeature.State()) {
            CalendarFeature()
        },
        openMyPage: @escaping () -> Void = {},
        openShare: @escaping (String, String) -> Void = { _, _ in }
    ) {
        self.store = store
        self.openMyPage = openMyPage
        self.openShare = openShare
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                HomeHeader(
                    myPage: openMyPage,
                    streakCount: viewStore.displayStreakCount
                )
                .padding(.horizontal, 20)
                .frame(height: 50)

                ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                    CalendarMonthSection(
                        memberQuotes: viewStore.memberQuotes,
                        currentMonth: Binding(
                            get: { viewStore.currentMonth },
                            set: { viewStore.send(.monthChanged($0)) }
                        ),
                        selectedDay: Binding(
                            get: { viewStore.selectedDay },
                            set: { viewStore.send(.daySelected($0)) }
                        ),
                        changeMonth: {
                            viewStore.send(.monthChanged($0))
                        },
                        selectDay: {
                            viewStore.send(.daySelected($0))
                        }
                    )
                    CalendarCountSection(
                        likeCount: viewStore.monthlySummary.likeCount,
                        writingCount: viewStore.monthlySummary.typingCount,
                        countOnClick: {
                            viewStore.send(.countTapped)
                        }
                    )
                    .padding(.top, 10)

                    let selectedRecord = selectedDayRecord(
                        from: viewStore.memberQuotes,
                        selectedDay: viewStore.selectedDay
                    )
                    CalendarSelectedDaySection(
                        selectedDayRecord: selectedRecord,
                        selectedDay: viewStore.selectedDay,
                        answer: Binding(
                            get: { viewStore.answerDraft },
                            set: { viewStore.send(.answerDraftChanged($0)) }
                        ),
                        recordedAnswer: viewStore.recordedAnswer,
                        isEditingAnswer: viewStore.isEditingAnswer,
                        recordAnswer: { viewStore.send(.answerRecordTapped) },
                        editAnswer: { viewStore.send(.answerEditTapped) },
                        onClick: {
                            viewStore.send(.bottomQuoteTapped)
                        },
                        onCopy: {
                            guard let selectedRecord else { return }
                            UIPasteboard.general.string = "\(selectedRecord.quote) - \(selectedRecord.author)"
                            viewStore.send(.copyCompleted)
                        },
                        onShare: {
                            guard let selectedRecord else { return }
                            openShare(selectedRecord.quote, selectedRecord.author)
                        },
                        onLike: {
                            guard let selectedRecord else { return }
                            viewStore.send(.likeTapped(selectedRecord.dailyQuoteSeq, selectedRecord.likeYn != "Y"))
                        },
                        onImage: {
                            guard let selectedRecord else { return }
                            viewStore.send(.imageTapped(selectedRecord.dailyQuoteSeq))
                        }
                    )
                    .id("calendar.selectedDayAnswer")
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 10)
                .onAppear {
                    if ProcessInfo.processInfo.arguments.contains("ui-testing-calendar-answer-saved") {
                        scrollProxy.scrollTo("calendar.selectedDayAnswer", anchor: .bottom)
                    }
                }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FillsaColor.background.ignoresSafeArea())
            .overlay {
                if viewStore.isImageDialogPresented,
                   let targetSeq = viewStore.imageTargetSeq,
                   let record = viewStore.memberQuotes.first(where: { $0.dailyQuoteSeq == targetSeq }) {
                    HomeImageDialog(
                        quote: record.quote,
                        author: record.author,
                        imagePath: record.imagePath ?? "",
                        dismiss: { viewStore.send(.imageDialogDismissed) },
                        delete: { viewStore.send(.deleteImageTapped) },
                        selectedPhotoItem: $selectedPhotoItem
                    )
                }
            }
            .overlay {
                if let message = viewStore.toastMessage {
                    QuoteToast(message: message, presentation: .success)
                        .task(id: viewStore.toastID) {
                            do {
                                try await Task.sleep(for: .milliseconds(1600))
                                viewStore.send(.toastDismissed)
                            } catch {}
                        }
                }
            }
            .alert("이미지를 삭제하시겠습니까?", isPresented: Binding(
                get: { viewStore.isDeleteImageConfirmationPresented },
                set: { if !$0 { viewStore.send(.deleteImageCancelled) } }
            )) {
                Button("삭제하기", role: .destructive) { viewStore.send(.deleteImageConfirmed) }
                Button("취소", role: .cancel) {}
            } message: {
                Text("삭제 후 이미지를 되돌릴 수 없습니다.")
            }
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else { return }
                Task {
                    defer { selectedPhotoItem = nil }
                    guard let fileURL = await makeTemporaryImageFile(from: item) else {
                        await viewStore.send(.imagePreparationFailed).finish()
                        return
                    }
                    await viewStore.send(.imagePicked(fileURL)).finish()
                }
            }
            .onAppear {
                guard !ProcessInfo.processInfo.arguments.contains("ui-testing-calendar") else { return }
                viewStore.send(.onAppear)
            }
        }
    }

    private func selectedDayRecord(from memberQuotes: [MemberQuotesData], selectedDay: Date) -> MemberQuotesData? {
        let targetDate = FillsaCalendarDateSupport.quoteDateString(for: selectedDay)
        return memberQuotes.first { $0.quoteDate == targetDate }
    }

    private func makeTemporaryImageFile(from item: PhotosPickerItem) async -> URL? {
        guard let source = try? await item.loadTransferable(type: Data.self) else { return nil }
        return await Task.detached(priority: .userInitiated) {
            guard let jpeg = HomeUploadImagePreparer.prepare(source) else { return nil }
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpg")
            do { try jpeg.write(to: url, options: .atomic); return url } catch { return nil }
        }.value
    }
}

#Preview {
    CalendarView()
}
