//
//  CalendarIcon.swift
//  Fiilsa
//

import SwiftUI

enum CalendarIconKind {
    case heart
    case flame
}

struct CalendarIcon: View {
    let kind: CalendarIconKind
    let size: Size

    init(kind: CalendarIconKind, size: Size = .regular) {
        self.kind = kind
        self.size = size
    }

    var body: some View {
        Image(assetName)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    enum Size {
        case compact
        case regular

        var assetSuffix: String {
            switch self {
            case .compact: "12"
            case .regular: "16"
            }
        }
    }

    private var assetName: String {
        let iconName: String
        switch kind {
        case .heart: iconName = "heart"
        case .flame: iconName = "flame"
        }
        return "calendar_\(iconName)_\(size.assetSuffix)"
    }
}
