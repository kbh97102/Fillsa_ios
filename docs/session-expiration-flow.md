# 전역 토큰 만료/에러 처리 흐름

## Android 기준

Android는 `AuthAuthenticator`가 인증 API의 `401` 응답을 받으면 refresh token으로 access token을 갱신한 뒤 원 요청을 다시 보낸다.

- `responseCount(response) >= 2`이면 더 이상 재시도하지 않는다.
- refresh token이 없거나 갱신에 실패하면 원 요청은 실패한다.
- 최종 `401`/`403`은 `WithBaseErrorHandling`에서 공통으로 처리한다.
- Android 공통 문구는 `로그인 시간이 만료되었습니다.\n재로그인해주세요`이고, 확인 시 `logoutEvent()`가 실행된다.

## iOS 구현 구조

iOS는 Alamofire `RequestInterceptor`와 TCA 루트 `AppFeature`를 연결해서 같은 흐름을 만든다.

```text
API request
-> FillsaRequestInterceptor
-> 401/403
-> refresh token request
-> success: token update + original request retry
-> failure: SessionExpirationEvent emit
-> AppFeature receives event
-> SessionClient.logout()
-> Home/MyPage/List/Calendar state reset
-> member UI becomes guest UI
```

## 코드 흐름

### 1. 인증 헤더 추가

`FillsaRequestInterceptor.adapt`는 요청마다 Keychain의 access token을 읽고 `Authorization: Bearer ...` 헤더를 붙인다.

단, `APIRequest.requiresAuthorization == false`인 요청은 `X-Fillsa-Authorization: none` 임시 헤더가 들어가고, 인터셉터가 이 헤더를 제거한 뒤 토큰 없이 보낸다. 로그인/refresh API가 여기에 해당한다.

### 2. 401/403 refresh retry

`FillsaRequestInterceptor.retry`는 응답 status code가 `401` 또는 `403`이고 `request.retryCount == 0`일 때만 refresh token 갱신을 시도한다.

- refresh 성공: 새 access token과 refresh token을 저장하고 원 요청을 한 번 재시도한다.
- refresh token 없음: `SessionExpirationEvent(reason: .missingRefreshToken)` 발행
- refresh 실패: `SessionExpirationEvent(reason: .refreshFailed)` 발행
- 재시도 후 다시 401/403: `SessionExpirationEvent(reason: .retryRejected)` 발행

이 구조가 무한 retry를 막는다. Android의 `responseCount(response) >= 2`와 같은 목적이다.

### 3. 세션 만료 이벤트 전달

Data 계층은 TCA를 직접 알지 않는다. 그래서 `SessionExpirationEventCenter`가 `NotificationCenter`로 세션 만료 이벤트를 발행한다.

`SessionExpirationClient`는 이 notification을 `AsyncStream<SessionExpirationEvent>`로 감싸서 TCA dependency로 제공한다.

Android 비교:

- Android `DataStore TOKEN_EXPIRED` 또는 ViewModel error flow에 가깝다.
- iOS에서는 루트 reducer가 계속 관찰할 수 있도록 `AsyncStream`으로 바꿨다.

### 4. AppFeature 처리

`AppView`는 앱 루트가 나타날 때 `.task` action을 한 번 보낸다.

`AppFeature.task`는 `sessionExpirationClient.events()`를 구독한다. 이벤트가 오면 `.sessionExpired(event)` action을 다시 보낸다.

`AppFeature.sessionExpired`는 중복 처리를 막기 위해 `isHandlingSessionExpiration`이 `false`일 때만 동작한다.

처리 순서:

1. `SessionClient.logout()` 호출
2. access token / refresh token 삭제
3. 화면을 `main`으로 이동
4. 선택 탭을 `home`으로 변경
5. `HomeFeature`, `QuoteListFeature`, `CalendarFeature`, `MyPageFeature` state 재생성

로그인 상태는 token 존재 여부로 판단하므로, state를 다시 만들면 각 화면이 비회원 기준으로 다시 로드된다.

## 공통 에러 정책

현재 구현된 범위:

- 인증 만료 계열 `401`/`403`
- refresh token 갱신 실패
- refresh 후에도 실패하는 경우
- 중복 세션 만료 이벤트 방지
- 무한 retry 방지

아직 별도 UI로 구현하지 않은 범위:

- Android `WithBaseErrorHandling`의 전체 에러 코드별 dialog/snackbar 정책
- `1002` 탈퇴 계정 처리
- `1005`, `1006` 일시 오류 dialog
- `1007` 업데이트 dialog
- `1010` 점검 dialog
- `1999` 서버 커스텀 메시지 dialog
- `404` 네트워크 에러 dialog

이 작업은 토큰 만료/세션 정리에 집중했다. 나머지 공통 에러 UI는 별도 작업으로 분리하는 편이 안전하다.
