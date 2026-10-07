# Home image upload size QA

## Reference

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/2.home?node-id=3223-5107
- Target nodes: image flow `3223:5107`, image view dialog `3223:4773`
- Full-frame reference image: `docs/design-qa/assets/home-figma-2929-17193/2026-09-07/` (existing Home image flow export)
- Runtime target/capture: iPhone 17e iOS 26.5 fixture upload capture, [PNG](assets/home-image-size-2026-10-07/fixture-upload-complete.png) and [5-second H.264 MP4](assets/home-image-size-2026-10-07/fixture-upload-complete.mp4). The video shows the existing image popup after a stubbed upload; byte limits are established by the automated test, not by the video alone.
- Byte contract evidence: [QA source](https://app.notion.com/p/3f2e639fc7a480a1a53bdfbd47c4fe5e) states “최대 이미지 크기: 2MB → api 호출전 압축필요”; `APIClient.uploadImage` sends `image/jpeg`. The server boundary and accepted formats are not specified. This branch assumes JPEG at no more than 2,000,000 bytes.

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Home image selection | `3223:5107` | selected photo | Real `HomeUploadImagePreparer` converts the fixture before `imagePicked`; unit test passes |
| Image view dialog | `3223:4773` | uploaded image | Existing 320:373 composition displays the fixture JPEG through a local preview URL; focused UI test and capture pass |

## Validation

- Root cause: raw PhotosPicker bytes were written with `.jpg` extension and sent as `image/jpeg`, regardless of source format or size.
- Regression test: oversized PNG becomes a decodable JPEG within 2,000,000 bytes; invalid image data cannot produce an upload payload.
- Test evidence: `xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,id=CE56066E-B7A3-4A0D-8249-0095E5227289' -derivedDataPath /tmp/fiilsa-qa-image-size-derived -only-testing:FiilsaTests CODE_SIGNING_ALLOWED=NO` succeeded on iPhone 17e, iOS 26.5 (76 passed cases, 0 failed). The focused `HomeUploadImagePreparerTests` run also succeeded. The test was first observed failing to compile because `HomeUploadImagePreparer` did not exist.
- Temporary upload file is removed after success, failure, or cancellation of the upload effect.
- Follow-up fixture test first failed to compile because `HomeImageSizeFixture` was absent, then passed after implementation. It creates a deterministic PNG over 2,000,000 bytes, sends the real prepared JPEG through the same file URL used by `HomeFeature.imagePicked`, and makes the stub reject any upload over 2,000,000 bytes, invalid JPEG signature, or undecodable image. It verifies the stub's preview copy is byte-identical to the submitted upload. Full `FiilsaTests` suite passed again on iPhone 17e iOS 26.5; focused fixture UI test passed after popup correction.
- The fixture launch argument follows `HomeImageSizeFixture.prepareUpload()` → `HomeFeature.imagePicked` → overridden `postUploadImage` stub → successful reducer state → existing image popup. The source is a generated noisy PNG; the stub does not contact the server. No byte-count UI was added.
- The follow-up `FiilsaTests` run reports 77 passed cases, 0 failed. Two focused `HomeUITests` cases passed: the existing Figma popup aspect ratio and the new oversized-image fixture completion.
- The first local-image runtime capture exposed the popup extending beyond the screen. The existing fixed-frame popup correction from the parallel `8a15592` work was reused, with only local-file image loading added here. A focused UI test confirms the dialog and visible change button are present and on screen. The popup screenshot was visually inspected; its layout matches the existing fixed-frame composition, but strict Figma full-frame acceptance remains blocked by viewport mismatch.
- The final capture is H.264 (`avc1`) in MP4 v2 container, 5.0 seconds. It is fixture evidence of the completed popup state and does not demonstrate a live server round trip.
- No live authenticated upload was run. Server acceptance remains **Blocked** pending integration runtime evidence.

## Final assembled-screen result

- Full-frame reference/capture comparison: fixture screenshot visually inspected against the existing popup target; strict comparison is blocked by the simulator versus Figma viewport mismatch
- Final runtime capture: [fixture PNG](assets/home-image-size-2026-10-07/fixture-upload-complete.png), [fixture H.264 MP4](assets/home-image-size-2026-10-07/fixture-upload-complete.mp4)
- Result: fixture flow passed; live server and strict full-frame Figma acceptance Blocked
- Remaining differences: unknown until authenticated upload on target device
