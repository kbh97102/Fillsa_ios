# [마이 페이지] `5.mypage`

## 회원 전용 전환 — 구현 (2026-10-11)

스플래시와 루트 화면 이동에서 회원 세션만 My Page에 접근한다. 비회원 카드·로그인 버튼을 제거했고, 인증 소실·로그아웃·탈퇴 완료는 로그인 화면으로 이동한다. 아래 비회원 설명은 이전 화면 명세의 기록이다. [검증 기록](../design-qa/2026-10-11-member-only-qa.md).

## 공통 (비회원 / 회원)

| 항목 | 동작 |
|------|------|
| 공지사항 버튼 | 공지사항 페이지로 이동 |
| 알림 버튼 | 알림 페이지로 이동 |
| 버전 표시 | 현재 앱 버전 노출 |
| 테마 버튼 (V2) | 테마 팝업 노출 (라이트 / 다크 / 시스템) |

## 레이아웃

- Figma 360pt 캔버스에서 본문 카드의 x=20, width=320은 화면 좌우 20pt 여백을 뜻한다.
- 회원 정보, 로그인, 메뉴 카드는 320pt로 고정하지 않는다. 화면 루트에서 좌우 20pt를 한 번만 적용하고, 카드는 남은 너비를 채운다.
- 테마 선택 팝업처럼 Figma에서 독립된 고정 크기로 정의한 모달만 해당 크기를 유지한다.

## 비회원

- 로그인 버튼 → 로그인 페이지로 이동

## 회원

- 회원 정보 노출: 프로필 사진, 닉네임
- 로그아웃 버튼 → 로컬 세션 정리 후 로그인 화면으로 이동. 로컬 정리 오류가 나도 로그인 화면으로 이동하며, 로그아웃 요청 기록으로 재시작 시 Home 진입을 막는다. [결정 및 수용 조건](1_login.md), [실행 캡처](evidence/2026-10-09-member-logout-login.png).
- 하단 메뉴 순서: `로그아웃` → `버전` → `회원탈퇴`
- `회원탈퇴`는 별도 카드·화살표 없이 50pt 행으로 직접 노출한다. 텍스트는 `#616161`이다.
- Figma 기준: `2929:11031`

### 회원 탈퇴

- `회원탈퇴` 클릭 시 확인 모달을 표시한다.
- Figma 기준: 라이트 `2936:20033`, 다크 `2936:20153`
- 모달은 화면 중앙의 `320×189pt` 카드이며, 라이트는 `#FFFFFF`, 다크는 `#424242` 배경과 `#616161` 외곽선을 사용한다.
- 모달 하단에는 12pt 간격의 `142×49pt` 버튼 두 개를 배치한다. `탈퇴하기`는 보라색 채움·흰 텍스트, `취소`는 흰 배경·보라색 1pt 외곽선·보라색 텍스트다.

> "탈퇴하시겠습니까?"
> "탈퇴 후에는 작성하신 필사 정보를 되돌릴 수 없습니다. 😢"

| 버튼 | 동작 |
|------|------|
| 탈퇴하기 | 계정 삭제 처리 |
| 취소 | 모달 닫기 |

---

## API

### 회원 스트릭 조회

```
GET /api/v1/member-streaks
```

**Response: `MemberStreakResponse`**

### 회원 탈퇴

```
DELETE /api/v1/auth/withdraw
```

**Response: `204 No Content` 또는 빈 본문의 2xx 응답**

- 인증 토큰 필요
- 성공 시 로컬 토큰, 사용자명, 프로필 이미지 정보를 삭제하고 Home으로 이동한다. 탈퇴 API가 성공한 뒤 로컬 정리가 실패해도 이미 삭제된 계정을 실패로 안내하지 않고 Home으로 이동한다.
- 서버가 이미 탈퇴된 사용자에게 `404 / errorCode 1002 / Withdrawal user`를 반환하면, 로컬에 남은 이전 토큰을 정리하고 탈퇴 완료와 동일하게 Home으로 이동한다. 그 밖의 탈퇴 API 오류는 실패 안내를 표시한다.
- 모든 인증 API 인터셉터와 로그인/로그아웃은 앱 전역의 동일한 Keychain 토큰 저장소를 사용한다. 이는 Android의 단일 DataStore를 주입하는 것과 같으며, 로그인·탈퇴 뒤 이전 refresh token이 메모리 캐시에 남지 않게 한다.

### 회원 전용 2차 변경 목표 — 계획, 미구현

- 탈퇴 API 성공과 이미 탈퇴된 계정(`404 / errorCode 1002 / Withdrawal user`)은 로컬 인증 정보 정리 결과와 관계없이 로그인 화면으로 이동한다. 그 밖의 서버 오류는 현재 My Page와 실패 안내를 유지한다.
- 로컬 정리 중 취소나 오류가 발생해도 서버에서 탈퇴가 확정됐다면 회원 화면에 남지 않는다.
- 비회원 My Page 카드와 로그인 버튼은 회원 전용 진입 경로를 닫은 후 제거한다. 회원 카드·로그아웃·버전·탈퇴의 표시와 순서는 유지한다.
- 구현 순서와 검증은 [화면 진입·세션 종료 계획](1_login_member_only_followup_implementation_plan.md), [비회원 코드 정리 계획](1_login_guest_cleanup_implementation_plan.md)을 따른다.

### 버전 업데이트 팝업 확인

```
GET /api/v1/popups/version-update?currentVersion={currentVersion}
```

**Query Parameter**

| 파라미터 | 기본값 | 설명 |
|----------|--------|------|
| currentVersion | `0.0.2` | 현재 앱 버전 |

**Response: `PopupResponse`**

### 일반 팝업 확인

```
GET /api/v1/popups/general
```

**Response: `PopupResponse`**

---

## 전역 팝업 표시 흐름

Android 기준:

- `MainActivityViewModel.getPopupGeneral()`이 일반 팝업과 버전 업데이트 팝업을 조회한다.
- 팝업 표시 우선순위는 `VERSION_UPDATE` → `NOTICE` → `EVENT` 순서다.
- 일반 팝업은 `CheckPopupIsHiddenUseCase`로 hidden 여부를 확인한 뒤 표시한다.
- 버전 업데이트 팝업은 hidden 여부를 확인하지 않고 표시 큐에 넣는다.
- `GeneralDialogs`에서 `VERSION_UPDATE` 또는 이미지가 있는 `NOTICE`/`EVENT`는 이미지 전용 팝업으로 표시한다.
- 이미지가 없는 `NOTICE`/`EVENT`는 제목/내용 팝업으로 표시하고 `오늘 보지 않기`를 제공한다.
- `오늘 보지 않기`는 `AddHiddenPopupUseCase`로 popup seq를 저장한다.
- Android는 `ClearHiddenInfoWorker`를 매일 00:30에 실행해 hidden popup 목록을 비운다.

주의:

- 현재 Android `MainActivity.onCreate()`의 `mainActivityViewModel.getPopupGeneral()` 호출은 주석 처리되어 있다.
- iOS는 Android에 존재하는 ViewModel/Dialog 흐름을 기준으로, main 화면 진입 후 한 번 팝업을 조회하는 방식으로 구현한다.
