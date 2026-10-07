import Foundation
import UIKit

enum HomeUploadImagePreparer {
    // The QA contract says 2MB without defining the byte unit. Use the smaller decimal limit.
    static let maximumBytes = 2_000_000

    static func prepare(_ source: Data) -> Data? {
        guard let decoded = UIImage(data: source) else { return nil }
        let pixelSize = CGSize(
            width: decoded.size.width * decoded.scale,
            height: decoded.size.height * decoded.scale
        )
        guard pixelSize.width > 0, pixelSize.height > 0 else { return nil }

        // Drawing the decoded image applies its EXIF orientation before JPEG encoding.
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        var image = UIGraphicsImageRenderer(size: pixelSize, format: format).image { _ in
            decoded.draw(in: CGRect(origin: .zero, size: pixelSize))
        }

        for _ in 0..<8 {
            for quality in [0.85, 0.65, 0.45, 0.25] as [CGFloat] {
                if let jpeg = image.jpegData(compressionQuality: quality),
                   jpeg.count <= maximumBytes {
                    return jpeg
                }
            }

            let nextSize = CGSize(width: image.size.width * 0.75, height: image.size.height * 0.75)
            guard nextSize.width >= 1, nextSize.height >= 1 else { return nil }
            image = UIGraphicsImageRenderer(size: nextSize, format: format).image { _ in
                image.draw(in: CGRect(origin: .zero, size: nextSize))
            }
        }
        return nil
    }
}
