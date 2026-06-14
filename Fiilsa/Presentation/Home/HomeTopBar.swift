//
//  HomeTopBar.swift
//  Fiilsa
//
//  Created by 강보훈 on 6/14/26.
//

import SwiftUI

struct HomeTopBar: View {
    var body: some View {
        HStack{
            
            Image("icn_top_logo")
            
            Spacer()
            
            Image("icn_my_page")
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    HomeTopBar()
}
