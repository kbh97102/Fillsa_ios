import ComposableArchitecture
import SwiftUI

struct LoginView: View {
    let store: StoreOf<LoginFeature>

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                content(viewStore: viewStore)

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
            .alert(
                "카카오톡 설치 후 이용해주세요.",
                isPresented: Binding(
                    get: { viewStore.isKakaoTalkInstallDialogPresented },
                    set: { isPresented in
                        if !isPresented {
                            viewStore.send(.kakaoTalkInstallDialogDismissed)
                        }
                    }
                )
            ) {
                Button("확인", role: .cancel) {}
            }
        }
    }

    private func content(
        viewStore: ViewStore<LoginFeature.State, LoginFeature.Action>
    ) -> some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Image(colorScheme == .dark ? "login_brand_dark" : "login_brand_light")
                        .resizable().scaledToFit()
                        .frame(width: 180, height: 150)
                        .accessibilityLabel("나만의 필사로 채우다, Fillsa")
                        .accessibilityIdentifier(colorScheme == .dark ? "login.logo.dark" : "login.logo.light")
                        .padding(.top, max(0, 162 - proxy.safeAreaInsets.top))

                    Text("로그인 후, 나만의 필사를 안전하게 저장할 수 있습니다.")
                        .font(FillsaTypography.body2)
                        .foregroundStyle(FillsaColor.onBackground1)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .frame(minHeight: 48)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)

                    VStack(spacing: 12) {
                        LoginButton(icon: .apple, text: "애플 계정으로 시작하기",
                                    backgroundColor: colorScheme == .dark ? .white : FillsaColor.gray700,
                                    textColor: colorScheme == .dark ? FillsaColor.gray700 : .white,
                                    isDarkMode: colorScheme == .dark, accessibilityIdentifier: "login.apple") {
                            viewStore.send(.appleTapped)
                        }
                        LoginButton(icon: .kakao, text: "카카오 계정으로 시작하기",
                                    backgroundColor: Color(hex: 0xFFE600), textColor: Color(hex: 0x371D1E),
                                    isDarkMode: colorScheme == .dark, accessibilityIdentifier: "login.kakao") {
                            viewStore.send(.kakaoTapped)
                        }
                        LoginButton(icon: .google, text: "구글 계정으로 시작하기",
                                    backgroundColor: Color(hex: 0xEEEEEF), textColor: FillsaColor.gray700,
                                    isDarkMode: colorScheme == .dark, accessibilityIdentifier: "login.google") {
                            viewStore.send(.googleTapped)
                        }
                    }
                    .disabled(viewStore.isProcessing)
                    .padding(.top, 12)

                    LoginAgreementText()
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(FillsaColor.background.ignoresSafeArea())
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
    LoginView(
        store: Store(initialState: LoginFeature.State()) {
            LoginFeature()
        }
    )
}
