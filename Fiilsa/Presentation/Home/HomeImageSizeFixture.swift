import Foundation
import UIKit

/// Runs only for the `-ui-testing-home-image-size-upload` launch argument.
enum HomeImageSizeFixture {
    struct Upload: Sendable {
        let fileURL: URL
        let sourceBytes: Int
        let uploadBytes: Int
    }

    enum FixtureError: Error { case invalidImage }

    static func prepareUpload() throws -> Upload {
        let source = try oversizedPNG()
        guard source.count > HomeUploadImagePreparer.maximumBytes,
              let jpeg = HomeUploadImagePreparer.prepare(source),
              jpeg.count <= HomeUploadImagePreparer.maximumBytes else {
            throw FixtureError.invalidImage
        }
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        try jpeg.write(to: fileURL, options: .atomic)
        return Upload(fileURL: fileURL, sourceBytes: source.count, uploadBytes: jpeg.count)
    }

    static func acceptUpload(fileURL: URL, dailyQuoteSeq: Int) throws -> MemberQuoteImageResponse {
        let data = try Data(contentsOf: fileURL)
        guard dailyQuoteSeq > 0,
              data.count <= HomeUploadImagePreparer.maximumBytes,
              data.starts(with: [0xFF, 0xD8]),
              UIImage(data: data) != nil else {
            throw FixtureError.invalidImage
        }
        let previewURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("home-image-size-preview-\(UUID().uuidString)")
            .appendingPathExtension("jpg")
        try data.write(to: previewURL, options: .atomic)
        return MemberQuoteImageResponse(memberQuoteSeq: dailyQuoteSeq, imagePath: previewURL.absoluteString)
    }

    private static func oversizedPNG() throws -> Data {
        let width = 1_600
        let height = 1_600
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        var seed: UInt32 = 0x1234_5678
        for offset in stride(from: 0, to: bytes.count, by: 4) {
            seed = 1_664_525 &* seed &+ 1_013_904_223
            bytes[offset] = UInt8(truncatingIfNeeded: seed)
            bytes[offset + 1] = UInt8(truncatingIfNeeded: seed >> 8)
            bytes[offset + 2] = UInt8(truncatingIfNeeded: seed >> 16)
            bytes[offset + 3] = 255
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let image = CGImage(width: width, height: height, bitsPerComponent: 8,
                                  bitsPerPixel: 32, bytesPerRow: width * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: true,
                                  intent: .defaultIntent),
              let png = UIImage(cgImage: image).pngData() else {
            throw FixtureError.invalidImage
        }
        return png
    }
}
