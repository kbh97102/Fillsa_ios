import SwiftUI

struct PlaceholderScreen: View {
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(FillsaTypography.heading3)
                .foregroundStyle(FillsaColor.onBackgroundPrimary)

            Text("Android parity screen placeholder")
                .font(FillsaTypography.body3)
                .foregroundStyle(FillsaColor.gray500)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FillsaColor.background)
    }
}

