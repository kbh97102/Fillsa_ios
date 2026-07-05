import SwiftUI
import UIKit

enum FillsaColor {
    static let purple01 = Color(hex: 0x5C65FF)
    static let purple02 = Color(hex: 0xD3D5FF)
    static let yellow01 = Color(hex: 0xFFF7E6)
    static let primary = Color(hex: 0xFFEFCC)
    static let yellow02 = Color(hex: 0xFFCB5C)
    static let green1A = Color(hex: 0x1ACE35)

    static let white = Color(hex: 0xFFFFFF)
    static let black = Color(hex: 0x000000)
    static let black0C = Color(hex: 0x0C0C0C)
    static let gray100 = Color(hex: 0xEEEEEE)
    static let gray200 = Color(hex: 0xE0E0E0)
    static let gray300 = Color(hex: 0xBDBDBD)
    static let gray400 = Color(hex: 0x9E9E9E)
    static let gray500 = Color(hex: 0x616161)
    static let gray600 = Color(hex: 0x424242)
    static let gray700 = Color(hex: 0x212121)

    // Android FillsaColorScheme parity. Use these semantic tokens for UI roles
    // that change between light and dark mode.
    static let background = dynamic(light: primary, dark: gray700)
    static let onBackground1 = dynamic(light: gray700, dark: white)
    static let onBackground2 = purple01
    static let backgroundContainer = dynamic(light: white, dark: gray600)
    static let primaryContainer = dynamic(light: purple01, dark: gray600)
    static let onPrimaryContainer = white
    static let outline = dynamic(light: purple01, dark: gray500)
    static let outlineVariant = gray200
    static let toastMessageBackground = dynamic(light: gray700, dark: gray500)
    static let onToastMessage1 = white
    static let onToastMessage2 = green1A
    static let backgroundDim = gray700.opacity(0.8)
    static let secondaryContainer = purple02
    static let onSecondaryContainer1 = gray700
    static let onSecondaryContainer2 = purple01
    static let tertiaryContainer = white
    static let onTertiaryContainer = purple01
    static let tertiaryOutline1 = purple02
    static let tertiaryOutline2 = purple01
    static let tertiary = yellow02
    static let onTertiary1 = white
    static let onTertiary2 = purple01
    static let myPageCardOutline = dynamic(light: purple02, dark: gray500)
    static let myPageShadow = dynamic(light: Color(hex: 0xCBC0A8).opacity(0.7), dark: Color.clear)

    static let onBackgroundPrimary = onBackground1
    static let onBackgroundAccent = onBackground2

    static func dynamic(light: Color, dark: Color) -> Color {
        Color(
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
            }
        )
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
