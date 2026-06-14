//
//  DateComponent.swift
//  Fiilsa
//
//  Created by 강보훈 on 6/14/26.
//

import Foundation
import SwiftUI

struct DateSection: View {
    let date: Date

    private let cardAspectRatio: CGFloat = 155 / 120
    private let cornerRadius: CGFloat = 12

    init(date: Date = Date()) {
        self.date = date
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(yearMonthText)

                Spacer()

                Text(weekdayText)
            }
            .font(FillsaTypography.subtitle2)
            .foregroundStyle(FillsaColor.gray700)
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(FillsaColor.purple02)

            ZStack {
                FillsaColor.white

                Text(dayText)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(FillsaColor.gray700)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 16)
            .padding(.bottom, 18)
            .background(FillsaColor.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(FillsaColor.purple02, lineWidth: 1)
        }
        .aspectRatio(cardAspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }

    private var yearMonthText: String {
        Self.yearMonthFormatter.string(from: date)
    }

    private var dayText: String {
        Self.dayFormatter.string(from: date)
    }

    private var weekdayText: String {
        Self.weekdayFormatter.string(from: date)
    }

    private static let koreanLocale = Locale(identifier: "ko_KR")

    private static let yearMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = koreanLocale
        formatter.dateFormat = "yyyy.MM"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = koreanLocale
        formatter.dateFormat = "d"
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = koreanLocale
        formatter.dateFormat = "EEEE"
        return formatter
    }()
}

#Preview {
    DateSection()
        .padding(24)
        .previewLayout(.sizeThatFits)
}
