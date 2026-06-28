import ComposableArchitecture
import SwiftUI

struct MyPageView: View {
    let store: StoreOf<MyPageFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                content(viewStore: viewStore)

                if viewStore.isThemeDialogPresented {
                    MyPageThemeDialog(
                        selectedTheme: Binding(
                            get: { viewStore.selectedTheme },
                            set: { viewStore.send(.themeSelected($0)) }
                        ),
                        confirm: {
                            viewStore.send(.themeDialogConfirmed)
                        }
                    )
                }
            }
            .background(FillsaColor.background.ignoresSafeArea())
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }

    private func content(
        viewStore: ViewStore<MyPageFeature.State, MyPageFeature.Action>
    ) -> some View {
        VStack(spacing: 0) {
            Button {
                viewStore.send(.logoTapped)
            } label: {
                Image("icn_top_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 154, height: 70)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)

            MyPageLoginSection(
                isLogged: viewStore.isLoggedIn,
                userName: viewStore.userName,
                imagePath: viewStore.imagePath,
                loginEvent: {
                    viewStore.send(.loginTapped)
                }
            )
            .padding(.top, 10)

            MyPageItem(
                icon: .info,
                text: "공지사항",
                onClick: {
                    viewStore.send(.noticeTapped)
                }
            )
            .padding(.top, 12)

            MyPageItem(
                icon: .bell,
                text: "알림",
                onClick: {
                    viewStore.send(.alertTapped)
                }
            )
            .padding(.top, 12)

            MyPageItem(
                icon: .theme,
                text: "테마",
                onClick: {
                    viewStore.send(.themeTapped)
                }
            )
            .padding(.top, 12)

            MyPageBottomButtonSection(
                isLogged: viewStore.isLoggedIn,
                logout: {
                    viewStore.send(.logoutTapped)
                }
            )
            .padding(.top, 20)

            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    MyPageView(
        store: Store(initialState: MyPageFeature.State()) {
            MyPageFeature()
        }
    )
}
