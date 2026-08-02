# TestFlight 배포 가이드

이 문서는 iOS 앱을 TestFlight로 테스트 배포하는 절차를 Android 개발자 관점에서 정리한다.

Android로 비교하면 TestFlight는 Play Console의 내부 테스트/비공개 테스트 트랙에 가깝다. iOS에서는 Xcode Archive로 빌드를 만들고 App Store Connect에 업로드한 뒤 TestFlight 탭에서 테스터에게 배포한다.

## TestFlight 개념

- TestFlight는 App Store 출시 전 베타 앱을 배포하고 피드백을 받는 Apple 공식 테스트 배포 도구다.
- 테스터는 iOS의 TestFlight 앱을 설치하고 초대 링크 또는 이메일로 베타 앱을 설치한다.
- Apple 공식 문서 기준으로 내부 테스터는 개발 팀 멤버 최대 100명까지 지정할 수 있다.
- 외부 테스터는 최대 10,000명까지 초대할 수 있지만, 첫 외부 배포 빌드는 Beta App Review를 통과해야 한다.
- 외부 테스터는 이메일 초대 또는 public link로 초대할 수 있다.

공식 참고:

- TestFlight overview  
  https://developer.apple.com/testflight/
- App Store Connect TestFlight overview  
  https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/

## 사전 준비

필요한 것:

- Apple Developer Program 가입 계정
- App Store Connect 접근 권한
- App Store Connect에 앱 레코드 생성
- Xcode signing 설정 완료
- Bundle ID와 App Store Connect 앱 레코드가 일치
- 배포용 app icon과 기본 메타데이터 준비
- 서버가 테스트 환경 또는 운영 테스트 가능한 상태

Apple 로그인을 테스트하려면 추가로 다음이 필요하다.

- Apple Developer App ID에서 `Sign in with Apple` capability 활성화
- Xcode target의 `Signing & Capabilities`에 `Sign in with Apple` 표시
- 서버가 `APPLE` provider 로그인 요청을 처리

## App Store Connect 앱 레코드 생성

1. App Store Connect에 로그인한다.
2. `Apps`로 이동한다.
3. `+` 버튼으로 새 앱을 만든다.
4. 플랫폼은 `iOS`를 선택한다.
5. 앱 이름, 기본 언어, Bundle ID, SKU를 입력한다.
6. 앱 레코드를 생성한다.

주의:

- Bundle ID는 Xcode의 `PRODUCT_BUNDLE_IDENTIFIER`와 같아야 한다.
- 현재 프로젝트 기본 Bundle ID는 `kbhdev.Fiilsa`다.

## 빌드 번호와 버전

TestFlight에 같은 build number를 두 번 올릴 수 없다. 매 업로드마다 build number를 올려야 한다.

Xcode에서 확인할 값:

```text
Version = MARKETING_VERSION
Build = CURRENT_PROJECT_VERSION
```

예:

```text
Version: 1.0
Build: 1
다음 업로드: Version 1.0 / Build 2
```

Android로 비교하면 `versionName`은 iOS `Version`, `versionCode`는 iOS `Build`에 가깝다.

## Xcode에서 Archive 업로드

1. Xcode 상단 destination을 실제 기기 또는 `Any iOS Device` 계열로 선택한다.
2. 메뉴에서 `Product > Archive`를 실행한다.
3. Archive가 끝나면 Organizer가 열린다.
4. 생성된 archive를 선택한다.
5. `Distribute App`을 누른다.
6. `App Store Connect`를 선택한다.
7. `Upload`를 선택한다.
8. signing과 capability 검증을 통과하는지 확인한다.
9. 업로드를 완료한다.

업로드 후 App Store Connect의 앱 `TestFlight` 탭에 빌드가 나타나기까지 시간이 걸릴 수 있다.

공식 참고:

- Upload builds  
  https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/

## 내부 테스트 배포

내부 테스트는 Apple Developer/App Store Connect 팀 멤버에게 배포하는 방식이다.

1. App Store Connect에서 앱 선택
2. `TestFlight` 탭 이동
3. 업로드된 빌드 처리 완료 확인
4. `Internal Testing` 그룹 생성 또는 기존 그룹 선택
5. 팀 멤버를 내부 테스터로 추가
6. 테스트할 빌드를 그룹에 추가
7. 테스터는 TestFlight 앱에서 초대를 수락하고 설치

내부 테스트는 일반적으로 외부 Beta App Review보다 빠르게 돌릴 수 있어 개발 중 확인에 적합하다.

## 외부 테스트 배포

외부 테스트는 팀 밖 사용자에게 배포하는 방식이다.

1. `TestFlight` 탭에서 External Testing 그룹 생성
2. 테스트 정보 입력
   - Beta App Description
   - What to Test
   - Feedback Email
   - Beta App Review Information
3. 외부 테스터 이메일 또는 public link 설정
4. 빌드를 외부 테스트 그룹에 추가
5. 첫 외부 배포 빌드는 Beta App Review로 제출된다.
6. 승인 후 외부 테스터가 TestFlight로 설치할 수 있다.

주의:

- 외부 테스트는 앱 정식 심사보다 가볍지만 Apple review를 거친다.
- 로그인 기능이 있으면 review note에 테스트 방법을 적어야 한다.
- 서버가 외부에서 접근 가능해야 한다.

## Apple 로그인 TestFlight QA

Apple 로그인은 시뮬레이터보다 실기기/TestFlight에서 꼭 확인한다.

확인할 것:

- TestFlight 앱에서 설치한 빌드에서 Apple 로그인 버튼이 동작한다.
- Apple 로그인 system sheet가 표시된다.
- 최초 로그인 시 이름/email 권한 화면이 표시된다.
- 성공 후 서버 로그인 API가 정상 응답한다.
- `APPLE` provider 계정이 서버에 생성된다.
- 앱 재실행 후 로그인 상태가 유지된다.
- 회원 탈퇴 후 같은 Apple 계정 재가입/재로그인 정책이 의도와 맞다.

## App Review Notes 초안

TestFlight 외부 심사 또는 App Store 심사 때 참고할 수 있는 설명 초안이다.

```text
This app supports Kakao and Sign in with Apple authentication.
To test Sign in with Apple, tap "Apple로 시작하기" on the login screen.
After successful authentication, the app moves to the Home tab.
Account deletion is available from My Page > Alert/Settings screen for signed-in users.
```

한국어로 내부 기록:

```text
로그인 화면에서 Apple로 시작하기 버튼을 눌러 Apple 로그인 테스트가 가능합니다.
로그인 성공 시 홈 화면으로 이동하며, 회원 탈퇴는 마이페이지 설정 화면에서 진행할 수 있습니다.
```

## 배포 전 체크리스트

- [ ] `Version`과 `Build` 값 확인
- [ ] Release 빌드에서 서버 base URL 확인
- [ ] Kakao REST API key build setting 확인
- [ ] `Sign in with Apple` capability 확인
- [ ] App Store Connect 앱 레코드의 Bundle ID 확인
- [ ] Privacy Policy URL 확인
- [ ] App Privacy 데이터 수집 항목 확인
- [ ] 로그인/탈퇴 review note 준비
- [ ] Archive 업로드 성공
- [ ] 내부 TestFlight 설치 성공
- [ ] Apple/Kakao 로그인 성공
- [ ] 회원 탈퇴 성공
- [ ] 외부 테스트가 필요하면 Beta App Review 제출

