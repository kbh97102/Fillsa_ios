import Foundation
import Testing
import UIKit
@testable import Fiilsa

@Suite("Home image-size upload fixture")
struct HomeImageSizeFixtureTests {
    @Test
    func oversizedSourceReachesUploadStubAsBoundedJpeg() throws {
        let fixture = try HomeImageSizeFixture.prepareUpload()
        defer { try? FileManager.default.removeItem(at: fixture.fileURL) }

        #expect(fixture.sourceBytes > 2_000_000)
        #expect(fixture.uploadBytes <= 2_000_000)
        print("HOME_IMAGE_SIZE_FIXTURE sourceBytes=\(fixture.sourceBytes) uploadBytes=\(fixture.uploadBytes)")
        let submitted = try Data(contentsOf: fixture.fileURL)
        #expect(submitted.count == fixture.uploadBytes)
        #expect(submitted.starts(with: [0xFF, 0xD8]))

        let response = try HomeImageSizeFixture.acceptUpload(fileURL: fixture.fileURL, dailyQuoteSeq: 1)
        let displayedFile = try #require(URL(string: response.imagePath))
        defer { try? FileManager.default.removeItem(at: displayedFile) }
        #expect(response.memberQuoteSeq == 1)
        #expect(try Data(contentsOf: displayedFile) == submitted)
        #expect(UIImage(contentsOfFile: displayedFile.path) != nil)
    }
}
