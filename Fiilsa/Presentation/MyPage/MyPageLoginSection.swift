//
//  MyPageLoginSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct MyPageLoginSection: View {
    let userName: String
    let imagePath: String

    var body: some View {
        loggedInContent
    }

    private var loggedInContent: some View {
        HStack(spacing: 0) {
            profileImage
                .frame(width: 50, height: 50)
                .clipShape(Circle())

            Text(userName)
                .font(FillsaTypography.subtitle1)
                .foregroundStyle(FillsaColor.onBackground1)
                .lineLimit(1)
                .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .frame(height: MyPageLayout.memberCardHeight)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FillsaColor.backgroundContainer)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(FillsaColor.myPageCardOutline, lineWidth: 1)
        }
        .shadow(color: FillsaColor.myPageShadow, radius: 16, x: 0, y: 0)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(MyPageAccessibilityIdentifier.memberCard)
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
                .scaledToFill()
        }
    }
}

#Preview("Logged in") {
    MyPageLoginSection(userName: "필사", imagePath: "")
        .padding()
        .background(FillsaColor.background)
}
