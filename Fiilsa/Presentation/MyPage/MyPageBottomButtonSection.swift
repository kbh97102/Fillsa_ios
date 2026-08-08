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
    let logout: () -> Void

    init(
        isLogged: Bool,
        version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
        logout: @escaping () -> Void = {}
    ) {
        self.isLogged = isLogged
        self.version = version
        self.logout = logout
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("버전")
                    .font(FillsaTypography.subtitle1)
                    .foregroundStyle(FillsaColor.onBackground1)

                Spacer()

                Text(version)
                    .font(FillsaTypography.body2)
                    .foregroundStyle(FillsaColor.onBackground1)
            }
            .frame(height: 50)

            if isLogged {
                Button(action: logout) {
                    Text("로그아웃")
                        .font(FillsaTypography.subtitle1)
                        .foregroundStyle(FillsaColor.onBackground1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .frame(height: 50)
            }
        }
        .padding(.horizontal, 12)
    }
}

#Preview {
    MyPageBottomButtonSection(isLogged: true, version: "1.0")
        .padding()
        .background(FillsaColor.background)
}
