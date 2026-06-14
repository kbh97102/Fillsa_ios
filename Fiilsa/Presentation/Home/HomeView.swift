//
//  Home.swift
//  Fiilsa
//
//  Created by 강보훈 on 6/14/26.
//

import SwiftUI


struct HomeView: View {
    var body: some View {
        VStack(spacing: 0) {
            HomeTopBar()

            HStack(alignment: .center, spacing: 20) {
                DateSection()

                HomeImageSection()
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(FillsaColor.background)
    }
}


#Preview {
    HomeView()
}
