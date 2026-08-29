//
//  CalendarCountSection.swift
//  Fiilsa
//

import SwiftUI

struct CalendarCountSection: View {
    let likeCount: Int
    let writingCount: Int
    let countOnClick: () -> Void

    init(
        likeCount: Int,
        writingCount: Int,
        countOnClick: @escaping () -> Void = {}
    ) {
        self.likeCount = likeCount
        self.writingCount = writingCount
        self.countOnClick = countOnClick
    }

    var body: some View {
        HStack {
            Spacer()

            Button(action: countOnClick) {
                HStack(spacing: 0) {
                    CalendarIcon(kind: .heart, size: .regular)
                        .frame(width: 16, height: 16)

                    countText(likeCount)
                        .padding(.leading, 4)

                    CalendarIcon(kind: .flame, size: .regular)
                        .frame(width: 16, height: 16)
                        .padding(.leading, 20)

                    countText(writingCount)
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
            .foregroundStyle(FillsaColor.onBackground1)
    }
}

#Preview {
    CalendarCountSection(likeCount: 5, writingCount: 2)
        .padding()
        .background(FillsaColor.background)
}
