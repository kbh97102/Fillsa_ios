//
//  MyPageBottomButtonSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct MyPageBottomButtonSection: View {
    let isLogged: Bool
    let version: String
    let isProcessing: Bool
    let logout: () -> Void
    let resign: () -> Void

    init(
        isLogged: Bool,
        version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
        isProcessing: Bool = false,
        logout: @escaping () -> Void = {},
        resign: @escaping () -> Void = {}
    ) {
        self.isLogged = isLogged
        self.version = version
        self.isProcessing = isProcessing
        self.logout = logout
        self.resign = resign
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLogged {
                Button(action: logout) {
                    HStack {
                        Text("로그아웃")
                            .font(FillsaTypography.subtitle1)
                            .foregroundStyle(FillsaColor.onBackground1)

                        Spacer()

                        Image(MyPageArrowAsset.base)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
                .accessibilityIdentifier(MyPageAccessibilityIdentifier.logout)
            }

            HStack {
                Text("버전")
                    .font(FillsaTypography.subtitle1)
                    .foregroundStyle(FillsaColor.onBackground1)

                Spacer()

                Text(version)
                    .font(FillsaTypography.body2)
                    .foregroundStyle(FillsaColor.onBackground1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .accessibilityIdentifier(MyPageAccessibilityIdentifier.version)

            if isLogged {
                Button(action: resign) {
                    HStack {
                        Text("회원탈퇴")
                            .font(FillsaTypography.body2)
                            .foregroundStyle(FillsaColor.myPageResign)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
                .accessibilityIdentifier(MyPageAccessibilityIdentifier.resign)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }
}

#Preview {
    MyPageBottomButtonSection(isLogged: true, version: "1.0")
        .padding()
        .background(FillsaColor.background)
}
