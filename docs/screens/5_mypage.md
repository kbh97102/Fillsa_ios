# [마이 페이지] `5.mypage`

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
- 로그아웃 버튼 → 마이 페이지 리렌더링 (비회원 상태)
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

**Response: `Int`**

- 인증 토큰 필요
- 성공 시 로컬 토큰, 사용자명, 프로필 이미지 정보를 삭제하고 Home으로 이동

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
