import Foundation
import Testing
import UIKit
@testable import Fiilsa

@Suite("Home upload image preparation")
struct HomeUploadImagePreparerTests {
    @Test
    func pngInputBecomesActualJpegWithinTwoMillionBytes() throws {
        let image = noisyImage(width: 1_600, height: 1_600)
        let png = try #require(image.pngData())
        #expect(png.count > 2_000_000)

        let prepared = try #require(HomeUploadImagePreparer.prepare(png))

        #expect(prepared.count <= 2_000_000)
        #expect(prepared.starts(with: [0xFF, 0xD8]))
        #expect(UIImage(data: prepared)?.size == image.size)
    }

    @Test
    func invalidImageBytesAreRejected() {
        #expect(HomeUploadImagePreparer.prepare(Data("not an image".utf8)) == nil)
    }

    private func noisyImage(width: Int, height: Int) -> UIImage {
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        var seed: UInt32 = 0x1234_5678
        for offset in stride(from: 0, to: bytes.count, by: 4) {
            seed = 1_664_525 &* seed &+ 1_013_904_223
            bytes[offset] = UInt8(truncatingIfNeeded: seed)
            bytes[offset + 1] = UInt8(truncatingIfNeeded: seed >> 8)
            bytes[offset + 2] = UInt8(truncatingIfNeeded: seed >> 16)
            bytes[offset + 3] = 255
        }
        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        let cgImage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                              bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                              provider: provider, decode: nil, shouldInterpolate: true,
                              intent: .defaultIntent)!
        return UIImage(cgImage: cgImage)
    }
}
