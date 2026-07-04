import ComposableArchitecture
import SwiftUI

struct LoginView: View {
    let store: StoreOf<LoginFeature>

    @Environment(\.openURL) private var openURL
    @State private var testClickCount = 0

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
        }
    }

    private func content(
        viewStore: ViewStore<LoginFeature.State, LoginFeature.Action>
    ) -> some View {
        VStack(spacing: 0) {
            if viewStore.isOnboarding {
                topSection(viewStore: viewStore)
            }

            Image("icn_top_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 154, height: 70)
                .padding(.top, 154)
                .onTapGesture {
                    testClickCount += 1
                }

            Text("로그인 후, 나만의 필사를 안전하게 저장할 수 있습니다.")
                .font(FillsaTypography.body2)
                .foregroundStyle(FillsaColor.gray700)
                .padding(.top, 80)

            LoginButton(
                icon: .kakao,
                text: "카카오 계정으로 시작하기",
                backgroundColor: Color(hex: 0xFEE500),
                onClick: {
                    viewStore.send(.kakaoTapped)
                }
            )
            .padding(.top, 12)
            .disabled(viewStore.isProcessing)

            LoginButton(
                icon: .google,
                text: "구글 계정으로 시작하기",
                backgroundColor: Color(hex: 0xF2F2F2),
                onClick: {
                    viewStore.send(.googleTapped)
                }
            )
            .padding(.top, 16)
            .disabled(viewStore.isProcessing)

            if !viewStore.isOnboarding {
                LoginButton(
                    icon: .pencil,
                    text: "비회원으로 시작하기",
                    backgroundColor: FillsaColor.white,
                    onClick: {
                        viewStore.send(.nonMemberTapped)
                    }
                )
                .padding(.top, 16)
            }

            LoginAgreementText(
                openTerms: {
                    openURL(URL(string: "https://home.fillsa.store/7vgjr4m1n5gkk2dwpy86")!)
                },
                openPrivacy: {
                    openURL(URL(string: "https://home.fillsa.store/3p4kj92yn5qwkm57q1x8")!)
                }
            )
            .padding(.top, 12)
            .padding(.bottom, 50)

            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FillsaColor.background.ignoresSafeArea())
    }

    private func topSection(
        viewStore: ViewStore<LoginFeature.State, LoginFeature.Action>
    ) -> some View {
        HStack {
            Spacer()

            Button {
                viewStore.send(.closeTapped)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(FillsaColor.gray700)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 13)
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
        store: Store(initialState: LoginFeature.State(isOnboarding: false)) {
            LoginFeature()
        }
    )
}
