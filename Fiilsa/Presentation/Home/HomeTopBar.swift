//
//  HomeTopBar.swift
//  Fiilsa
//
//  Created by 강보훈 on 6/14/26.
//

import SwiftUI

struct HomeTopBar: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {

            Image(colorScheme == .dark ? "icn_top_logo_dark" : "icn_top_logo")
                .resizable()
                .frame(width: 64, height: 30)
            
            Spacer()
            
            Image("icn_my_page")
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(FillsaColor.onBackground1)
                .frame(width: 24, height: 24)
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    HomeTopBar()
}
