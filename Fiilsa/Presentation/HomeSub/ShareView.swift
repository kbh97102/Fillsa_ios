import ComposableArchitecture
import Photos
import SwiftUI

struct ShareView: View {
    let store: StoreOf<ShareFeature>

    @State private var shareImage: UIImage?
    @State private var isShareSheetPresented = false

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                content(viewStore: viewStore)

                if viewStore.isDescriptionVisible {
                    ShareDescriptionOverlay {
                        viewStore.send(.descriptionTapped)
                    }
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
            .background(FillsaColor.background.ignoresSafeArea())
            .onAppear {
                viewStore.send(.onAppear)
            }
            .sheet(isPresented: $isShareSheetPresented, onDismiss: {
                viewStore.send(.shareCompleted)
                shareImage = nil
            }) {
                if let shareImage {
                    ActivityView(activityItems: [shareImage])
                }
            }
        }
    }

    private func content(
        viewStore: ViewStore<ShareFeature.State, ShareFeature.Action>
    ) -> some View {
        VStack(spacing: 0) {
            topSection(viewStore: viewStore)

            Text("배경을 선택해주세요.")
                .font(FillsaTypography.heading4)
                .foregroundStyle(FillsaColor.gray700)

            Text("필사한 문장이 이미지로 저장됩니다.")
                .font(FillsaTypography.body2)
                .foregroundStyle(FillsaColor.gray700)
                .padding(.top, 4)

            TabView(
                selection: Binding(
                    get: { viewStore.selectedPage },
                    set: { viewStore.send(.pageChanged($0)) }
                )
            ) {
                ForEach(ShareBackgroundStyle.allCases) { style in
                    ShareCard(
                        quote: viewStore.quote,
                        author: viewStore.author,
                        style: style
                    )
                    .frame(width: 270, height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .padding(.horizontal, 60)
                    .tag(style.rawValue)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .padding(.vertical, 30)

            bottomSection(viewStore: viewStore)
                .padding(.bottom, 50)
        }
    }

    private func topSection(
        viewStore: ViewStore<ShareFeature.State, ShareFeature.Action>
    ) -> some View {
        HStack {
            Button {
                viewStore.send(.backTapped)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(FillsaColor.gray700)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 9)
    }

    private func bottomSection(
        viewStore: ViewStore<ShareFeature.State, ShareFeature.Action>
    ) -> some View {
        HStack(spacing: 50) {
            shareButton(systemName: "square.and.arrow.down", text: "저장") {
                Task {
                    guard let image = renderCurrentCard(viewStore: viewStore) else {
                        await viewStore.send(.saveCompleted(false)).finish()
                        return
                    }
                    let didSave = await saveImageToPhotoLibrary(image)
                    await viewStore.send(.saveCompleted(didSave)).finish()
                }
            }

            shareButton(systemName: "doc.on.doc", text: "복사") {
                UIPasteboard.general.string = "\(viewStore.quote) - \(viewStore.author)"
                viewStore.send(.copyTapped)
            }

            shareButton(systemName: "message.fill", text: "카카오톡") {
                guard let image = renderCurrentCard(viewStore: viewStore) else { return }
                shareImage = image
                isShareSheetPresented = true
            }
        }
    }

    private func shareButton(
        systemName: String,
        text: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(FillsaColor.white)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: systemName)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(FillsaColor.gray700)
                    }

                Text(text)
                    .font(FillsaTypography.body3)
                    .foregroundStyle(FillsaColor.gray700)
            }
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func renderCurrentCard(
        viewStore: ViewStore<ShareFeature.State, ShareFeature.Action>
    ) -> UIImage? {
        let style = ShareBackgroundStyle(rawValue: viewStore.selectedPage) ?? .background1
        let renderer = ImageRenderer(
            content: ShareCard(
                quote: viewStore.quote,
                author: viewStore.author,
                style: style
            )
            .frame(width: 270, height: 400)
            .clipShape(RoundedRectangle(cornerRadius: 30))
        )
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    private func saveImageToPhotoLibrary(_ image: UIImage) async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        let authorized: Bool

        switch status {
        case .authorized, .limited:
            authorized = true
        case .notDetermined:
            let requested = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            authorized = requested == .authorized || requested == .limited
        case .denied, .restricted:
            authorized = false
        @unknown default:
            authorized = false
        }

        guard authorized else { return false }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, _ in
                continuation.resume(returning: success)
            }
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

private struct ShareCard: View {
    let quote: String
    let author: String
    let style: ShareBackgroundStyle

    var body: some View {
        ZStack {
            style.background

            VStack(spacing: 18) {
                Text(quote)
                    .font(FillsaTypography.body2)
                    .multilineTextAlignment(.center)

                Text(author)
                    .font(FillsaTypography.body2)
            }
            .foregroundStyle(style.textColor)
            .padding(26)
        }
    }
}

private struct ShareDescriptionOverlay: View {
    let dismiss: () -> Void

    var body: some View {
        Button(action: dismiss) {
            VStack(spacing: 20) {
                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(FillsaColor.white)

                Text("좌우로 움직여 이미지를 선택해주세요.")
                    .font(FillsaTypography.subtitle1)
                    .foregroundStyle(FillsaColor.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FillsaColor.gray700.opacity(0.8))
        }
        .buttonStyle(.plain)
        .ignoresSafeArea()
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private enum ShareBackgroundStyle: Int, CaseIterable, Identifiable {
    case background1
    case background2
    case background3
    case background4
    case background5
    case background7
    case background8
    case background10

    var id: Int { rawValue }

    @ViewBuilder
    var background: some View {
        switch self {
        case .background1:
            verticalGradient([
                (0, Color(hex: 0xFEFED6)),
                (0.49, Color(hex: 0xE6B5C1)),
                (1, Color(hex: 0xC990CE))
            ])
        case .background2:
            verticalGradient([
                (0, Color(hex: 0x00A5E4)),
                (0.49, Color(hex: 0x4B6ADC)),
                (1, Color(hex: 0x6848D9))
            ])
        case .background3:
            verticalGradient([
                (0, Color(hex: 0xE4F2DB)),
                (0.44, Color(hex: 0x75CBB0)),
                (1, Color(hex: 0x0BB325))
            ])
        case .background4:
            verticalGradient([
                (0, Color(hex: 0xFFFEFB)),
                (0.44, Color(hex: 0xE6B073)),
                (0.92, Color(hex: 0xEF7800))
            ])
        case .background5:
            verticalGradient([
                (0, Color(hex: 0xFFFFFF)),
                (0.29, Color(hex: 0xFFFFBD)),
                (1, Color(hex: 0x74EAEA))
            ])
        case .background7:
            stripedBackground(base: Color(hex: 0xFFF7E6), lineOpacity: 0.8)
        case .background8:
            stripedBackground(base: Color(hex: 0x212121), lineOpacity: 0.2)
        case .background10:
            verticalGradient([
                (0, Color(hex: 0xE6C3D6)),
                (0.36, Color(hex: 0xF4F5DD)),
                (1, Color(hex: 0x6B77FF))
            ])
        }
    }

    var textColor: Color {
        switch self {
        case .background2, .background8:
            return FillsaColor.white
        default:
            return FillsaColor.gray700
        }
    }

    private func verticalGradient(_ stops: [(Double, Color)]) -> LinearGradient {
        LinearGradient(
            stops: stops.map { Gradient.Stop(color: $0.1, location: $0.0) },
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func stripedBackground(base: Color, lineOpacity: Double) -> some View {
        ZStack {
            base

            ForEach(Array(stride(from: -128.0, through: 528.0, by: 20.5)), id: \.self) { y in
                Rectangle()
                    .fill(Color(hex: 0xD3D5FF).opacity(lineOpacity))
                    .frame(width: 360, height: 0.5)
                    .position(x: 180, y: y)
            }
        }
    }
}

#Preview {
    ShareView(
        store: Store(initialState: ShareFeature.State(
            quote: "상황을 가장 잘 활용하는 사람이 가장 좋은 상황을 맞는다.",
            author: "존 우든"
        )) {
            ShareFeature()
        }
    )
}
