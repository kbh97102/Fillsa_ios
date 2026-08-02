# FCM 토큰 디버그 로그 설계

## 목표

개발자가 실기기 테스트 중 Xcode 콘솔에서 FCM registration token 전체를 복사할 수 있게 한다.

## 범위

- `MessagingDelegate`의 `didReceiveRegistrationToken` 콜백에서 유효한 토큰을 받으면 전체 값을 로그로 출력한다.
- 로그는 `#if DEBUG` 범위에만 둔다. 배포용 Release 빌드에는 토큰 로그가 포함되지 않는다.
- 토큰 전달 이벤트와 서버 동기화 동작은 변경하지 않는다.

## 선택한 방식

기존 일부 마스킹 로그를 전체 토큰 로그로 교체한다. 별도 로거, 저장소, 화면은 추가하지 않는다. FCM 토큰은 민감한 기기 식별 정보이므로 테스트에 필요한 DEBUG 환경으로만 노출을 제한한다.

## 검증

- Debug 시뮬레이터 빌드가 성공해야 한다.
- 실기기에서 앱 실행 또는 토큰 갱신 뒤 Xcode 콘솔에 `[FCM] registration token: <전체 토큰>` 형식이 출력되어야 한다.
