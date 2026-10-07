# 홈 이미지: 사진 크기 제한 미적용

- QA: [Notion 원문](https://app.notion.com/p/3f2e639fc7a480a1a53bdfbd47c4fe5e) — 중간, Not started, Device 미지정. 본문에 “최대 이미지 크기: 2MB → api 호출전 압축필요” 명시.
- 화면 계획: [Home 이미지 팝업](2_home.md#이미지-팝업-2-2img_checkupload)
- Figma: [이미지 흐름 `3223:5107`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/2.home?node-id=3223-5107), 이미지 팝업 `3223:4773`
- 판단 범위: iOS 업로드 전 크기 검사·압축 부재는 코드로 확인. 실제 서버의 2MB 경계 응답은 미측정.
- 구현 계약 가정: QA 원문은 `2MB`라고만 하며 2,000,000/2,097,152바이트 경계와 허용 포맷을 정의하지 않는다. 기존 iOS multipart 계약이 `image/jpeg`이므로 JPEG로 변환하고 더 엄격한 2,000,000바이트 이하를 적용한다. 서버 실측 또는 명세가 나오면 경계와 포맷을 재확인한다.
- 검증 기록: [Home image size QA](../design-qa/2026-10-07-ios-home-image-size-qa.md)

## 원인

`PhotosPickerItem.loadTransferable(type: Data.self)`로 가져온 원본 바이트를 그대로 임시 파일에 쓴다 (`Fiilsa/Presentation/Home/HomeView.swift:153-157`). 파일 확장자를 무조건 `.jpg`로 붙이지만 변환은 하지 않는다. 이후 `HomeFeature.imagePicked`는 파일 크기 확인 없이 업로드 use case를 호출하고 (`Fiilsa/Presentation/Home/HomeFeature.swift:202-219`), `APIClient.uploadImage`는 파일을 무조건 `image/jpeg`로 전송한다 (`Fiilsa/Data/API/APIClient.swift:54-78`). 원본이 PNG/HEIC이거나 2MB를 넘으면 확장자·MIME과 실제 바이트가 어긋나거나 서버 크기 제한을 넘을 수 있다.

## 해결 방안

1. 서버가 말하는 `2MB`의 정확한 바이트 경계와 허용 포맷을 확인한다. 기존 파일 바이트 수 및 실제 이미지 타입을 먼저 기록해 실패 지점을 재현한다.
2. 사진 선택 후 업로드 전에 이미지를 디코드해 방향을 보정하고, 서버가 허용하는 형식(예: JPEG)으로 인코딩한다. 크기가 제한 이하가 될 때까지 품질과 필요 시 해상도를 조절한다. 결과 바이트와 확장자·MIME을 일치시킨다.
3. 제한을 만족하는 파일만 `postUploadImage`에 전달한다. 만족하지 못하는 경우에는 업로드하지 않고, 오류 표현은 Figma 또는 승인된 문구로 결정한다. 사용 후 임시 파일을 정리한다.

## 검증 기준

- 2MB 전후의 JPEG/PNG/HEIC, 세로·가로 사진을 넣어 실제 전송 바이트가 서버 한도 이내이고 디코딩·방향이 정상인지 확인한다.
- 초과 파일에서 API 요청이 발생하지 않는다. 허용 파일은 업로드·재조회·이미지 보기까지 성공한다.
- 선택 및 결과 팝업의 UI 변경이 있다면 이미지 컴포넌트와 전체 Home 화면을 Figma 기준으로 검증한다.
