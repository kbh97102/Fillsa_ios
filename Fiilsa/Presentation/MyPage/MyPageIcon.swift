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
        ZStack {
            switch kind {
            case .book:
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(FillsaColor.purple01)
            case .info:
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(FillsaColor.purple01)
            case .bell:
                Image(systemName: "bell.fill")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(FillsaColor.purple01)
            case .theme:
                Image(systemName: "circle.lefthalf.filled")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(FillsaColor.purple01)
            case .profile:
                Circle()
                    .fill(FillsaColor.purple02)

                Image(systemName: "person.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(FillsaColor.purple01)
            }
        }
    }
}
