# Calendar Post-implementation QA

## 기준과 증빙

- Figma light: `2438:13281` (360×767), dark: `2438:7461` (360×767)
- 실제 앱: Calendar 브랜치 전용 DerivedData 빌드 후 `ui-testing-calendar`, `ui-testing-theme-light|dark` 인자로 캡처
- 캡처: `/tmp/fiilsa-calendar-light-actual.png`, `/tmp/fiilsa-calendar-dark-actual.png`
- 실제 기기는 사용 가능한 iPhone 17 Pro(402pt 폭)였다. Figma의 360pt 기준과 상태바 하드웨어가 다르므로, 기기 크기 자체의 좌표 차이는 별도 이슈로 분리했다.

## 통과

| 항목 | 결과 | 근거 |
|---|---|---|
| 라이트 상단 스트릭 / 하단 탭 숨김 | 통과 | 라이트 캡처에 `🔥 100일`, 탭 바 없음. `CalendarUITests` 통과. |
| 다크 스트릭 숨김 / 하단 탭 노출 | 통과 | 다크 캡처에 스트릭 없음, 탭 바 존재. `CalendarUITests` 통과. |
| 광고 및 광고 UI | 통과 | 양쪽 캡처에 AD badge·광고 문구·고정 광고 슬롯 없음. |
| 월 카드 light/dark 표면·테두리 | 통과 | light `yellow01/yellow02`, dark `gray700/gray600` 표면 및 12pt 라운드가 Figma와 일치. |
| 36×50 날짜 셀과 11pt 열 간격 | 통과 | `CalendarMonthSection`이 36pt 고정 열·11pt 간격·50pt 행을 사용한다. |
| 선택 명언 날짜 색상 | 통과 | light 보라, dark 흰색으로 캡처에서 확인. |
| 세로 구조 | 통과 | 헤더 뒤 20pt 간격으로 월 카드, 카드 뒤 count 15pt, 명언 카드 15pt 순서가 Figma 구조와 일치. |

## 수정 필요

| 우선순위 | 실제 화면 vs Figma | 수정 위치 | 필요한 수정 |
|---|---|---|---|
| P1 | 402pt 폭 실제 기기에서 월 카드는 가용 폭으로 확장된다. Figma 기준은 320×396이다. | `CalendarView.swift`, `CalendarMonthSection.swift` | Figma 절대 기준을 모든 폭에서 유지하려면 월 카드와 명언 카드를 `maxWidth: 320`으로 제한하고 가운데 정렬한다. 현재는 **360pt 폭에서만** 320pt가 된다. |
| P1 | 월 이동 아이콘이 Figma의 shaft가 있는 `iconamoon:arrow`가 아니라 SF Symbol `chevron.right`다. | `CalendarMonthSection.swift` | Figma `2438:13286`/`13289` export asset을 프로젝트 asset으로 추가하고 좌/우 반전으로 사용한다. |
| P1 | 다크 하단 탭의 selected Calendar는 Figma의 흰색 event-note 계열 아이콘/라벨인데, 실제는 보라색 SF Symbol `calendar`와 보라 라벨이다. Home/List/My page 아이콘도 Figma glyph와 다르다. | `FillsaBottomNavigationBar.swift` | Figma 원본 아이콘 assets와 상태별 Figma 색상으로 교체한다. Calendar가 다크에서 탭을 노출하므로 이 차이가 직접 보인다. |
| P1 | 결정론적 QA fixture는 월 요약 `0/0/0`, 선택 명언 본문 빈 문자열, 현재 날짜(2026.08)를 보여 Figma의 선택 날짜·아이콘 조합·명언 본문과 픽셀 비교할 수 없다. | 테스트 전용 `FiilsaApp.swift` fixture | UI QA fixture에 Figma와 같은 2025.03, 선택 21일, 명언·note/heart/flame·count 값을 주입한다. 운영 화면 데이터 로딩 규칙은 변경하지 않는다. |
| P2 | 실제 iPhone 17 Pro의 Dynamic Island 상태바/안전 영역은 Figma의 360pt 구형 status bar와 다르다. 콘텐츠 월 카드 시작 위치는 시각상 동일한 구조이나, status/header의 절대 y 값은 직접 비교 불가다. | 검증 환경 | iPhone 16 Pro(또는 360pt Figma 기준 기기) 스냅샷을 CI/로컬에 설치해 재검증한다. |

## 회귀 테스트

```sh
xcodebuild -project Fiilsa.xcodeproj -scheme Fiilsa \
  -destination 'platform=iOS Simulator,id=89410CC6-A661-4252-B810-0E54DE5FB620' \
  -only-testing:FiilsaTests/CalendarFeatureTests \
  -only-testing:FiilsaUITests/CalendarUITests test
```

결과: `TEST SUCCEEDED` — Calendar unit 2개, UI 2개 통과.
