# [랜딩 페이지] `0.onboarding`

## 기능

- 앱 최초 다운로드 시 시스템 알림 허용 OS 팝업 노출
- 권한 허용 여부와 별개로 앱 시작 시 APNs 원격 알림 등록을 요청하고, 허용된 기기에서는 FCM 원격 알림을 수신할 준비를 한다.
- Firebase 초기화와 APNs/FCM 토큰 연결은 SwiftUI 앱 생명주기에 연결한 `UIApplicationDelegate`가 담당한다.
