# [테마] `5-3.theme` (V2)

## Android 기준

- Android는 `FillsaTheme`에서 `FillsaColorScheme`을 light/dark로 분기한다.
- 기본 테마 선택값은 시스템이다.
- 다크 모드의 핵심 색상은 다음과 같다.

| 토큰 | Light | Dark |
|------|-------|------|
| `background` | `primary` (`#FFEFCC`) | `gray_700` (`#212121`) |
| `onBackground1` | `gray_700` (`#212121`) | `white` (`#FFFFFF`) |
| `onBackground2` | `purple01` (`#5C65FF`) | `purple01` (`#5C65FF`) |
| `backgroundContainer` | `white` (`#FFFFFF`) | `gray_600` (`#424242`) |
| `primaryContainer` | `purple01` (`#5C65FF`) | `gray_600` (`#424242`) |
| `onPrimaryContainer` | `white` (`#FFFFFF`) | `white` (`#FFFFFF`) |
| `outline` | `purple01` (`#5C65FF`) | `gray_500` (`#616161`) |
| `outlineVariant` | `gray_200` (`#E0E0E0`) | `gray_200` (`#E0E0E0`) |
| `toastMessageBackground` | `gray_700` (`#212121`) | `gray_500` (`#616161`) |

## 기본값

- 시스템 테마 적용

## 동작

- 마이 페이지 테마 버튼 클릭 시 테마 선택 팝업 노출
- 선택 옵션: 시스템 / 라이트 / 다크
- 확인 버튼 클릭 시 선택 테마 즉시 적용

## iOS 구현 메모

- `DarkModeType` 선택값은 `UserDefaults`에 저장한다.
- `AppView`에서 선택값을 SwiftUI `preferredColorScheme`으로 변환해 앱 전체에 적용한다.
- `FillsaColor`는 Android `FillsaColorScheme`과 같은 의미 토큰을 제공한다.
- `Splash`, `Home`, `QuoteList`, `Calendar`, `MyPage`의 주요 배경/컨테이너/본문 텍스트는 고정 색상 대신 의미 토큰을 사용한다.

## 검증 기준

- 시스템/라이트/다크 선택 시 앱 전체 color scheme이 즉시 바뀐다.
- 다크 모드에서 주요 화면 배경은 `#212121`, 카드/팝업 컨테이너는 `#424242`, 본문 텍스트는 흰색 계열로 표시된다.
- 라이트 모드에서 기존 Android light 디자인과 동일하게 배경 `#FFEFCC`, 주요 컨테이너 흰색을 유지한다.
