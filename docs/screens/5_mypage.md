# [마이 페이지] `5.mypage`

## 공통 (비회원 / 회원)

| 항목 | 동작 |
|------|------|
| 공지사항 버튼 | 공지사항 페이지로 이동 |
| 알림 버튼 | 알림 페이지로 이동 |
| 버전 표시 | 현재 앱 버전 노출 |
| 테마 버튼 (V2) | 테마 팝업 노출 (라이트 / 다크 / 시스템) |

## 비회원

- 로그인 버튼 → 로그인 페이지로 이동

## 회원

- 회원 정보 노출: 프로필 사진, 닉네임
- 로그아웃 버튼 → 마이 페이지 리렌더링 (비회원 상태)

---

## API

### 회원 스트릭 조회

```
GET /api/v1/member-streaks
```

**Response: `MemberStreakResponse`**

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
