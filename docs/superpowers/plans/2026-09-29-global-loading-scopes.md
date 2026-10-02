# Global Loading Scopes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Feature의 공통 API wrapper와 여러 API를 모두 기다리는 작업 묶음으로 전역 로딩을 관리한다.

**Architecture:** actor가 활성 scope token과 개수 stream을 관리하고, LoadingClient를 TCA dependency로 주입한다. 단일 작업은 `.runWithLoading`, 여러 작업 묶음은 Feature의 `.run`에서 명시적 begin/await/end를 사용하며 AppFeature만 전역 표시 상태를 소유한다. APIClient/Repository/UseCase에는 UI 로딩 책임을 추가하지 않는다.

**Tech Stack:** Swift 5 mode, Swift Concurrency, SwiftUI, TCA 1.26.0, 기존 XCTest/Swift Testing. 새 패키지 없음.

**Spec:** [2026-09-29-global-loading-scopes.md](../specs/2026-09-29-global-loading-scopes.md)

## Global Constraints

- 활성 scope가 하나 이상일 때 전역 로딩을 표시한다.
- 하나의 단일 wrapper 또는 명시적 작업 묶음이 하나의 로딩 범위(scope)다.
- B가 실패해도 A/C를 계속 기다리는 것을 기본으로 한다.
- 취소는 일반 실패 Action/토스트로 바꾸지 않는다.
- APIClient/Repository/UseCase는 UI 로딩을 알지 않는다.
- 전체 앱 테스트는 사용자의 기존 요청에 따라 생략하고 관련 suite만 실행한다.
- 검증 실패는 `docs/verification/<검증일>-global-loading-failures.md`에 원인·위치·증거·재검증 결과를 기록하고 사용자에게 링크와 요약을 제공한다.
- 시각 구현 전 Figma URL/node-id, 전체 기준 이미지, common 화면 계획 및 QA 기록을 확보한다.
- 작업은 이 세션에서 순차 실행하는 방식으로 제안하며, 구현은 사용자 계획 검토 후 시작한다.

## Review Focus

- A/B/C가 다른 순서로 끝나거나 B만 실패해도 마지막 자식까지 로딩을 유지하는가? Task 3에서 검증.
- 겹친 scope 또는 중복 end가 다른 요청의 로딩을 끄는가? Task 1에서 검증.
- 취소·취소 전 시작·취소를 일반 오류로 던지는 client가 scope를 남기거나 오류 UI를 만드는가? Tasks 1/3/4에서 검증.
- 구독 전에 시작된 작업과 UI fixture의 startup guard 때문에 App 상태가 누락되는가? Task 2에서 검증.
- 결과 Action, 팝업 표시, API 재시도/후속 저장이 끝나기 전에 scope가 종료되는가? Tasks 1/4/5에서 검증.

## 파일과 책임

| 파일 | 책임 |
|---|---|
| `Fiilsa/Core/Dependencies/LoadingClient.swift` (신규) | actor registry, dependency, withLoading 수명 관리 |
| `Fiilsa/Presentation/Common/LoadingEffect.swift` (신규) | Effect.runWithLoading 진입점 |
| `Fiilsa/App/AppFeature.swift` | 개수 구독, activeLoadingCount, 표시 상태 |
| 각 API 호출 Feature | 단일 자동 wrapper 또는 명시적 묶음 begin/await/end, 기존 결과/오류/취소 처리 |
| `Fiilsa/Presentation/Common/GlobalLoadingOverlay.swift` (Figma 확보 후 신규) | Figma에 정의된 표시만 담당 |
| `Fiilsa/App/AppView.swift` | 최상위 overlay 한 번 조립 |
| 관련 테스트와 `docs/screens/common.md` | 동작 회귀, 디자인 계약과 QA 증거 |

## Task 1: scope registry와 공통 wrapper

**Files:** Create `Fiilsa/Core/Dependencies/LoadingClient.swift`, `Fiilsa/Presentation/Common/LoadingEffect.swift`, `FiilsaTests/LoadingClientTests.swift`, `FiilsaTests/LoadingEffectTests.swift`.

**Interfaces:** spec의 `LoadingClient.begin/end/counts/withLoading`, `DependencyValues.loadingClient`, `Effect.runWithLoading(operation:)`를 제공한다. 같은 파일의 internal actor `LoadingRegistry`는 begin/end/counts를 담당하며 활성 token과 구독자 continuation을 보관한다.

- [ ] 실패 테스트 작성: `singleScopeStartsAndEnds`, `overlappingScopesRemainActiveUntilLastEnd`, `duplicateEndDoesNotEndAnotherScope`, `lateSubscriberReceivesCurrentCount`, `cancelledBeforeStartDoesNotBegin`, `cancelledOperationBalancesItsToken`, `scopeEndsAfterResultActionIsReduced`. 각각 count가 0→1→0, 0→1→2→1→0으로 바뀌는지와 end가 정확한 token에 한 번 적용되는지 검증한다.
- [ ] `LoadingClientTests`와 `LoadingEffectTests`만 실행해 RED를 확인한다.
- [ ] actor에서 token 삽입/삭제 후 snapshot을 publish한다. counts는 `.bufferingNewest(1)` stream으로 현재 count를 초기 yield하고, 종료 구독자는 제거한다. 늦은 구독의 초기 snapshot과 등록이 actor 안에서 원자적으로 이뤄지게 한다.
- [ ] `DependencyKey.liveValue`는 하나의 registry를 사용한다. `testValue`는 no-op begin/end와 0을 yield 후 종료하는 stream을 제공한다. 로딩 검증 테스트는 자신만의 registry/client로 override한다.
- [ ] `withLoading`을 취소 전 검사 → begin await → 취소 여부 확인 → nonthrowing operation await → end await로 구현한다. detached Task나 비동기 defer 정리를 사용하지 않는다.
- [ ] `runWithLoading`은 DependencyValues를 캡처하고 `.run` 안에서 `withLoading`을 실행한다. 성공/실패 Action 변환은 caller에게 남긴다. source location 인자를 제공하는 경우 native `.run`의 fileID/filePath/line/column에 그대로 전달한다.
- [ ] 같은 focused tests로 GREEN 및 stream 정리 여부를 확인한다.
- [ ] 커밋: `feat: add scoped global loading wrapper`.

## Task 2: AppFeature 전역 표시 상태 연결

**Files:** Modify `Fiilsa/App/AppFeature.swift`, `FiilsaTests/AppFeatureTests.swift`.

**Interfaces:** Task 1의 `loadingClient.counts()`를 소비한다. `activeLoadingCount: Int`, computed `isGlobalLoading: Bool`, `loadingCountChanged(Int)`를 제공한다.

- [ ] 실패 테스트 작성: `loadingCountControlsGlobalVisibility` (0/2/1/0에서 false/true/true/false), `startupSubscribesToCurrentLoadingCount`, `loadingSubscriptionDoesNotRegisterAScope`, `fixtureStartupStillSubscribesToLoading`.
- [ ] `AppFeatureTests`만 실행해 RED를 확인한다.
- [ ] `.task`에서 counts 구독을 별도 Effect로 만들고 typed cancellation ID로 중복 구독을 막는다. 기존 fixture guard는 다른 startup 작업에만 적용한다. 부모/자식 navigation으로 count를 reset하지 않는다.
- [ ] count Action은 App reducer에서만 처리한다. 새 비즈니스 로딩 flag를 각 Feature에 복제하지 않는다.
- [ ] `AppFeatureTests`, Task 1 테스트로 GREEN을 확인한다.
- [ ] 커밋: `feat: bind loading scope count to app state`.

## Task 3: Home으로 단일 호출과 묶음 호출 검증

**Files:** Modify `Fiilsa/Presentation/Home/HomeFeature.swift`, `FiilsaTests/HomeFeatureTests.swift`.

**Interfaces:** Task 1의 `.runWithLoading` 및 `loadingClient.begin/end`를 소비한다. Home 내부 helper `fetchDailyQuote(quoteDate: String, send: Send<Action>) async`와 `fetchCompletionState(send: Send<Action>) async`는 오류를 밖으로 던지지 않는다.

- [ ] 실패 테스트 작성: `homeEntryWaitsForQuoteAndCompletionState`, `quoteFailureStillWaitsForCompletionState`, `homeSingleRequestUsesOneScope`, `homeCancellationDoesNotSendFailure`. 첫 자식 완료/실패 후에는 count=1, 마지막 자식과 Action 처리 후에는 count=0인지 확인한다.
- [ ] `LoadingEffectTests`에 명시적 begin/await/end로 구성한 A/B/C 제어 gate 테스트 `groupWaitsForAllThreeChildren`와 `oneFailedChildDoesNotEndGroup`를 추가한다. A 완료와 B 실패 후 C가 열린 동안 count=1, C 종료 후 count=0을 검증한다.
- [ ] `HomeFeatureTests`, `LoadingEffectTests`만 실행해 RED를 확인한다.
- [ ] Home에 `@Dependency(\.loadingClient)`를 주입한다. 기존 `.onAppear`의 `.merge(load, completionState)`를 하나의 `.run`에서 직접 begin/await/end를 선언하는 형태로 옮긴다. `load(state:)`는 기존 flag 설정과 date 캡처를 유지하며 단일 quote wrapper를 반환한다. 초기 진입은 같은 quote helper와 completion helper를 직접 호출한다.

```swift
return .run { send in
    guard !Task.isCancelled else { return }
    let token = await loadingClient.begin()
    if !Task.isCancelled {
        async let quote: Void = fetchDailyQuote(quoteDate: quoteDate, send: send)
        async let completion: Void = fetchCompletionState(send: send)
        _ = await (quote, completion)
    }
    await loadingClient.end(token)
}
```

- [ ] 각 helper의 catch에서 먼저 `CancellationError`/`Task.isCancelled`를 확인한다. 취소라면 failure Action 없이 돌아간다. 일반 오류는 기존 ErrorResponse 변환을 유지한다. 완료 상태 helper의 로컬 조회 실패 fallback도 유지한다.
- [ ] 날짜 변경, 좋아요, 업로드, 삭제의 기존 `.run`을 `.runWithLoading`으로 전환한다. 공통 wrapper 안에서 결과 Action을 await한 후 반환한다.
- [ ] focused tests로 GREEN을 확인한다. 이 단계는 화면 픽셀을 변경하지 않는다.
- [ ] 커밋: `feat: group Home entry work in one loading scope`.

## Task 4: 나머지 foreground API 작업으로 확장

**Files:** Modify `Calendar/CalendarFeature.swift`, `QuoteList/QuoteListFeature.swift`, `Login/LoginFeature.swift`, `HomeSub/TypingFeature.swift`, `QuoteListSub/MemoInsertFeature.swift`, `MyPage/MyPageFeature.swift`, `MyPageSub/NoticeFeature.swift`, `MyPageSub/AlertFeature.swift`, `Common/GeneralPopupFeature.swift` (모두 `Fiilsa/Presentation/` 하위). Test 기존 대응 Feature tests, 신규 `FiilsaTests/FeatureLoadingIntegrationTests.swift`.

**Interfaces:** `.runWithLoading`과 부분 작업용 `loadingClient.withLoading`을 소비한다. 기존 Feature State/Action, 반환값, 오류 문구, navigation contract를 유지한다.

- [ ] 실패 테스트 작성: 각 spec 적용 행의 사용자 API 작업이 scope를 등록하고 종료하는지 확인한다. 대표 단일 성공/실패는 Calendar, 취소·새 요청 중첩은 QuoteList, 두 API 묶음은 GeneralPopup, 결과 뒤 세션 정리는 MyPage, 실제 인증 SDK 대기 제외는 Login으로 고정한다. API가 없는 로컬 설정 변경은 count=0인지 확인한다.
- [ ] 대응 Feature tests와 `FeatureLoadingIntegrationTests`만 실행해 RED를 확인한다.
- [ ] spec 적용 표대로 wrapper를 변경한다. 기존 `isLoading/isSaving/isProcessing`과 중복 방지 guard를 삭제하지 않는다. QuoteList `.cancellable`은 바깥에 유지한다.
- [ ] GeneralPopup의 기존 순차 조회는 `.run`에서 begin/end를 직접 선언한다. 일반 popup 실패에도 버전 popup 조회를 이어가는 기존 동작을 보존한다. 취소라면 다음 API/loaded Action을 진행하지 않되 end는 실행한다. begin 이후 end를 건너뛰는 early return/throw는 금지한다.
- [ ] Login은 `login(user:)`만 감싼다. Apple/Kakao 인증 SDK가 시스템 UI를 기다리는 Effect는 감싸지 않는다.
- [ ] Alert는 기존 OS 권한 흐름 뒤의 `pushRegistrationClient.synchronize` 구간만 `withLoading`으로 감싼다. 백그라운드 호출 경로의 동작은 유지한다.
- [ ] 취소 가능 API Effect의 catch/try? 이후 Task 취소 여부를 확인하여 cancellation을 일반 실패로 바꾸거나 후속 API를 계속 시작하지 않게 한다. 기존 HTTP retry는 wrapper 안의 동일 호출로 처리하고 추가 token을 생성하지 않는다.
- [ ] focused tests로 GREEN을 확인하고 `rg`로 각 적용 행과 실제 API Effect가 일치하는지 검사한다.
- [ ] 커밋: `feat: use scoped loading for foreground API effects`.

## Task 5: Figma 스피너를 최상위 화면에 조립

**Gate:** Figma 대상 URL/node-id가 제공되기 전에는 이 Task의 UI 구현을 시작하지 않는다. 로딩 상태 계층을 구현해도 이 단계가 끝나기 전에는 “스피너 추가 완료”로 보고하지 않는다.

**Files:** Create `Fiilsa/Presentation/Common/GlobalLoadingOverlay.swift`, `FiilsaUITests/GlobalLoadingUITests.swift`, `docs/design-qa/2026-09-29-common-loading-qa.md`; Modify `Fiilsa/App/AppView.swift`, `Fiilsa/FiilsaApp.swift` (fixture만), `docs/screens/common.md`.

**Interfaces:** AppFeature의 `isGlobalLoading`을 소비한다. 표시 View는 API·token·오류 처리 책임을 갖지 않는다.

- [ ] `docs/ui-redesign-workflow.md`를 끝까지 읽고 Figma 전체 프레임/컴포넌트/상태를 확보한다. common 화면 계획에 source, spinner 영역, light/dark, 터치 차단·모달 층 순서, QA 링크를 기록한다.
- [ ] 제어 가능한 A/B/C fixture를 준비하고 `spinnerRemainsVisibleUntilLastRequestEnds`, `spinnerDisappearsAfterFailureOrCancellation` 테스트를 작성한다. 결과 popup/navigation은 scope Action 반영과 종료 이후 Figma가 허용한 상태로 보이는지 확인한다.
- [ ] 해당 UI 테스트만 실행해 RED를 확인한다.
- [ ] Figma 자산/구조를 바탕으로 최상위 overlay를 한 번 조립한다. SwiftUI native ProgressView는 디자인과 일치하는 경우에만 사용한다. 디자인에 없는 딤·문구·지연·최소 표시 시간을 추가하지 않는다.
- [ ] UI 테스트 GREEN 이후 영향을 받은 컴포넌트와 전체 프레임을 캡처·대조한다. 최대 5회 라운드, 결과와 남은 차이를 QA 기록에 남긴다.
- [ ] 커밋: `feat: display Figma global loading overlay`.

## 검증 명령

사용 가능한 simulator ID를 먼저 `xcrun simctl list devices booted`로 확인한다. 아래 명령의 destination은 그 ID로 대체한다. 현재 변경 대상 suite만 `-only-testing`에 추가하며 전체 앱 suite는 실행하지 않는다.

```bash
xcodebuild -quiet test -project Fiilsa.xcodeproj -scheme Fiilsa \
  -only-testing:FiilsaTests/LoadingClientTests \
  -only-testing:FiilsaTests/LoadingEffectTests \
  -only-testing:FiilsaTests/AppFeatureTests \
  -only-testing:FiilsaTests/HomeFeatureTests \
  -parallel-testing-enabled NO \
  -destination 'platform=iOS Simulator,id=<available-device-id>' \
  -derivedDataPath /tmp/fiilsa-global-loading-derived \
  -clonedSourcePackagesDirPath /tmp/fiilsa-firebase-packages \
  CODE_SIGNING_ALLOWED=NO
```

## 검증 실패 기록 및 보고

모든 Task의 검증 단계에 적용한다. 실패가 실제 발생한 시점에 `docs/verification/<검증일>-global-loading-failures.md`를 생성하고, 같은 작업의 후속 실패·재검증은 같은 문서에 추가한다.

- [ ] 실패한 Task/명령, 테스트 suite/테스트 이름, assertion 또는 빌드 오류의 파일 경로와 줄 번호를 기록한다. 오류가 관측된 위치와 실제 원인 코드의 위치가 다르면 둘 다 적는다.
- [ ] 기대 동작과 실제 결과를 값으로 기록한다. 묶음 로딩 문제라면 A/B/C의 시작·응답 순서와 각 시점의 활성 scope 수를 함께 남긴다.
- [ ] 재현 명령, simulator/OS/Xcode 환경과 관련 오류 로그를 보존한다. xcresult 위치와 필요한 발췌를 함께 기록하며 인증 정보는 제외한다. UI 실패는 PNG/Figma QA 링크를 추가한다.
- [ ] 원인을 근거와 함께 설명한다. 확인 전에는 `원인 미확인`으로 표시하고 가설·추가 확인 항목을 구분한다. 의도한 TDD RED / 예상하지 못한 실패, 제품 코드 / 테스트 코드 / 빌드·환경 문제를 분류한다.
- [ ] 시도한 수정과 재검증 명령·결과를 추가한다. 해결 후에도 최초 실패 기록을 지우지 않는다. 상태는 `조사 중`, `수정 후 재검증 중`, `해결`, `미해결`로 갱신한다.
- [ ] 사용자에게 문서 링크와 “어디서 / 왜 / 해결 여부”를 요약한다. 미해결 검증을 통과로 보고하지 않는다.

실패 항목은 아래 형식으로 작성한다.

```markdown
## F-01: <실패 요약>
- 상태 / 분류:
- 작업 / 테스트:
- 관측 위치 / 원인 위치: <파일:줄 번호 또는 원인 미확인>
- 기대값 / 실제값:
- 재현 명령 / 환경:
- 원인 / 확인 근거 / 미확인 가설:
- 오류 로그 / xcresult / 화면 증거:
- 수정 내용:
- 재검증 명령 / 결과:
```

## Handoff

これは実装前の計画。推奨は同じセッションで Task 1→4を順次実装し、Figmaが揃ったら Task 5へ進む方法。APIの適用範囲と「一般失敗でも他の API は待つ」既定をユーザーがレビューしてからコード実装を開始する。
