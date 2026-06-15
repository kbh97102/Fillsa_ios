//
//  LoginView.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct LoginView: View {
    let isOnboarding: Bool
    let close: () -> Void
    let moveHome: () -> Void
    let moveOnboardingGuide: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var testClickCount = 0

    var body: some View {
        VStack(spacing: 0) {
            if isOnboarding {
                topSection
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
                onClick: {}
            )
            .padding(.top, 12)

            LoginButton(
                icon: .google,
                text: "구글 계정으로 시작하기",
                backgroundColor: Color(hex: 0xF2F2F2),
                onClick: {}
            )
            .padding(.top, 16)

            if !isOnboarding {
                LoginButton(
                    icon: .pencil,
                    text: "비회원으로 시작하기",
                    backgroundColor: FillsaColor.white,
                    onClick: moveOnboardingGuide
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

    private var topSection: some View {
        HStack {
            Spacer()

            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(FillsaColor.gray700)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 13)
    }
}

#Preview {
    LoginView(
        isOnboarding: false,
        close: {},
        moveHome: {},
        moveOnboardingGuide: {}
    )
}
