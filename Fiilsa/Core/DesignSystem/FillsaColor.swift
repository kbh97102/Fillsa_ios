import SwiftUI

enum FillsaColor {
    static let purple01 = Color(hex: 0x5C65FF)
    static let purple02 = Color(hex: 0xD3D5FF)
    static let primary = Color(hex: 0xFFEFCC)
    static let yellow02 = Color(hex: 0xFFCB5C)
    static let green1A = Color(hex: 0x1ACE35)

    static let white = Color(hex: 0xFFFFFF)
    static let black = Color(hex: 0x000000)
    static let gray100 = Color(hex: 0xEEEEEE)
    static let gray200 = Color(hex: 0xE0E0E0)
    static let gray300 = Color(hex: 0xBDBDBD)
    static let gray400 = Color(hex: 0x9E9E9E)
    static let gray500 = Color(hex: 0x616161)
    static let gray600 = Color(hex: 0x424242)
    static let gray700 = Color(hex: 0x212121)

    static let background = primary
    static let onBackgroundPrimary = gray700
    static let onBackgroundAccent = purple01
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

