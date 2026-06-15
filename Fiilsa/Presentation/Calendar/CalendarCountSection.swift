//
//  CalendarCountSection.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

struct CalendarCountSection: View {
    let likeCount: Int
    let typingCount: Int
    let todayCompleteCount: Int
    let countOnClick: () -> Void

    init(
        likeCount: Int,
        typingCount: Int,
        todayCompleteCount: Int,
        countOnClick: @escaping () -> Void = {}
    ) {
        self.likeCount = likeCount
        self.typingCount = typingCount
        self.todayCompleteCount = todayCompleteCount
        self.countOnClick = countOnClick
    }

    var body: some View {
        HStack {
            Spacer()

            Button(action: countOnClick) {
                HStack(spacing: 0) {
                    CalendarIcon(kind: .note)
                        .frame(width: 16, height: 17)

                    countText(typingCount)
                        .padding(.leading, 4)

                    CalendarIcon(kind: .heart)
                        .frame(width: 16, height: 16)
                        .padding(.leading, 20)

                    countText(likeCount)
                        .padding(.leading, 4)

                    CalendarIcon(kind: .flame)
                        .frame(width: 16, height: 16)
                        .padding(.leading, 20)

                    countText(todayCompleteCount)
                        .padding(.leading, 4)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private func countText(_ count: Int) -> some View {
        Text(count.description)
            .font(FillsaTypography.body3)
            .foregroundStyle(FillsaColor.gray700)
    }
}

#Preview {
    CalendarCountSection(
        likeCount: 5,
        typingCount: 3,
        todayCompleteCount: 2
    )
    .padding()
    .background(FillsaColor.background)
}
