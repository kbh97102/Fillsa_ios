import SwiftUI
import UIKit

/// Figma 3223:4754. The thumbnail always represents the record's uploaded image.
struct QuoteImageActionLabel: View {
    let imagePath: String?

    var body: some View {
        HStack(spacing: 4) {
            if let imagePath, !imagePath.isEmpty {
                thumbnail(imagePath)
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .accessibilityHidden(true)
                Text("이미지 보기")
                    .font(FillsaTypography.body4.bold())
                    .foregroundStyle(FillsaColor.purple01)
            } else {
                Image("home_action_camera")
                    .resizable().scaledToFit()
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)
                Text("이미지 등록")
                    .font(FillsaTypography.body4)
            }
        }
    }

    @ViewBuilder
    private func thumbnail(_ path: String) -> some View {
        if let url = URL(string: path), url.isFileURL,
           let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            AsyncImage(url: URL(string: path)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.clear
            }
        }
    }

}
