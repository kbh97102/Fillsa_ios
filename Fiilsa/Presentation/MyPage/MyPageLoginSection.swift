//
//  MyPageLoginSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct MyPageLoginSection: View {
    let isLogged: Bool
    let userName: String
    let imagePath: String
    let loginEvent: () -> Void

    var body: some View {
        if isLogged {
            loggedInContent
        } else {
            loggedOutContent
        }
    }

    private var loggedInContent: some View {
        HStack(spacing: 0) {
            profileImage
                .frame(width: 50, height: 50)
                .clipShape(Circle())

            Text(userName)
                .font(FillsaTypography.subtitle1)
                .foregroundStyle(FillsaColor.gray700)
                .lineLimit(1)
                .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FillsaColor.white)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(FillsaColor.purple02, lineWidth: 1)
        }
        .shadow(color: Color(hex: 0xCBC0A8).opacity(0.7), radius: 16, x: 0, y: 0)
    }

    private var loggedOutContent: some View {
        Button(action: loginEvent) {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    MyPageIcon(kind: .book)
                        .frame(width: 30, height: 30)

                    Text("로그인 후 사용해 주세요!")
                        .font(FillsaTypography.subtitle1)
                        .foregroundStyle(FillsaColor.gray700)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 12)
                        .fill(FillsaColor.white)
                )

                Text("로그인")
                    .font(FillsaTypography.subtitle1)
                    .foregroundStyle(FillsaColor.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 12, bottomTrailingRadius: 12, topTrailingRadius: 0)
                            .fill(Color(hex: 0x5E67FD))
                    )
            }
            .shadow(color: Color(hex: 0xCBC0A8).opacity(0.7), radius: 16, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var profileImage: some View {
        if let url = URL(string: imagePath), !imagePath.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    MyPageIcon(kind: .profile)
                }
            }
        } else {
            MyPageIcon(kind: .profile)
        }
    }
}

#Preview("Logged out") {
    MyPageLoginSection(isLogged: false, userName: "", imagePath: "", loginEvent: {})
        .padding()
        .background(FillsaColor.background)
}

#Preview("Logged in") {
    MyPageLoginSection(isLogged: true, userName: "필사", imagePath: "", loginEvent: {})
        .padding()
        .background(FillsaColor.background)
}
