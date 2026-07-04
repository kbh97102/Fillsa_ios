import ComposableArchitecture
import SwiftUI

struct GeneralPopupView: View {
    let store: StoreOf<GeneralPopupFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            if let popup = viewStore.currentPopup {
                ZStack {
                    Color.black.opacity(0.32)
                        .ignoresSafeArea()
                        .onTapGesture {
                            viewStore.send(.dismissCurrent)
                        }

                    popupContent(popup, viewStore: viewStore)
                        .padding(.horizontal, 20)
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }

    @ViewBuilder
    private func popupContent(
        _ popup: PopupResponse,
        viewStore: ViewStore<GeneralPopupFeature.State, GeneralPopupFeature.Action>
    ) -> some View {
        if shouldShowImageOnly(popup) {
            imageOnlyDialog(popup, viewStore: viewStore)
        } else {
            noticeDialog(popup, viewStore: viewStore)
        }
    }

    private func imageOnlyDialog(
        _ popup: PopupResponse,
        viewStore: ViewStore<GeneralPopupFeature.State, GeneralPopupFeature.Action>
    ) -> some View {
        VStack(spacing: 0) {
            popupImage(urlString: popup.imageUrl ?? "")

            Divider()
                .background(FillsaColor.outlineVariant)

            HStack {
                Spacer()

                Button("닫기") {
                    viewStore.send(.dismissCurrent)
                }
                .font(FillsaTypography.subtitle2)
                .foregroundStyle(FillsaColor.gray700)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(FillsaColor.white)
        )
    }

    private func noticeDialog(
        _ popup: PopupResponse,
        viewStore: ViewStore<GeneralPopupFeature.State, GeneralPopupFeature.Action>
    ) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Image("icn_top_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 104)
                    .padding(.top, 32)

                Text(popup.title ?? "")
                    .font(FillsaTypography.heading4)
                    .foregroundStyle(FillsaColor.gray700)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .padding(.horizontal, 20)

                Text(popup.content ?? "")
                    .font(FillsaTypography.body2)
                    .foregroundStyle(FillsaColor.gray700)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.horizontal, 20)

                Spacer()
                    .frame(height: 40)
            }
            .frame(maxWidth: .infinity)
            .background(FillsaColor.primary)

            Divider()
                .background(FillsaColor.outlineVariant)

            HStack {
                Button("오늘 보지 않기") {
                    viewStore.send(.dismissToday)
                }
                .font(FillsaTypography.subtitle2)
                .foregroundStyle(FillsaColor.gray700)
                .padding(.vertical, 10)

                Spacer()

                Button("닫기") {
                    viewStore.send(.dismissCurrent)
                }
                .font(FillsaTypography.subtitle2)
                .foregroundStyle(FillsaColor.gray700)
                .padding(.vertical, 10)
            }
            .padding(.horizontal, 20)
            .background(FillsaColor.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func popupImage(urlString: String) -> some View {
        if let url = URL(string: urlString), !urlString.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFit()
                default:
                    Rectangle()
                        .fill(FillsaColor.gray100)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        } else {
            Rectangle()
                .fill(FillsaColor.gray100)
                .aspectRatio(1, contentMode: .fit)
        }
    }

    private func shouldShowImageOnly(_ popup: PopupResponse) -> Bool {
        popup.popupType == "VERSION_UPDATE" || !(popup.imageUrl ?? "").isEmpty
    }
}

#Preview {
    GeneralPopupView(
        store: Store(
            initialState: GeneralPopupFeature.State(
                currentPopup: PopupResponse(
                    popupSeq: 1,
                    popupType: "NOTICE",
                    title: "버전별 신규 기능",
                    content: "버전 업데이트에 대한 내용이 들어갑니다.",
                    imageUrl: nil
                )
            )
        ) {
            GeneralPopupFeature()
        }
    )
}
