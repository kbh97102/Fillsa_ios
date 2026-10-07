# Home image upload size QA

## Reference

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/2.home?node-id=3223-5107
- Target nodes: image flow `3223:5107`, image view dialog `3223:4773`
- Full-frame reference image: `docs/design-qa/assets/home-figma-2929-17193/2026-09-07/` (existing Home image flow export)
- Runtime target/capture: none for this branch; no presentation layout, text, asset, or interaction changed
- Byte contract evidence: [QA source](https://app.notion.com/p/3f2e639fc7a480a1a53bdfbd47c4fe5e) states “최대 이미지 크기: 2MB → api 호출전 압축필요”; `APIClient.uploadImage` sends `image/jpeg`. The server boundary and accepted formats are not specified. This branch assumes JPEG at no more than 2,000,000 bytes.

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Home image selection | `3223:5107` | selected photo | No presentation change; functional tests only |
| Image view dialog | `3223:4773` | uploaded image | No presentation change; runtime server round trip unverified |

## Validation

- Root cause: raw PhotosPicker bytes were written with `.jpg` extension and sent as `image/jpeg`, regardless of source format or size.
- Regression test: oversized PNG becomes a decodable JPEG within 2,000,000 bytes; invalid image data cannot produce an upload payload.
- Test evidence: `xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,id=CE56066E-B7A3-4A0D-8249-0095E5227289' -derivedDataPath /tmp/fiilsa-qa-image-size-derived -only-testing:FiilsaTests CODE_SIGNING_ALLOWED=NO` succeeded on iPhone 17e, iOS 26.5 (76 passed cases, 0 failed). The focused `HomeUploadImagePreparerTests` run also succeeded. The test was first observed failing to compile because `HomeUploadImagePreparer` did not exist.
- Temporary upload file is removed after success, failure, or cancellation of the upload effect.
- No live authenticated upload or Figma full-frame comparison was run in this branch. Server acceptance and the assembled Home result remain **Blocked** pending integration runtime evidence.

## Final assembled-screen result

- Full-frame reference/capture comparison: unavailable for this data-only change
- Final runtime capture: none
- Result: Blocked for end-to-end server and assembled-screen validation
- Remaining differences: unknown until authenticated upload on target device
