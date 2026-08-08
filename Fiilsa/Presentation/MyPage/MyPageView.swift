import ComposableArchitecture
import SwiftUI

struct MyPageView: View {
    let store: StoreOf<MyPageFeature>

    @Environment(\.colorScheme) private var colorScheme

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
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(MyPageAccessibilityIdentifier.screen)
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
                logoImage
            }
            .buttonStyle(.plain)
            .frame(width: MyPageLayout.logoSize.width, height: MyPageLayout.logoSize.height)
            .frame(maxWidth: .infinity, minHeight: 50)
            .accessibilityIdentifier(MyPageAccessibilityIdentifier.logo)

            MyPageLoginSection(
                isLogged: viewStore.isLoggedIn,
                userName: viewStore.userName,
                imagePath: viewStore.imagePath,
                loginEvent: {
                    viewStore.send(.loginTapped)
                }
            )
            .padding(.top, viewStore.isLoggedIn ? 20 : 10)

            VStack(spacing: MyPageLayout.menuSpacing) {
                MyPageItem(
                    icon: .info,
                    text: "공지사항",
                    onClick: {
                        viewStore.send(.noticeTapped)
                    }
                )
                .accessibilityIdentifier(MyPageAccessibilityIdentifier.noticeMenu)

                MyPageItem(
                    icon: .bell,
                    text: "알림",
                    onClick: {
                        viewStore.send(.alertTapped)
                    }
                )
                .accessibilityIdentifier(MyPageAccessibilityIdentifier.alertMenu)

                MyPageItem(
                    icon: .theme,
                    text: "테마",
                    useArrow: false,
                    onClick: {
                        viewStore.send(.themeTapped)
                    }
                )
                .accessibilityIdentifier(MyPageAccessibilityIdentifier.themeMenu)
            }
            .padding(.top, 20)

            MyPageBottomButtonSection(
                isLogged: viewStore.isLoggedIn,
                logout: {
                    viewStore.send(.logoutTapped)
                }
            )
            .padding(.top, 20)

            Spacer()
        }
        .padding(.horizontal, MyPageLayout.screenHorizontalInset)
    }

    private var logoImage: some View {
        Image(colorScheme == .dark ? "icn_top_logo_dark" : "icn_top_logo")
            .resizable()
            .scaledToFit()
        .frame(width: MyPageLayout.logoSize.width, height: MyPageLayout.logoSize.height)
    }
}

#Preview {
    MyPageView(
        store: Store(initialState: MyPageFeature.State()) {
            MyPageFeature()
        }
    )
}
