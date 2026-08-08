//
//  MyPageIcon.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

enum MyPageIconKind {
    case book
    case info
    case bell
    case theme
    case profile
}

struct MyPageIcon: View {
    let kind: MyPageIconKind

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
    }

    private var assetName: String {
        switch kind {
        case .book: "my_page_book"
        case .info: "my_page_info"
        case .bell: "my_page_bell"
        case .theme: "my_page_theme"
        case .profile: "my_page_profile"
        }
    }
}
