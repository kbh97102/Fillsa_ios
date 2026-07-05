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
        HStack{

            Image(colorScheme == .dark ? "icn_top_logo_dark" : "icn_top_logo")
            
            Spacer()
            
            Image("icn_my_page")
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    HomeTopBar()
}
