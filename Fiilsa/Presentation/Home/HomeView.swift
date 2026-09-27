import ComposableArchitecture
import PhotosUI
import SwiftUI

enum HomeToastPresentation: Equatable {
    case standard
    case success

    static func resolve(message: String) -> Self {
        message == "답변을 기록했어요." ? .success : .standard
    }
}

struct HomeView: View {
    @State private var selectedLocale: HomeLocaleType = .kor
    @State private var selectedPhotoItem: PhotosPickerItem?
    let store: StoreOf<HomeFeature>
    let date: Date
    let openTyping: () -> Void
    let openShare: (String, String) -> Void
    let openLogin: () -> Void
    let openMyPage: () -> Void
    let openCalendar: () -> Void
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme

    init(store: StoreOf<HomeFeature> = Store(initialState: HomeFeature.State()) { HomeFeature() }, date: Date = Date(), openTyping: @escaping () -> Void = {}, openShare: @escaping (String, String) -> Void = { _, _ in }, openLogin: @escaping () -> Void = {}, openMyPage: @escaping () -> Void = {}, openCalendar: @escaping () -> Void = {}) {
        self.store = store; self.date = date; self.openTyping = openTyping; self.openShare = openShare; self.openLogin = openLogin; self.openMyPage = openMyPage; self.openCalendar = openCalendar
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
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
                                Text("아래 글을 필사해주세요.").font(FillsaTypography.body3).foregroundStyle(palette.primaryText.color)
                                Spacer()
                                HomeLocaleSwitch(selected: $selectedLocale)
                            }.padding(.top, 16).padding(.horizontal, 20)
                            HomeQuoteCard(text: quote(from: viewStore.quote), author: author(from: viewStore.quote), date: viewStore.date, next: { viewStore.send(.nextTapped) }, before: { viewStore.send(.beforeTapped) }, navigate: openTyping, authorTapped: {
                                if let urlString = viewStore.quote.authorUrl, let url = URL(string: urlString) { openURL(url) }
                            })
                            .padding(.top, 4).padding(.horizontal, 20).accessibilityIdentifier("home.quoteCard")
                            HomeQuoteActionRow(copy: { UIPasteboard.general.string = copyText(from: viewStore.quote); viewStore.send(.copyCompleted) }, share: { openShare(quote(from: viewStore.quote), author(from: viewStore.quote)) }, isLike: viewStore.quote.likeYn == "Y", setIsLike: { viewStore.send(.likeTapped($0)) }, registerImage: { viewStore.send(.imageTapped) })
                                .padding(.top, 10)
                                .padding(.horizontal, 20)
                            Divider().overlay(palette.mainDivider.color.opacity(palette.mainDividerOpacity)).padding(.top, 1)
                            HomeQuestionAnswerCard(
                                answer: Binding(
                                    get: { viewStore.answerDraft },
                                    set: { viewStore.send(.answerDraftChanged($0)) }
                                ),
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
                        .position(
                            x: trigger.midX - 89,
                            y: trigger.maxY + 41
                        )
                    }
                    if viewStore.isImageDialogPresented { HomeImageDialog(quote: quote(from: viewStore.quote), author: author(from: viewStore.quote), imagePath: viewStore.quote.imagePath ?? "", dismiss: { viewStore.send(.imageDialogDismissed) }, delete: { viewStore.send(.deleteImageTapped) }, selectedPhotoItem: $selectedPhotoItem) }
                    if let message = viewStore.toastMessage {
                        toast(message, presentation: .resolve(message: message))
                            .transition(.opacity)
                            .onAppear {
                                guard !isQuestionDoneFixture else { return }
                                Task {
                                    try? await Task.sleep(nanoseconds: 1_600_000_000)
                                    await viewStore.send(.toastDismissed).finish()
                                }
                            }
                    }
                    }
                }
            }
            .alert("로그인 후 사용하실 수 있습니다.", isPresented: Binding(get: { viewStore.isLoginRequiredDialogPresented }, set: { if !$0 { viewStore.send(.loginRequiredDialogDismissed) } })) { Button("로그인 하기") { viewStore.send(.loginRequiredDialogDismissed); openLogin() }; Button("취소", role: .cancel) {} }
            .alert("이미지를 삭제하시겠습니까?", isPresented: Binding(get: { viewStore.isDeleteImageConfirmationPresented }, set: { if !$0 { viewStore.send(.deleteImageCancelled) } })) { Button("삭제하기", role: .destructive) { viewStore.send(.deleteImageConfirmed) }; Button("취소", role: .cancel) {} } message: { Text("삭제 후 이미지를 되돌릴 수 없습니다.") }
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else { return }
                Task { guard let fileURL = await makeTemporaryImageFile(from: item) else { return }; await viewStore.send(.imagePicked(fileURL)).finish(); selectedPhotoItem = nil }
            }
        }
    }

    private func quote(from data: DailyQuote) -> String { selectedLocale == .kor ? data.korQuote ?? "" : data.engQuote ?? "" }
    private func author(from data: DailyQuote) -> String { selectedLocale == .kor ? data.korAuthor ?? "" : data.engAuthor ?? "" }
    private func copyText(from data: DailyQuote) -> String { "\(quote(from: data)) - \(author(from: data))" }
    private func makeTemporaryImageFile(from item: PhotosPickerItem) async -> URL? {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
        do { try data.write(to: url, options: .atomic); return url } catch { return nil }
    }
    private func toast(_ message: String, presentation: HomeToastPresentation) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                if presentation == .success {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(FillsaColor.onToastMessage2)
                }
                Text(message)
                    .font(FillsaTypography.body2)
                    .foregroundStyle(FillsaColor.onToastMessage1)
            }
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(FillsaColor.toastMessageBackground, in: RoundedRectangle(cornerRadius: 8))
            .padding(.bottom, 28)
        }
    }

    private var isQuestionDoneFixture: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing-home-question-done")
    }

    private var palette: HomeFigmaPalette {
        .resolve(isDark: colorScheme == .dark)
    }
}
