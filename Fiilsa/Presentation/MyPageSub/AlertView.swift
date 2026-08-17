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

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FillsaColor.background.ignoresSafeArea())
            .onAppear {
                viewStore.send(.onAppear)
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

#Preview {
    AlertView(
        store: Store(initialState: AlertFeature.State()) {
            AlertFeature()
        }
    )
}
