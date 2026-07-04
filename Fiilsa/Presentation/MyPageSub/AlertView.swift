import ComposableArchitecture
import SwiftUI

struct AlertView: View {
    let store: StoreOf<AlertFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                VStack(spacing: 0) {
                    HeaderSection(
                        title: "알림",
                        back: {
                            viewStore.send(.backTapped)
                        }
                    )
                    .padding(.horizontal, 20)
                    .background(FillsaColor.background)

                    AlertSwitchSection(
                        selected: Binding(
                            get: { viewStore.isAlarmOn },
                            set: { viewStore.send(.alarmToggled($0)) }
                        ),
                        isEnabled: !viewStore.isProcessing
                    )

                    if viewStore.isLoggedIn {
                        resignButton(viewStore: viewStore)
                            .padding(.top, 50)
                    }

                    Spacer()
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

                if viewStore.isResignDialogPresented {
                    resignDialog(viewStore: viewStore)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FillsaColor.background.ignoresSafeArea())
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }

    private func resignButton(
        viewStore: ViewStore<AlertFeature.State, AlertFeature.Action>
    ) -> some View {
        Button {
            viewStore.send(.resignTapped)
        } label: {
            HStack {
                Text("탈퇴하기")
                    .font(FillsaTypography.body2)
                    .foregroundStyle(FillsaColor.onBackground1)

                Spacer()

                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(FillsaColor.onBackground1)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 19)
            .background(FillsaColor.backgroundContainer)
        }
        .buttonStyle(.plain)
        .disabled(viewStore.isProcessing)
    }

    private func resignDialog(
        viewStore: ViewStore<AlertFeature.State, AlertFeature.Action>
    ) -> some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()
                .onTapGesture {
                    viewStore.send(.resignDialogDismissed)
                }

            VStack(spacing: 0) {
                Text("탈퇴하시겠습니까?")
                    .font(FillsaTypography.heading4)
                    .foregroundStyle(FillsaColor.onBackground1)
                    .padding(.top, 28)

                Text("탈퇴 후에는 작성하신 필사 정보를 되돌릴 수 없습니다.")
                    .font(FillsaTypography.body2)
                    .foregroundStyle(FillsaColor.onBackground1)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .padding(.horizontal, 24)

                HStack(spacing: 0) {
                    Button {
                        viewStore.send(.resignConfirmed)
                    } label: {
                        Text("탈퇴하기")
                            .font(FillsaTypography.subtitle1)
                            .foregroundStyle(FillsaColor.purple01)
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewStore.isProcessing)

                    Rectangle()
                        .fill(FillsaColor.gray200)
                        .frame(width: 1, height: 50)

                    Button {
                        viewStore.send(.resignDialogDismissed)
                    } label: {
                        Text("취소")
                            .font(FillsaTypography.subtitle1)
                            .foregroundStyle(FillsaColor.onBackground1)
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 24)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(FillsaColor.gray200)
                        .frame(height: 1)
                }
            }
            .frame(maxWidth: 312)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(FillsaColor.backgroundContainer)
            )
            .padding(.horizontal, 24)
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
    AlertView(
        store: Store(initialState: AlertFeature.State()) {
            AlertFeature()
        }
    )
}
