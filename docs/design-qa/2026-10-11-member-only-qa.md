# iOS 회원 전용 전환 QA — 2026-10-11

## 기준과 범위

- 대상: 스플래시·로그인·Home·Calendar·List·필사·My Page, 로그아웃·세션 만료·회원 탈퇴.
- Figma URL/노드/비교 이미지: 이번 회원 전용 화면 이동 및 비회원 상태 제거는 사용자가 Figma 없이 진행하도록 명시했다. 따라서 Figma 픽셀 일치 판정은 수행하지 않았다. 기존 회원 화면의 문구와 배치는 유지하고, 변경된 이동·표시 상태를 테스트했다.
- 실행 환경: iPhone 17e Simulator, iOS 26.4.1, 라이트/다크 모드 UI fixture.
- 화면 증거: [회원 로그아웃 후 전체 로그인 화면](evidence/2026-10-11-member-logout-login.png). `MyPageUITests.test_memberLogoutOpensLogin`의 보존된 XCUITest 첨부 이미지다.

## 구성 요소와 동작 결과

| 영역 | 변경 후 상태 | 검증 |
|---|---|---|
| 스플래시 | 첫 실행 여부와 회원 세션을 판정해 목적지 결정 | `SplashFeatureTests`, `AppFeatureTests` |
| 로그인 | 카카오·Apple 로그인만 표시, 닫기·비회원 진입 경로 없음 | `LoginDarkModeUITests`, `OnboardingGuideUITests`, 로그인 캡처 |
| Home·Calendar·List·필사 | 확인된 회원 상태에서만 진입, 회원 API만 조회·저장 | 각 feature/use case 단위 테스트 |
| My Page | 회원 카드만 표시, 인증 소실·로그아웃·탈퇴 후 로그인 | `MyPageFeatureTests`, `MyPageUITests` |
| 이전 비회원 필사 | 로그인 시 읽기·전송·자동 삭제 없음, SQLite 파일·스키마 보존 | `SessionPersistenceTests.test_loginDoesNotUploadOrDeleteLegacyLocalQuotes` |
| 세션 만료 | 현재 토큰 지문과 일치하는 만료만 처리, 이전 세션의 늦은 응답 무시 | `AppFeatureTests` |

## 검증 과정

1. 회원 전용 진입·로그아웃·세션 만료 경로를 단위 테스트로 먼저 고정했다.
2. 비회원 로컬 데이터가 로그인 요청의 `syncData`에 들어가거나 삭제되지 않는지 성공·실패 사례로 확인했다.
3. 로그인과 My Page UI fixture를 실행하고, 로그아웃 뒤 로그인 화면 캡처를 기록했다.
4. 전체 테스트에서 발견한 늦은 스플래시 응답의 Home 재진입을 실패 테스트로 재현한 뒤 차단했다. Home 답변 저장 뒤 키보드와 회원 UI fixture의 인증 상태를 수정해 재검증했다.

## 결과와 제한

- 새 빌드 폴더와 고정된 시뮬레이터로 실행한 변경 관련 검사 **143/143건 통과**: 전체 `FiilsaTests`, 로그인·My Page·온보딩 가이드 UI 전체, Home 답변 키보드·필사 저장 버튼, 전역 로딩, 하단 탭 UI. 결과 번들: `/tmp/fiilsa-member-verification/Logs/Test/Test-Fiilsa-2026.10.11_14-32-17-+0900.xcresult`.
- 최종 앱 빌드: `xcodebuild build -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,id=6C263489-FBEE-4DC7-9904-55D99393D4EC' -derivedDataPath /tmp/fiilsa-member-verification -quiet` 종료 코드 0. 빌드 로그는 `/tmp/fiilsa-member-build-final.log`.
- 앞선 전체 실행은 **183건 중 176건 통과, 7건 실패**였다. 1건은 아래의 기존 Home 툴팁 좌표 사례다. 나머지 6건은 위의 새 빌드 격리 실행에서 모두 통과했다. 전체 실행의 My Page 실패 첨부에는 현재 코드에서 제거된 비회원 카드가 표시됐고, 다크 모드 탭 실패 첨부에는 라이트 모드 화면이 표시됐다. 이는 해당 전체 실행에서 앱 빌드 또는 화면 상태가 섞였다는 근거이며, 실제 변경 코드의 재현 가능한 실패로 판정하지 않았다.
- 새 빌드의 전체 실행은 **183건 중 181건 통과, 2건 실패**였다. 기존 Home 툴팁 이외의 `GlobalLoadingUITests.testSpinnerCoversRoutableScreensExceptSplash`에서 로그인·My Page 로딩 표시의 접근성 좌표가 화면 중심에서 10pt 벗어났다. 녹화 화면에서는 로딩 표시가 중앙에 있어 앱 레이아웃 변경은 되돌렸다. 테스트 시작 방향을 세로로 고정한 뒤 단독 재실행이 통과했다. 사용자의 최신 지시에 따라 전체 재검증은 중단하고 최종 빌드만 확인한다. 따라서 전체 테스트 통과로 판정하지 않는다.
- 이 검증에는 실제 카카오·Apple 계정과 운영 서버의 종단 간 로그인은 포함되지 않는다. 인증·서버 응답 경계는 주입한 테스트 의존성으로 확인했다.
- 이전 비회원 데이터는 기기에 남지만 현재 앱 UI에서는 열거나 서버에 동기화할 수 없다. 앱 삭제 등 운영체제의 데이터 제거는 이 보존 범위 밖이다.
- 기존 독립 이슈: `HomeUITests.testStreakTooltipArrowIsAnchoredToStatusButton`은 2026-10-09 전체 테스트에서 이미 좌표 82pt 대 기대값 90.33pt로 실패했다. 이번 회원 전용 변경과 별개로 결과를 분리한다.

## 최종 화면 판정

- 전체 프레임 런타임 캡처: [로그아웃 후 로그인](evidence/2026-10-11-member-logout-login.png).
- 회원 전용 화면 진입과 비회원 UI 제거: 관련 단위·UI 테스트 143건 통과.
- Figma 비교 라운드: 사용자 지시에 따른 생략.
