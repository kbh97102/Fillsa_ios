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
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 8) {
                LoginIcon(icon: icon)
                    .frame(width: 24, height: 24)

                Text(text)
                    .font(FillsaTypography.subtitle2)
                    .foregroundStyle(Color(hex: 0x1F1F1F))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(.plain)
    }
}

enum LoginButtonIcon {
    case kakao
    case google
    case pencil
}

private struct LoginIcon: View {
    let icon: LoginButtonIcon

    var body: some View {
        switch icon {
        case .kakao:
            Circle()
                .fill(Color(hex: 0x191919))
                .overlay {
                    Text("k")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: 0xFEE500))
                }

        case .google:
            ZStack {
                Circle()
                    .fill(FillsaColor.white)
                Text("G")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: 0x4285F4))
            }

        case .pencil:
            Image(systemName: "pencil")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(FillsaColor.gray700)
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
