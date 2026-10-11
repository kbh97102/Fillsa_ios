# iOS QA 5건 작업 결과 · 2026-10-11

## 작업 위치와 기준

- 별도 워크트리: `.worktrees/ios-qa-20261009`, 브랜치 `fix/ios-qa-20261009`, 분기 기준 `22d3270`.
- 원본 체크아웃의 미커밋 변경은 수정하지 않았다. [HTML 사전 계획서](2026-10-09-ios-qa-preplan.html)와 비교 이미지를 워크트리로 복사했다.
- Figma 파일 `VdFocqyqTgevMVCQxwAQ2X`의 대상 노드를 재조회했다. 기존 앱 커넥터는 재인증 오류를 냈지만 프로젝트 Figma MCP 조회는 정상 작동했다. **재인증 링크는 필요하지 않았다.**
- Figma 360pt 기준값은 고정 프레임으로 쓰지 않고, 부모 여백·자식 패딩과 콘텐츠 간격으로 구현했다.

## 항목별 목적·원인·처리

| iOS QA | 목적 | 확인된 원인 | 처리 및 현재 상태 |
|---|---|---|---|
| 마이페이지 테마 팝업 | Figma의 전체 화면 딤과 20pt 바깥/12pt 안쪽 여백 | 배경이 296pt 내부 콘텐츠에만 씌워졌고 `MyPageView` 내부 오버레이가 공통 하단 탭을 덮지 못함 | 카드 패딩 바깥에 배경을 적용하고 오버레이를 `AppView`로 이동. Light/Dark 캡처에서 하단 탭 딤 확인. [QA](2026-10-11-mypage-qa.md). |
| 캘린더 완료·미완료 UI | Figma의 월 카드·선택일 카드·안내·구분선 | 320pt 카드, 36pt 날짜 셀, 일부 높이가 고정되고 미완료 안내 서체/테두리, 완료 구분선이 달랐음 | 7열을 가용 너비로 나누고 세로 패딩으로 높이 구성. Bold 안내, 보라색 미완료 테두리, 테마별 구분선과 한 줄 액션을 적용. [QA](2026-10-11-calendar-qa.md). |
| 캘린더 복사·공유·이미지 | 회원·비회원 완료일 액션의 정상 연결 확인 | 현재 코드에는 세 액션 연결이 이미 존재함. 보고된 실사용 실패 원인은 fixture에서 재현되지 않아 미확정 | 회원/비회원 UI fixture와 테스트 확인. 제품 액션 로직 변경 없음. 클립보드 실제 값과 실서버 계정 흐름은 미검증. [QA](2026-10-11-calendar-qa.md). |
| 홈 명언 글꼴 | Figma `GangwonEduAll_OTF:Bold` 본문 | 미등록 `GangwonEduAll-Light`에 합성 Bold를 사용 | 실제 `GangwonEduAll-OTFBold` 글꼴 파일을 앱 번들에 등록하고 카드에 적용. 이미지가 높이를 결정하지 않도록 배경으로 배치. [QA](2026-10-11-home-qa.md). |
| 홈 한/영 토글 | Figma 노란색 `#FFCB5C`와 12pt 글자 | 보라색 `secondaryContainer`를 사용 | 노란색으로 변경하고 Latin `A`에 Figma Poppins Bold 12pt 파일 등록. 한글은 앱의 Pretendard Bold 12pt 사용. [QA](2026-10-11-home-qa.md). |

## 변경 범위

- 화면 코드: `AppView`, `MyPageThemeDialog`/`MyPageView`, `CalendarMonthSection`/`CalendarDayCell`/`CalendarSelectedQuoteSection`, `HomeQuoteCard`/`HomeLocaleSwitch`.
- 테스트 fixture: 비회원 캘린더 액션과 테마 팝업 직접 캡처 상태. TCA reducer의 제품 액션 계약은 유지했다.
- 리소스: 강원교육 글꼴 Bold OTF, [Google Fonts Poppins Bold](https://github.com/google/fonts/blob/main/ofl/poppins/Poppins-Bold.ttf) TTF 및 [OFL 라이선스](../../Fiilsa/Poppins-OFL.txt), `UIAppFonts` 등록.
- 계획/QA: [Home](../screens/2_home.md), [Calendar](../screens/3_calendar.md), [My Page](../screens/5_mypage.md) 화면 문서와 각 화면 QA 기록을 갱신했다.

## 검증

- iPhone 17e / iOS 26.5 Simulator, 분리된 `/tmp/fiilsa-iosqa-dd` 빌드: `xcodebuild build` 종료 코드 0.
- 대상 `CalendarFeatureTests`, `MyPageLayoutTests`, 캘린더 회원/비회원 액션과 테마 팝업 UI 테스트: **17개 통과, 실패 0개**. 증거: `/tmp/fiilsa-iosqa-dd/Logs/Test/Test-Fiilsa-2026.10.11_14-26-34-+0900.xcresult`.
- 최종 Light/Dark 런타임 PNG 7개와 Figma·런타임 나란히 보기 PNG 6개: [`assets/ios-qa-2026-10-11/`](assets/ios-qa-2026-10-11/). 전체 화면과 컴포넌트 차이는 화면별 QA 기록에 남겼다. [HTML 비교 보고서](2026-10-11-ios-qa-result-report.html)에서 상태별 캡처를 볼 수 있다.
- `git diff --check`: 통과. 기존 Swift 6 actor isolation 및 Preview 경고는 빌드 로그에 남아 있다.

## 남은 판단

- `docs/ui-redesign-workflow.md`의 완료 조건상 세 화면 모두 **Blocked**다. Figma 프레임은 360pt 폭(테마 634pt, 홈 821pt, 캘린더 816/1101pt 높이)이고 가용 시뮬레이터 캡처는 390×844pt다. 동일 크기·데이터의 전체 조립 화면 비교가 없어 `Pass`로 기록하지 않는다.
- Figma의 2025년 3월 달력은 날짜가 활성화되어 있으나 앱의 `startDay/startMonth`는 2025년 6월로 제한한다. 해당 제한을 바꾸면 과거 날짜 선택·월 이동이라는 제품 동작이 달라지므로 이번 여백/시각 수정 범위에서 보존했다. 동일 상태 대조를 위해 이 계약에 대한 결정이 필요하다.
- 캘린더 액션은 fixture에서 탭/화면 이동을 확인했지만, QA에서 보고된 실제 실패를 재현하지 못했다. 실계정·서버 응답과 클립보드 값을 확인한 뒤 원인을 확정해야 한다.
- 영어 선택 및 긴 명언의 최종 캡처는 아직 없다.
- Figma 하단 광고 표시는 이전 화면 계획의 사용자 승인에 따라 앱에서 제외되어 있다. 이번 QA에서 새로 추가하지 않았다.

## iOS 구현 메모

SwiftUI의 `padding`은 Compose의 `Modifier.padding`과 같은 역할이다. 공통 하단 탭을 포함한 화면 전체를 어둡게 하려면 `MyPageView`보다 상위인 `AppView`에 팝업을 두어야 한다. TCA의 테마 선택/확인 액션은 Android MVI의 이벤트처럼 기존 reducer로 전달된다. 대안인 320pt 고정 카드와 36pt 고정 셀은 360pt 기준 화면에서는 맞을 수 있어도 다른 iPhone 너비에서 여백을 깨므로 사용하지 않았다.
