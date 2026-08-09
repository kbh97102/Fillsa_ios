//
//  MyPageItem.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct MyPageItem: View {
    @Environment(\.colorScheme) private var colorScheme

    let icon: MyPageIconKind
    let text: String
    let useArrow: Bool
    let onClick: () -> Void

    init(
        icon: MyPageIconKind,
        text: String,
        useArrow: Bool = true,
        onClick: @escaping () -> Void = {}
    ) {
        self.icon = icon
        self.text = text
        self.useArrow = useArrow
        self.onClick = onClick
    }

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 0) {
                MyPageIcon(kind: icon)
                    .frame(width: 20, height: 20)

                Text(text)
                    .font(FillsaTypography.subtitle1)
                    .foregroundStyle(FillsaColor.onBackground1)
                    .padding(.leading, 8)

                Spacer()

                if useArrow {
                    arrowIcon
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: MyPageLayout.menuHeight)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(FillsaColor.backgroundContainer)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(FillsaColor.myPageCardOutline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var arrowIcon: some View {
        ZStack {
            Image(MyPageArrowAsset.base)
                .resizable()
                .scaledToFit()

            if colorScheme == .dark {
                Image(MyPageArrowAsset.darkOverlay)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: 24, height: 24)
        .accessibilityIdentifier(MyPageAccessibilityIdentifier.menuArrow)
    }
}

#Preview {
    MyPageItem(icon: .info, text: "공지사항")
        .padding()
        .background(FillsaColor.background)
}
