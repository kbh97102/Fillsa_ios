//
//  HomeTopBar.swift
//  Fiilsa
//
//  Created by 강보훈 on 6/14/26.
//

import SwiftUI

struct HomeTopBar: View {
    let myPage: () -> Void
    let displayStreak: Bool
    let streakCount: Int?

    @Environment(\.colorScheme) private var colorScheme

    init(
        myPage: @escaping () -> Void = {},
        displayStreak: Bool = false,
        streakCount: Int? = nil
    ) {
        self.myPage = myPage
        self.displayStreak = displayStreak
        self.streakCount = streakCount
    }

    var body: some View {
        HStack {

            Image(colorScheme == .dark ? "icn_top_logo_dark" : "icn_top_logo")
                .resizable()
                .frame(width: 64, height: 30)
            
            Spacer()

            if displayStreak, let streakCount {
                HStack(spacing: 2) {
                    CalendarIcon(kind: .flame)
                        .frame(width: 20, height: 20)

                    Text("\(streakCount)일")
                        .font(FillsaTypography.body1)
                        .foregroundStyle(FillsaColor.onBackground1)
                }
                .accessibilityIdentifier(FillsaAccessibilityIdentifier.calendarStreak)
                .padding(.trailing, 10)
            }
            
            Button(action: myPage) {
                Image("icn_my_page")
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(FillsaColor.onBackground1)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    HomeTopBar()
}
