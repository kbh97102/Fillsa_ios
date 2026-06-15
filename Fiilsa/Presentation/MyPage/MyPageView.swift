//
//  MyPageView.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct MyPageView: View {
    @State private var isLogged = false
    @State private var userName = ""
    @State private var imagePath = ""
    @State private var selectedTheme: DarkModeType = .system
    @State private var isThemeDialogPresented = false

    var body: some View {
        ZStack {
            content

            if isThemeDialogPresented {
                MyPageThemeDialog(
                    selectedTheme: $selectedTheme,
                    confirm: {
                        isThemeDialogPresented = false
                    }
                )
            }
        }
        .background(FillsaColor.background.ignoresSafeArea())
    }

    private var content: some View {
        VStack(spacing: 0) {
            Button(action: {}) {
                Image("icn_top_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 154, height: 70)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)

            MyPageLoginSection(
                isLogged: isLogged,
                userName: userName,
                imagePath: imagePath,
                loginEvent: {}
            )
            .padding(.top, 10)

            MyPageItem(icon: .info, text: "공지사항")
                .padding(.top, 12)

            MyPageItem(icon: .bell, text: "알림")
                .padding(.top, 12)

            MyPageItem(
                icon: .theme,
                text: "테마",
                onClick: {
                    isThemeDialogPresented = true
                }
            )
            .padding(.top, 12)

            MyPageBottomButtonSection(
                isLogged: isLogged,
                logout: {
                    isLogged = false
                    userName = ""
                    imagePath = ""
                }
            )
            .padding(.top, 20)

            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    MyPageView()
}
