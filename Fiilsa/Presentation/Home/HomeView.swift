import ComposableArchitecture
import PhotosUI
import SwiftUI

enum HomeToastPresentation: Equatable {
    case standard
    case success

    static func resolve(message: String) -> Self {
        ["답변을 기록했어요.", "복사되었습니다."].contains(message) ? .success : .standard
    }
}

struct HomeView: View {
    @State private var selectedLocale: HomeLocaleType = .kor
    @State private var selectedPhotoItem: PhotosPickerItem?
    let store: StoreOf<HomeFeature>
    let date: Date
    let openTyping: () -> Void
    let openShare: (String, String) -> Void
    let openMyPage: () -> Void
    let openCalendar: () -> Void
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme

    init(store: StoreOf<HomeFeature> = Store(initialState: HomeFeature.State()) { HomeFeature() }, date: Date = Date(), openTyping: @escaping () -> Void = {}, openShare: @escaping (String, String) -> Void = { _, _ in }, openMyPage: @escaping () -> Void = {}, openCalendar: @escaping () -> Void = {}) {
        self.store = store; self.date = date; self.openTyping = openTyping; self.openShare = openShare; self.openMyPage = openMyPage; self.openCalendar = openCalendar
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            imagePickerContent(viewStore: viewStore)
        }
    }

    private func imagePickerContent(viewStore: ViewStore<HomeFeature.State, HomeFeature.Action>) -> some View {
        alertContent(viewStore: viewStore)
            .onChange(of: selectedPhotoItem) {
                guard let item = selectedPhotoItem else { return }
                Task {
                    defer { selectedPhotoItem = nil }
                    guard let fileURL = await makeTemporaryImageFile(from: item) else {
                        await viewStore.send(.imageUploaded(viewStore.quote.dailyQuoteSeq, .failure(.defaultError))).finish()
                        return
                    }
                    await viewStore.send(.imagePicked(fileURL)).finish()
                }
            }
    }

    private func alertContent(viewStore: ViewStore<HomeFeature.State, HomeFeature.Action>) -> some View {
        baseContent(viewStore: viewStore)
            .alert("이미지를 삭제하시겠습니까?", isPresented: Binding(
                get: { viewStore.isDeleteImageConfirmationPresented },
                set: { if !$0 { viewStore.send(.deleteImageCancelled) } }
            )) {
                Button("삭제하기", role: .destructive) { viewStore.send(.deleteImageConfirmed) }
                Button("취소", role: .cancel) {}
            } message: {
                Text("삭제 후 이미지를 되돌릴 수 없습니다.")
            }
    }

    private func baseContent(viewStore: ViewStore<HomeFeature.State, HomeFeature.Action>) -> some View {
        VStack(spacing: 0) {
                HomeHeader(
                    myPage: openMyPage,
                    streakCount: viewStore.streakCount,
                    isStreakStateLoaded: viewStore.isStreakStateLoaded,
                    streakStatus: { viewStore.send(.streakStatusTapped) }
                )
                .padding(.horizontal, 20)
                .frame(height: 50)
                ScrollViewReader { proxy in
                    ScrollView {
                        scrollContent(viewStore: viewStore)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                        DispatchQueue.main.async {
                            proxy.scrollTo("home.answerCard", anchor: .bottom)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.rootBackground.color.ignoresSafeArea())
            .onAppear { viewStore.send(.onAppear) }
            .overlayPreferenceValue(HomeOverlayAnchorPreferenceKey.self) { anchors in
                GeometryReader { proxy in
                    overlayContent(viewStore: viewStore, anchors: anchors, proxy: proxy)
                }
            }
    }

    private func scrollContent(viewStore: ViewStore<HomeFeature.State, HomeFeature.Action>) -> some View {
        VStack(spacing: 0) {
            HomeDateControls(
                date: viewStore.date,
                completedWritingDates: viewStore.completedWritingDates,
                selectCalendar: { viewStore.send(.calendarTriggerTapped) },
                selectDate: { viewStore.send(.calendarDateSelected($0)) }
            )
            .padding(.top, 10)
            .padding(.horizontal, 20)
            HStack {
                Text("아래 글을 필사해주세요.")
                    .font(FillsaTypography.body3)
                    .foregroundStyle(palette.primaryText.color)
                Spacer()
                HomeLocaleSwitch(selected: $selectedLocale)
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)
            HomeQuoteCard(
                text: quote(from: viewStore.quote),
                author: author(from: viewStore.quote),
                date: viewStore.date,
                next: { viewStore.send(.nextTapped) },
                before: { viewStore.send(.beforeTapped) },
                navigate: openTyping,
                authorTapped: {
                    if let urlString = viewStore.quote.authorUrl, let url = URL(string: urlString) {
                        openURL(url)
                    }
                }
            )
            .padding(.top, 4)
            .padding(.horizontal, 20)
            .accessibilityIdentifier("home.quoteCard")
            HomeQuoteActionRow(
                copy: {
                    UIPasteboard.general.string = copyText(from: viewStore.quote)
                    viewStore.send(.copyCompleted)
                },
                share: { openShare(quote(from: viewStore.quote), author(from: viewStore.quote)) },
                isLike: viewStore.quote.likeYn == "Y",
                imagePath: viewStore.quote.imagePath,
                setIsLike: { viewStore.send(.likeTapped($0)) },
                registerImage: { viewStore.send(.imageTapped) }
            )
            .padding(.top, 10)
            .padding(.horizontal, 20)
            Divider()
                .overlay(palette.mainDivider.color.opacity(palette.mainDividerOpacity))
                .padding(.top, 1)
            HomeQuestionAnswerCard(
                answer: Binding(
                    get: { viewStore.answerDraft },
                    set: { viewStore.send(.answerDraftChanged($0)) }
                ),
                question: viewStore.quote.questionKo ?? "누군가의 호의를 한참 뒤에야 받아들인 적 있나요?",
                recordedAnswer: viewStore.recordedAnswer,
                isEditing: viewStore.isEditingAnswer,
                recordAnswer: { viewStore.send(.answerRecordTapped) },
                editAnswer: { viewStore.send(.answerEditTapped) }
            )
            .id("home.answerCard")
            .padding(.top, 17)
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private func overlayContent(
        viewStore: ViewStore<HomeFeature.State, HomeFeature.Action>,
        anchors: [HomeOverlayAnchor: Anchor<CGRect>],
        proxy: GeometryProxy
    ) -> some View {
        ZStack(alignment: .topLeading) {
            if viewStore.isCalendarPresented || viewStore.isStreakTooltipPresented {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if viewStore.isCalendarPresented { viewStore.send(.calendarDismissed) }
                        if viewStore.isStreakTooltipPresented { viewStore.send(.streakTooltipDismissed) }
                    }
            }
            if viewStore.isCalendarPresented, let anchor = anchors[.calendarTrigger] {
                let trigger = proxy[anchor]
                HomeInlineCalendar(
                    displayedMonth: viewStore.calendarDisplayedMonth,
                    selectedDate: viewStore.date,
                    selectDate: { viewStore.send(.calendarDateSelected($0)) },
                    changeMonth: { viewStore.send(.calendarMonthChanged($0)) }
                )
                .position(x: trigger.minX + 124, y: trigger.maxY + 173.5)
            }
            if viewStore.isStreakTooltipPresented, let anchor = anchors[.streakStatus] {
                let trigger = proxy[anchor]
                HomeStreakTooltip(
                    openCalendar: {
                        viewStore.send(.streakTooltipDismissed)
                        openCalendar()
                    }
                )
                .position(x: trigger.midX - 89, y: trigger.maxY + 41)
            }
            if viewStore.isImageDialogPresented {
                HomeImageDialog(
                    quote: quote(from: viewStore.quote),
                    author: author(from: viewStore.quote),
                    imagePath: viewStore.quote.imagePath ?? "",
                    dismiss: { viewStore.send(.imageDialogDismissed) },
                    delete: { viewStore.send(.deleteImageTapped) },
                    selectedPhotoItem: $selectedPhotoItem
                )
            }
            if let message = viewStore.toastMessage {
                QuoteToast(message: message, presentation: .resolve(message: message))
                    .transition(.opacity)
                    .id(message)
                    .task(id: viewStore.toastID) {
                        guard !isQuestionDoneFixture else { return }
                        do {
                            try await Task.sleep(for: .milliseconds(1600))
                            viewStore.send(.toastDismissed)
                        } catch {}
                    }
            }
        }
    }

    private func quote(from data: DailyQuote) -> String { selectedLocale == .kor ? data.korQuote ?? "" : data.engQuote ?? "" }
    private func author(from data: DailyQuote) -> String { selectedLocale == .kor ? data.korAuthor ?? "" : data.engAuthor ?? "" }
    private func copyText(from data: DailyQuote) -> String { "\(quote(from: data)) - \(author(from: data))" }
    private func makeTemporaryImageFile(from item: PhotosPickerItem) async -> URL? {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return nil }
        return await Task.detached(priority: .userInitiated) {
            guard let jpeg = HomeUploadImagePreparer.prepare(data) else { return nil }
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpg")
            do { try jpeg.write(to: url, options: .atomic); return url } catch { return nil }
        }.value
    }
    private var isQuestionDoneFixture: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing-home-question-done")
    }

    private var palette: HomeFigmaPalette {
        .resolve(isDark: colorScheme == .dark)
    }
}
