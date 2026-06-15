//
//  LoginAgreementText.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct LoginAgreementText: View {
    let openTerms: () -> Void
    let openPrivacy: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("로그인 시, ")
                + Text("이용약관")
                .underline()
                .font(FillsaTypography.subtitle2)
                + Text(" 및 ")
                + Text("개인정보 처리방침")
                .underline()
                .font(FillsaTypography.subtitle2)
                + Text("에 동의하는 것으로 간주됩니다.")
        }
        .font(FillsaTypography.body3)
        .foregroundStyle(FillsaColor.gray700)
        .multilineTextAlignment(.center)
        .overlay {
            HStack(spacing: 0) {
                Button(action: openTerms) {
                    Color.clear
                }
                .buttonStyle(.plain)

                Button(action: openPrivacy) {
                    Color.clear
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    LoginAgreementText(openTerms: {}, openPrivacy: {})
        .padding()
        .background(FillsaColor.background)
}
