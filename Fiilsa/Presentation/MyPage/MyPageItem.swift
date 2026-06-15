//
//  MyPageItem.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct MyPageItem: View {
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
                    .foregroundStyle(FillsaColor.gray700)
                    .padding(.leading, 8)

                Spacer()

                if useArrow {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(FillsaColor.gray700)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(FillsaColor.white)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(FillsaColor.purple02, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MyPageItem(icon: .info, text: "공지사항")
        .padding()
        .background(FillsaColor.background)
}
