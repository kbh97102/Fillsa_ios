//
//  HeaderSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct HeaderSection: View {
    let title: String
    let back: () -> Void

    var body: some View {
        HStack {
            Button(action: back) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(FillsaColor.gray700)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(FillsaTypography.subtitle1)
                .foregroundStyle(FillsaColor.gray700)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.vertical, 9)
    }
}

#Preview {
    HeaderSection(title: "메모", back: {})
        .padding()
        .background(FillsaColor.background)
}
