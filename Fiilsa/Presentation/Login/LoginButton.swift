//
//  LoginButton.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct LoginButton: View {
    let icon: LoginButtonIcon
    let text: String
    let backgroundColor: Color
    var textColor: Color = Color(hex: 0x1F1F1F)
    var isDarkMode = false
    var accessibilityIdentifier = ""
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 8) {
                LoginIcon(icon: icon)
                    .environment(\.colorScheme, isDarkMode ? .dark : .light)
                    .frame(width: 30, height: 30)

                Text(text)
                    .font(FillsaTypography.subtitle2)
                    .foregroundStyle(textColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

enum LoginButtonIcon {
    case kakao
    case apple
    case pencil
}

private struct LoginIcon: View {
    let icon: LoginButtonIcon

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        switch icon {
        case .kakao:
            Image("login_kakao")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 17)

        case .apple:
            Image(colorScheme == .dark ? "login_apple_dark" : "login_apple_light")
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 19)

        case .pencil:
            Image(colorScheme == .dark ? "login_guest_dark" : "login_guest_light")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
        }
    }
}

#Preview {
    LoginButton(
        icon: .kakao,
        text: "카카오 계정으로 시작하기",
        backgroundColor: Color(hex: 0xFEE500),
        onClick: {}
    )
    .padding()
    .background(FillsaColor.background)
}
