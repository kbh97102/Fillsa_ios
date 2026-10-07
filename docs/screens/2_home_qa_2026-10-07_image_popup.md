# 홈 이미지: 팝업 크기가 이미지에 따라 변함

- QA: [Notion 원문](https://app.notion.com/p/3f2e639fc7a480b5a1dbee1dbb7089cd) — 중간, Not started, Device 미지정. 스크린샷 첨부.
- 화면 계획: [Home 이미지 팝업](2_home.md#이미지-팝업-2-2img_checkupload)
- Figma: [이미지 보기 `3223:4773`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/2.home?node-id=3223-4773), 팝업 `3223:4966` (화면 계획의 320:373 비율), 이미지 흐름 `3223:5107`
- 기준 자료: `docs/design-qa/assets/home-figma-2929-17193/2026-09-07/fillsa-home-image-flow.png`; 과거 기본 배경 런타임 캡처 `runtime-ios-image-modal-light.png`
- 판단 범위: 2026-10-07 이미지가 있는 상태를 별도 iPhone 17e iOS 26.4 시뮬레이터에서 재현했다. 가로 640×80 이미지는 팝업 접근성 프레임을 5624×703pt, 세로 80×640 이미지는 350×2800pt로 확대했다. 레이아웃 경계가 없는 `scaledToFill` 이미지가 원인이었다. [수정 및 Figma QA 기록](../design-qa/2026-10-07-home-image-popup-qa.md).

## 코드에서 확인한 점

수정 전 `HomeImageDialog`는 바깥 `ZStack` 안의 팝업에 `.aspectRatio(320/373, contentMode: .fit)`만 적용했다. 이미지 성공 상태의 `AsyncImage.resizable().scaledToFill()`은 별도 프레임과 clipping 없이 자식 크기 계산에 참여해, 넓거나 긴 원본 사진에서 팝업과 버튼 위치를 밀었다. 기본 그라데이션만 검사하는 기존 UI 테스트는 이를 발견하지 못했다. 이제 `GeometryReader`에서 부모 폭 기준 팝업 외곽을 먼저 계산하고, 이미지에 같은 프레임과 clipping을 적용한다.

## 해결 방안

1. 같은 기기·화면 상태에서 기본 배경, 가로 사진, 세로 사진, 극단적 비율 사진의 팝업 `x/y/width/height`를 수집한다. 첨부된 QA 이미지와 Figma 기준 프레임을 함께 대조한다.
2. 이미지별 프레임 변화가 확인되면 팝업 컨테이너의 크기 경계를 부모 폭과 Figma 비율로 먼저 결정하고, 배경 이미지의 `scaledToFill`을 그 경계 안에서만 적용·잘라낸다. 사진 비율은 **내용의 crop**에만 영향을 주도록 한다.
3. Figma에 정의된 팝업 위치, 버튼, 텍스트와 전체 Home 조립 화면을 Light/Dark 및 이미지 상태별로 비교한다. 사진 자체의 crop 정책도 Figma 기준으로 결정한다.

## 검증 기준

- 동일 기기에서 사진 종횡비·해상도를 바꿔도 팝업 외곽 크기와 중심이 일정하다.
- 이미지가 팝업 밖으로 번지지 않고 버튼·문구를 밀지 않는다.
- 기존 비율 테스트에 이미지가 있는 상태를 추가하고, Figma 컴포넌트와 전체 화면 비교 증거를 남긴다.
