//
//  HomeLocaleSwitch.swift
//  Fiilsa
//
//  Created by Codex on 6/15/26.
//

import SwiftUI

enum HomeLocaleType {
    case kor
    case eng

    mutating func toggle() {
        self = self == .kor ? .eng : .kor
    }
}

struct HomeLocaleSwitch: View {
    @Binding var selected: HomeLocaleType

    var body: some View {
        Button {
            selected.toggle()
        } label: {
            HStack(spacing: 0) {
                localeItem("한", isSelected: selected == .kor)
                localeItem("A", isSelected: selected == .eng)
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 4)
            .background(Capsule().fill(FillsaColor.purple02))
        }
        .buttonStyle(.plain)
    }

    private func localeItem(_ title: String, isSelected: Bool) -> some View {
        Text(title)
            .font(FillsaTypography.subtitle2)
            .foregroundStyle(FillsaColor.gray700)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background {
                if isSelected {
                    Capsule().fill(FillsaColor.white)
                }
            }
    }
}

#Preview {
    @Previewable @State var selected: HomeLocaleType = .kor

    HomeLocaleSwitch(selected: $selected)
        .padding()
        .previewLayout(.sizeThatFits)
}
