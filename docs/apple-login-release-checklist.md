# Apple 로그인 출시 체크리스트

이 문서는 Apple 로그인 기능을 실제 배포 가능한 상태로 마무리하기 위해 필요한 앱, Apple Developer, 서버, App Store 설정을 정리한다.

## 현재 앱 구현 상태

- 로그인 화면은 Kakao/Apple/비회원 시작 버튼을 제공한다.
- Apple 로그인 버튼은 `LoginFeature.Action.appleTapped`로 연결되어 있다.
- `SocialAuthClient.signInWithApple()`은 `AuthenticationServices`의 `ASAuthorizationAppleIDProvider`를 사용한다.
- Apple 로그인 성공 시 서버 로그인 요청에는 다음 값이 전달된다.

```text
oAuthProvider = "APPLE"
oAuthId = ASAuthorizationAppleIDCredential.user
nickname = fullName 기반 문자열, 없으면 ""
profileImageUrl = ""
```

- `Fiilsa/Fiilsa.entitlements`에 `com.apple.developer.applesignin` entitlement가 추가되어 있다.

Android 기준으로 비교하면, 앱 코드에 SDK 호출을 붙인 상태이고 Play Console/Firebase OAuth 설정과 서버 provider 처리가 아직 맞아야 하는 단계다.

## Apple Developer 설정

Apple Developer 웹의 `Certificates, Identifiers & Profiles`에서 확인한다.

1. `Identifiers`로 이동한다.
2. 앱의 Bundle ID를 선택한다.
   - 현재 iOS Bundle ID: `kbhdev.Fiilsa`
3. `Sign in with Apple` capability를 활성화한다.
4. 변경사항을 저장한다.
5. provisioning profile을 다시 생성하거나 갱신한다.
6. Xcode에서 signing profile이 갱신된 상태로 빌드되는지 확인한다.

주의할 점:

- Xcode entitlements만 추가되어 있어도 Apple Developer App ID capability가 꺼져 있으면 실기기/배포 빌드에서 실패할 수 있다.
- Bundle ID가 Apple Developer App ID, Xcode target, App Store Connect 앱 레코드에서 모두 같아야 한다.

공식 참고:

- Apple Developer Documentation: `AuthenticationServices` Sign in with Apple 구현 문서  
  https://developer.apple.com/documentation/authenticationservices/implementing-user-authentication-with-sign-in-with-apple

## Xcode 설정

Xcode에서 다음을 확인한다.

1. Target `Fiilsa`를 선택한다.
2. `Signing & Capabilities` 탭을 연다.
3. Team이 실제 Apple Developer Team인지 확인한다.
4. Bundle Identifier가 `kbhdev.Fiilsa`인지 확인한다.
5. `Sign in with Apple` capability가 보이는지 확인한다.
6. `Build Settings`에서 `CODE_SIGN_ENTITLEMENTS`가 `Fiilsa/Fiilsa.entitlements`를 가리키는지 확인한다.

현재 프로젝트에는 entitlements 파일과 build setting 연결이 이미 추가되어 있다.

## 서버 설정

서버는 Apple provider를 명시적으로 지원해야 한다.

필수 작업:

- `oAuthProvider = "APPLE"` 허용
- Apple 사용자 고유 ID를 `oAuthId`로 저장
- Apple 계정 최초 가입/기존 로그인 처리 추가
- `nickname`이 빈 문자열이어도 허용
- `profileImageUrl`이 빈 문자열이어도 허용
- 기존 Kakao/Google 중심 enum, validation, DB constraint가 있으면 Apple 추가

권장 작업:

- 앱이 Apple `identityToken`을 서버로 전달하도록 확장
- 서버가 Apple 공개키로 `identityToken` JWT 서명을 검증
- JWT claim을 검증

검증해야 할 claim:

```text
iss == https://appleid.apple.com
aud == iOS Bundle ID 또는 Service ID
exp > 현재 시간
sub == 서버에 저장할 Apple user identifier
```

현재 앱 구현은 `credential.user`를 서버에 전달하는 구조다. 출시 보안 기준으로는 `identityToken`까지 서버에 전달하고 서버에서 검증하는 구조가 더 안전하다.

## 계정 삭제와 Apple 토큰 revoke

App Store 심사 기준상 계정 생성을 지원하는 앱은 앱 안에서 계정 삭제를 시작할 수 있어야 한다. Apple은 계정 삭제가 전체 계정과 관련 데이터를 삭제해야 하며, Sign in with Apple을 쓰는 앱은 Apple REST API로 사용자 토큰 revoke를 고려해야 한다고 안내한다.

현재 앱에는 회원 탈퇴 화면 흐름이 있으므로 Apple 로그인 사용자도 같은 경로로 탈퇴할 수 있어야 한다.

추가로 결정해야 할 점:

- Apple 로그인 시 `authorizationCode`를 서버로 전달할지
- 서버가 Apple token endpoint를 통해 refresh token을 확보할지
- 탈퇴 시 Apple revoke API를 호출할지

공식 참고:

- App Store Review Guidelines 5.1.1(v) Account Sign-In  
  https://developer.apple.com/app-store/review/guidelines/
- Offering account deletion in your app  
  https://developer.apple.com/support/offering-account-deletion-in-your-app/

## App Store Connect 설정

Apple 로그인 자체를 App Store Connect에서 별도 키로 입력하는 단계는 없다. 대신 심사와 개인정보 항목을 맞춰야 한다.

필수 확인:

- Privacy Policy URL 등록
- App Privacy 항목 업데이트
  - 계정 정보
  - 사용자 식별자
  - 이름/email을 저장한다면 해당 데이터 유형
- Review Notes에 로그인 방법 설명
- 심사용 계정 또는 앱 기능을 충분히 확인할 수 있는 테스트 방법 제공
- 계정 삭제 경로 설명

## QA 체크리스트

- Apple 로그인 버튼을 누르면 시스템 로그인 UI가 표시된다.
- 취소 시 로그인 화면에 그대로 남는다.
- 성공 시 Home으로 이동한다.
- 서버에 `oAuthProvider = "APPLE"` 요청이 전달된다.
- 최초 로그인 후 앱 재실행 시 로그인 상태가 유지된다.
- 같은 Apple 계정으로 재로그인 시 기존 계정으로 연결된다.
- Apple이 이름/email을 두 번째 로그인부터 다시 내려주지 않아도 서버 로그인이 성공한다.
- 회원 탈퇴 후 로컬 토큰과 사용자 정보가 삭제된다.
- TestFlight 또는 실기기에서 capability/signing 오류가 없다.

