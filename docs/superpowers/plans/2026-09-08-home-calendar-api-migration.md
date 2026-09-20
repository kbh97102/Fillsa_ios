# Home / Calendar API Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. This document authorizes planning only; do not begin implementation as a side effect of reading it.

**Goal:** 2026-09-03 서버 계약에 맞춰 회원 Home의 7일 조회·질문 답변 저장과 Calendar의 월간 상세 데이터를 연동한다.

**Architecture:** 기존 TCA/MVI 및 Clean Architecture를 유지한다. 새 API 응답은 기존 v1 모델과 분리하고, Domain repository/use case 및 Core dependency를 통해 Reducer에 전달한다. Home은 서버 기준 7일 창을 보관하고 Calendar는 월간 응답을 보관하며, AppFeature가 화면 간 저장 결과를 전달한다.

**Tech Stack:** Swift 5 language mode, SwiftUI, ComposableArchitecture, Alamofire, Foundation Codable, Swift Testing, TCA TestStore, XCTest UI tests.

**Spec:** [확인된 계약·현재 코드 비교·미확정 항목](../specs/2026-09-08-home-calendar-api-contract.md), [Notion 원문](https://app.notion.com/p/Fillsa-3d0e639fc7a480589e90d3245234ee3a).

## Global Constraints

- MVI와 Clean Architecture, TCA 스타일을 유지한다.
- Reducer → use case dependency → domain repository → data repository → APIClient 순서를 지킨다.
- Domain use case는 TCA 및 concrete data repository를 import하지 않는다.
- UI는 Figma가 유일한 기준이다. UI 구현 전 화면 문서, Figma URL/노드, 기준 이미지, 상태·컴포넌트 분해, QA 링크를 확보한다.
- UI 변경은 컴포넌트 우선 개발 및 최대 5회 검증을 적용한다. 전체 런타임 프레임 비교 없이 완료로 기록하지 않는다.
- 현재 Xcode 프로젝트의 `IPHONEOS_DEPLOYMENT_TARGET = 26.4`, `SWIFT_VERSION = 5.0`을 변경하지 않는다.
- 기존 작업 중인 Home 문서·QA·Xcode 사용자 상태 파일을 덮어쓰거나 되돌리지 않는다.
- 좋아요/이미지/streak 경로, 비회원 경로, 기존 QuoteList·Memo 데이터는 이번 변경을 이유로 제거하지 않는다.
- 최초 회원 weekly 요청은 `endDate`를 생략한다. 날짜 선택마다 daily를 호출하지 않는다.
- 답변 저장은 필사 완료가 아니며 `completed`, `state`, streak 및 typingCount를 바꾸지 않는다.

---

## 범위와 순서

1. v2 모델 및 HTTP 계약을 먼저 테스트 가능하게 추가한다.
2. 회원 Home 조회를 주간 캐시로 전환한다.
3. 공통 답변 저장 use case를 추가하고 Home 저장을 연결한다.
4. Calendar 월간 상세와 답변 저장을 연결한다.
5. 화면 간 저장 결과, 계정 변경, 타이핑·이미지 후 갱신을 통합 검증한다.
6. 타이핑 v2 계약 불일치를 별도로 확정한다.
7. 화면 문서와 Figma QA를 마무리한다.

Task 1은 UI 결정 없이 진행할 수 있다. Task 2~5의 화면 binding 작업은 아래 Figma 시작 게이트를 선행한다. 타이핑의 미확정 계약은 다른 API 구현의 선행 조건이 아니다.

### UI 구현 시작 게이트

- Home: [기획](../../screens/2_home.md), [Figma](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/2.home?node-id=2929-13556), 기본 `2929:13556`, dark `3039:26518`, 주간 `3204:2435`, 질문 상태 `3087:29376` / `3139:1399` / `3087:29378`, 저장 토스트 `3110:34293`.
- Calendar: [기획](../../screens/3_calendar.md), [Figma](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/3.calendar?node-id=2985-21952), 기본 `2985:21952`, 선택 `2985:22510`, 완료 `2987:22796`.
- 위 참조는 저장소 문서에서 확인했다. 이번 API 조사에서 Figma 노드의 현재 내용을 다시 조회하거나 시각적으로 검증하지는 않았다.
- 구현자는 `docs/ui-redesign-workflow.md` 전체를 읽고 Figma MCP로 해당 프레임의 현재 기준 이미지를 확보한다. 날짜 창 움직임, 질문 null/저장 중/오류/비회원 상태에 대해 디자인에 없는 결정을 도입하지 않는다.
- 기존 Home 문서의 세션 저장 전용 설명은 새 API 계약으로 대체하고, Calendar의 저장 CTA 무동작 설명도 실제 연결 범위에 맞게 수정한다. 다른 작업의 QA 결과를 이번 구현 통과로 재사용하지 않는다.

## 검증 명령

2026-09-08 조회에서 iPhone 17 Pro / iOS 26.5 / `89410CC6-A661-4252-B810-0E54DE5FB620`이 사용 가능했다. 실행 시 기기가 사라졌다면 `xcrun simctl list devices available`로 iOS 26.4 이상 기기를 다시 선택한다.

```bash
xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa \
  -destination 'platform=iOS Simulator,id=89410CC6-A661-4252-B810-0E54DE5FB620' \
  -only-testing:FiilsaTests CODE_SIGNING_ALLOWED=NO
```

각 task의 red/green 단계는 이 명령에 해당 suite의 `-only-testing:FiilsaTests/SuiteName`만 사용한다. 실패가 simulator/package resolution 때문이면 기능의 red로 세지 않는다. 이번 계획 작성에서는 앱 빌드/테스트를 실행하지 않았다.

## Task 1: v2 응답 모델과 repository 계약

**Files**

- Create: `Fiilsa/Domain/Responses/MemberQuoteDay.swift`
- Create: `Fiilsa/Domain/Requests/AnswerRequest.swift`
- Create: `Fiilsa/Domain/Responses/AnswerResponse.swift`
- Modify: `Fiilsa/Domain/Responses/CalendarResponses.swift`
- Modify: `Fiilsa/Data/API/APIEndpoint.swift`
- Modify: `Fiilsa/Domain/Repositories/HomeRepository.swift`
- Modify: `Fiilsa/Data/Repositories/DefaultHomeRepository.swift`
- Create tests: `FiilsaTests/MemberQuoteContractTests.swift`, `FiilsaTests/HomeRepositoryContractTests.swift`

**Interfaces**

기존 `APIClientProtocol`을 그대로 사용한다. 신규 API의 인터페이스는 다음과 같다.

```swift
struct MemberQuoteDay: Codable, Equatable, Identifiable {
    var id: String { date }
    let date: String
    let dayOfWeek: String
    let state: String
    let dailyQuoteSeq: Int?
    let korQuote: String?
    let engQuote: String?
    let korAuthor: String?
    let engAuthor: String?
    let authorUrl: String?
    let questionKo: String?
    let questionEn: String?
    var answer: String?
    var answeredAt: String?
    var likeYn: String?
    var imagePath: String?
    var completed: Bool?
}

struct MemberWeeklyQuoteResponse: Codable, Equatable {
    let startDate: String
    let endDate: String
    var days: [MemberQuoteDay]
}

struct AnswerRequest: Encodable, Equatable { let answer: String }
struct AnswerResponse: Decodable, Equatable {
    let memberQuoteSeq: Int
    let answer: String
    let answeredAt: String
}

// HomeRepository requirements; implemented by DefaultHomeRepository.
func getWeeklyQuotes(endDate: String?) async throws -> MemberWeeklyQuoteResponse
func getMemberQuoteDay(quoteDate: String) async throws -> MemberQuoteDay
func postAnswer(dailyQuoteSeq: Int, request: AnswerRequest) async throws -> AnswerResponse
```

`state`는 원본 String으로 보관하고 알 수 없는 값을 임의로 `none`으로 바꾸지 않는다. 명언이 없는 날짜의 `dailyQuoteSeq`를 0으로 채우지 않는다. `answeredAt`은 timezone이 정의되지 않았으므로 문자열로 보관한다.

- [ ] **1. 계약 테스트를 추가하고 red를 확인한다.** 아래 null/알 수 없는 키 사례 외에 동일한 day fixture를 weekly와 daily 양쪽에서 디코딩한다. 월간은 기존 7개 필드만 있는 fixture와 추가 8개 필드를 포함한 fixture를 비교해 기존 값과 통계가 바뀌지 않는지 검증한다.

```swift
import Foundation
import Testing
@testable import Fiilsa

struct MemberQuoteContractTests {
    @Test func unassignedDayKeepsDateIdentity() throws {
        let payload = #"{"date":"2026-09-01","dayOfWeek":"TUESDAY","state":"none","dailyQuoteSeq":null,"completed":false,"futureField":1}"#
        let day = try JSONDecoder().decode(MemberQuoteDay.self, from: Data(payload.utf8))
        #expect(day.id == "2026-09-01")
        #expect(day.dailyQuoteSeq == nil)
        #expect(day.questionKo == nil)
        #expect(day.completed == false)
    }
}
```

- [ ] **2. 위 모델을 추가하고 월간 모델을 확장한다.** `MemberQuotesData`에 추가 8개 필드를 optional String으로 추가한다. 기존 생성 호출을 깨지 않도록 기존 7개 인자와 신규 인자의 `= nil` 기본값을 가진 명시적 initializer를 제공한다. `answer`, `answeredAt`, `imagePath`는 캐시 병합을 위해 변경 가능하게 한다. 기존 `quote`, `author`, ID 및 요약 타입은 유지한다.
- [ ] **3. endpoint를 추가한다.** 기존 v1 daily 상수와 메서드는 유지한다.

```swift
static let memberWeeklyQuotes = "/api/v2/member-quotes/weekly"
static let memberDailyQuoteV2 = "/api/v2/member-quotes/daily"
static func answer(dailyQuoteSeq: Int) -> String {
    "/api/v2/member-quotes/\(dailyQuoteSeq)/answer"
}
```

- [ ] **4. request를 연결하고 요청 계약 테스트를 추가한다.** `getWeeklyQuotes`는 아래처럼 nil query를 생략한다. daily는 `quoteDate` query, answer는 JSON body 및 `requiresAuthorization: true`로 전송한다. 기존 `FiilsaTests.swift`의 URLProtocol 방식으로 method/path/query/body를 캡처하여 검증한다. `HTTP 400/errorCode 1003` fixture가 `ErrorResponse`로 전달되는지 확인한다. 운영 서버로 저장 테스트를 보내지 않는다.

```swift
let request = APIRequest<EmptyRequestBody>(
    method: .get,
    path: APIEndpoint.memberWeeklyQuotes,
    queryItems: endDate.map { [URLQueryItem(name: "endDate", value: $0)] } ?? []
)
return try await apiClient.send(request, responseType: MemberWeeklyQuoteResponse.self)
```

- [ ] **5. `MemberQuoteContractTests`와 `HomeRepositoryContractTests` green 확인 후 해당 변경만 커밋한다.** 예: `feat: add member quote v2 API contracts`.

## Task 2: Home의 서버 기준 주간 조회·캐시

**Files**

- Create: `Fiilsa/Domain/UseCases/Home/LoadHomeFeedUseCase.swift`
- Create: `Fiilsa/Domain/Support/QuoteDateWindow.swift`
- Modify: `Fiilsa/Core/Dependencies/HomeUseCasesDependency.swift`
- Modify: `Fiilsa/Presentation/Home/HomeFeature.swift`
- Modify bindings: `Fiilsa/Presentation/Home/HomeView.swift`, `Fiilsa/Presentation/Home/HomeFigmaComponents.swift`
- Tests: `FiilsaTests/HomeFeatureTests.swift`, new `FiilsaTests/QuoteDateWindowTests.swift`

**Interfaces**

```swift
enum HomeFeedResult: Equatable {
    case member(MemberWeeklyQuoteResponse)
    case guest(HomeDailyQuoteResult)
}
// LoadHomeFeedUseCase owns HomeRepository and LocalRepository.
func callAsFunction(endDate: String?, guestQuoteDate: String) async throws -> HomeFeedResult
// Addition to HomeUseCases; liveValue calls the use case above.
var loadFeed: @Sendable (String?, String) async throws -> HomeFeedResult
// QuoteDateWindow: date-only Gregorian arithmetic, no device-today inference.
static func endDate(containing date: String, anchor: String) -> String?
```

- [ ] **1. 테스트를 먼저 추가한다.** 최초 로그인 요청에서 endDate nil, 응답 anchor가 기기 날짜와 달라도 서버 날짜 선택, 7일 내 before/next/dateSelected에서 호출 0회, 경계 진입에서 weekly 1회, 캐시 재진입에서 0회, 완료한 오늘의 `done` 보존, null ID 날짜 유지, 로그아웃에서 기존 guest 일간 경로 사용을 검증한다. 월말/연말/윤년은 다음 계산을 포함한다.

```swift
@Test func rollingWindowUsesServerAnchor() {
    #expect(QuoteDateWindow.endDate(containing: "2026-08-31", anchor: "2026-09-03") == "2026-09-03")
    #expect(QuoteDateWindow.endDate(containing: "2026-08-27", anchor: "2026-09-03") == "2026-08-27")
    #expect(QuoteDateWindow.endDate(containing: "2026-09-04", anchor: "2026-09-03") == nil)
}
```

- [ ] **2. date-only 계산과 use case를 구현한다.** 날짜 파싱은 고정 Gregorian/UTC/`en_US_POSIX`를 사용한다. UTC는 날짜 산술의 안정적 기준일 뿐 서버 timezone 추정이 아니다. `delta = anchor - selectedDate`의 달력상 일수, `windowIndex = delta / 7`, `endDate = anchor - windowIndex * 7`로 임의 날짜가 속한 창을 계산한다. 회원은 Task 1 weekly를 호출하고 비회원은 기존 `LoadHomeDailyQuoteUseCase`를 사용한다.
- [ ] **3. Home 상태와 응답 action을 추가한다.** `serverToday: String?`, `weeklyWindows: [String: MemberWeeklyQuoteResponse]`, `activeEndDate: String?`, `selectedDateKey: String`, `feedRequestID: UUID?`를 State에 둔다. `feedLoaded(UUID, Result<HomeFeedResult, ErrorResponse>)`가 현재 request ID와 일치할 때만 활성 선택/로딩 상태를 바꾼다. 요청 실패를 성공 캐시에 넣지 않고 동일 날짜 재시도를 허용한다.
- [ ] **4. 기존 before/next/calendarDateSelected를 같은 선택 처리로 통합한다.** 캐시에 있으면 로컬 선택만 한다. 없으면 anchor에 정렬된 창을 한 번 요청한다. 서버가 보정한 응답 endDate를 캐시 키로 삼는다. 첫 응답 이후 창을 옮겨도 `serverToday`를 과거 endDate로 덮어쓰지 않는다. 창은 날짜 오름차순으로 정리하고 선택을 바꿔도 기존 7일 집합은 유지한다.
- [ ] **5. Figma 시작 게이트 후 binding을 연결한다.** 기존 `DailyQuote`는 v1/Typing/Share용으로 남기고, v2 날짜에서 quote ID가 있는 경우에만 기존 액션용 `DailyQuote`를 만든다. null ID에서는 mutation/navigation을 차단한다. 주간 strip은 응답 날짜·요일·상태를 받도록 바꾸고 로컬 streak 목록으로 회원 완료 표시를 재계산하지 않는다. 질문 문구는 `questionKo`/`questionEn`을 locale에 맞춰 전달한다. 선택 스타일과 서버 완료 상태는 별도 개념으로 유지한다.
- [ ] **6. Home/날짜 테스트 green 확인 후 커밋한다.** 예: `feat: load home quotes by server rolling week`.

## Task 3: 답변 저장 use case와 Home의 비동기 저장

**Files**

- Create: `Fiilsa/Domain/UseCases/Common/SaveQuoteAnswerUseCase.swift`
- Create: `Fiilsa/Core/Dependencies/AnswerUseCasesDependency.swift`
- Modify: `Fiilsa/Presentation/Home/HomeFeature.swift`
- Modify binding: `Fiilsa/Presentation/Home/HomeFigmaComponents.swift`
- Tests: `FiilsaTests/HomeFeatureTests.swift`, new `FiilsaTests/AnswerUseCaseTests.swift`

**Interfaces**

```swift
struct SaveQuoteAnswerUseCase {
    let homeRepository: HomeRepository
    func callAsFunction(dailyQuoteSeq: Int, answer: String) async throws -> AnswerResponse {
        try await homeRepository.postAnswer(
            dailyQuoteSeq: dailyQuoteSeq, request: AnswerRequest(answer: answer)
        )
    }
}

struct AnswerUseCases {
    var save: @Sendable (Int, String) async throws -> AnswerResponse
}
// HomeFeature and CalendarFeature actions use the same identity tuple.
case answerSaved(Int, String, Result<AnswerResponse, ErrorResponse>)
```

- [ ] **1. 저장 테스트를 red로 추가한다.** 기존 `answerRecordsInHomeSessionAndCanReturnToEditing`는 서버 성공 이후 완료되는 계약으로 바꾼다. save 호출 전 성공 토스트 없음, 공백 입력의 호출 0회, 서버 trim 결과 반영, 1003 실패 시 draft/편집 유지, 같은 날짜 중복 탭 방지, A 날짜 저장 중 B 이동 시 A 캐시만 갱신, null ID 저장 차단을 검증한다. completion/streak 관련 dependency를 호출하면 테스트가 실패하도록 대역을 설정한다.
- [ ] **2. Domain use case와 TCA dependency를 등록한다.** `AnswerUseCases`의 `DependencyKey.liveValue`는 `LiveRepositories.home`을 use case에 주입한다. Android의 Hilt 제공 객체처럼 구성하지만 화면은 `@Dependency(\.answerUseCases)`만 사용한다.
- [ ] **3. Home에 날짜별 편집 상태를 둔다.** `answerDrafts: [String: String]`, `savingAnswerDates: Set<String>`, `answerError: ErrorResponse?`를 사용한다. 저장 action에서 quote ID/date/draft를 캡처하고 해당 날짜를 saving 집합에 넣는다. 성공 응답의 ID/date로 weekly 캐시의 answer/answeredAt을 바꾼다. 화면이 같은 날짜일 때만 편집 완료 및 기존 성공 토스트를 적용한다. 실패는 서버 완료로 표시하지 않는다.
- [ ] **4. 기존 상태를 새 저장 계약으로 연결한다.** 날짜 선택 때 서버 answer 또는 해당 날짜의 미저장 draft를 복원한다. 서버 저장 완료 후 draft를 정규화된 answer로 교체한다. 답변 저장 결과로 `completed`/`state`/streak/typingCount를 변경하지 않는다. `memberQuoteSeq`는 응답 레코드 ID이고, 이후 수정 URL에도 계속 `dailyQuoteSeq`를 쓴다.
- [ ] **5. 200자 계약을 검증한다.** ASCII/한글 200·201자, 공백 문자열, 앞뒤 공백, 이모지·조합 문자를 테스트에 포함한다. 서버 문자 단위가 확인되기 전에는 현재 grapheme 제한을 유지하며 1003 오류를 정상 실패로 처리한다. 답변 실패 UX는 Figma 근거 없이 신규 문구/팝업을 추가하지 않는다.
- [ ] **6. Home/Answer 테스트 green 및 커밋.** 예: `feat: persist home question answers`.

## Task 4: Calendar 월간 상세 및 답변 연결

**Files**

- Modify: `Fiilsa/Presentation/Calendar/CalendarFeature.swift`
- Modify bindings: `Fiilsa/Presentation/Calendar/CalendarSelectedQuoteSection.swift`, `Fiilsa/Presentation/Calendar/CalendarView.swift`
- Modify shared component: `Fiilsa/Presentation/Home/HomeFigmaComponents.swift`
- Tests: `FiilsaTests/CalendarFeatureTests.swift`

**Interfaces**

- Consumes: Task 1의 확장 `MemberQuotesData`, Task 3 `AnswerUseCases.save(Int, String)`.
- Produces: 선택 날짜의 월간 레코드와 `answerSaved(Int, String, Result<AnswerResponse, ErrorResponse>)` 처리. 성공은 해당 날짜의 answer/answeredAt만 갱신한다.

- [ ] **1. 월간 테스트를 red로 추가한다.** 날짜 탭 시 weekly/daily/monthly 호출 0회, 같은 월의 다른 날짜 선택 시 각각의 question/answer/image 유지, 저장 실패 시 draft 유지, 저장 성공 시 monthlySummary·completed·todayCompleted 불변을 검증한다.

```swift
@Test @MainActor func selectingDayDoesNotReloadMonth() async {
    let day = FillsaCalendarDateSupport.calendar.date(
        from: DateComponents(year: 2026, month: 9, day: 3)
    )!
    let store = TestStore(initialState: CalendarFeature.State()) {
        CalendarFeature()
    } withDependencies: {
        $0.calendarUseCases.loadMonth = { _ in
            Issue.record("Date selection must not load the month")
            throw ErrorResponse.defaultError
        }
    }
    await store.send(.daySelected(day)) { $0.selectedDay = day }
    await store.finish()
}
```

- [ ] **2. 선택 상세는 현재 `memberQuotes`에서 `quoteDate`로 찾는다.** `quote`/`author`는 한국어 데이터로 유지한다. `engQuote`/`engAuthor`/question/answer/answeredAt/imagePath를 월간 레코드에서 읽는다. 새 필드만 받기 위해 날짜 탭에서 v2 daily를 호출하지 않는다.
- [ ] **3. Calendar의 입력을 reducer 상태로 이동한다.** `@State private var answer`와 무동작 CTA를 TCA draft/action으로 교체한다. Task 3과 동일한 identity/중복 저장 방지를 적용하며 저장은 공통 AnswerUseCases로 호출한다. 다만 Home의 toast 표현을 Calendar에 자동 복제하지 않는다. Calendar Figma 상태에 맞는 binding만 연결한다.
- [ ] **4. 월 전환 응답 경쟁을 막는다.** 요청에 yearMonth와 request ID를 포함하고 이전 월 응답이 현재 선택을 덮어쓰지 못하게 한다. 다른 월에서 완료된 답변 저장은 현재 월 레코드를 잘못 수정하지 않는다.
- [ ] **5. Calendar 및 기존 비회원 월간 테스트 green 후 커밋.** 예: `feat: bind calendar details and answers to monthly data`.

## Task 5: 화면 간 일관성·저장 후 갱신·세션 경계

**Files**

- Modify: `Fiilsa/App/AppFeature.swift`
- Modify lifecycle event binding: `Fiilsa/FiilsaApp.swift`
- Modify: `Fiilsa/Presentation/Home/HomeFeature.swift`, `Fiilsa/Presentation/Calendar/CalendarFeature.swift`
- Modify: `Fiilsa/Presentation/HomeSub/TypingFeature.swift`
- Modify: `Fiilsa/Core/Dependencies/HomeUseCasesDependency.swift`
- Tests: `FiilsaTests/AppFeatureTests.swift`, `FiilsaTests/HomeFeatureTests.swift`, `FiilsaTests/CalendarFeatureTests.swift`

**Interfaces**

```swift
// Added to HomeUseCases; forwards to HomeRepository.getMemberQuoteDay.
var loadMemberDay: @Sendable (String) async throws -> MemberQuoteDay
// HomeFeature/CalendarFeature delegate payload for successful answer writes.
case answerPersisted(Int, String, AnswerResponse)
// Sibling reducer action: patch only matching cached records, with no effect.
case externalAnswerUpdated(Int, String, AnswerResponse)
// TypingFeature delegate distinguishes successful save from ordinary exit.
case saved(dailyQuoteSeq: Int, quoteDate: String)
```

- [ ] **1. root reducer 테스트를 추가한다.** Home 저장 후 Calendar의 해당 날짜 answer 갱신, 역방향 동일, 저장 완료 전에 탭 이동, A의 느린 요청 이후 B 선택, 로그아웃 직후 오래된 응답 도착을 검사한다. 비회원 입력이 회원 토큰으로 자동 업로드되지 않도록 검증한다.
- [ ] **2. 성공 결과를 AppFeature가 전달한다.** 각 feature의 `answerPersisted`를 받아 반대 feature에 `externalAnswerUpdated`를 전송한다. 수신 feature는 다시 delegate를 발생시키지 않는다. 아직 읽지 않은 월/창은 다음 일반 로드 시 서버에서 읽고, 캐시에 없는 레코드를 일부 필드만으로 만들어 넣지 않는다.
- [ ] **3. 이미지·타이핑 성공 후에만 필요한 데이터를 갱신한다.** 이미지 upload/delete 응답은 완료/통계 전체를 제공하지 않으므로 해당 날짜를 v2 daily로 갱신하고 회원 streak를 다시 읽는다. Calendar 해당 월을 stale로 표시하여 다음 표시 시 월간 요약을 서버에서 갱신한다. 타이핑은 실패와 단순 뒤로가기를 성공으로 취급하지 않도록 `saved` delegate를 분리한다. 답변만 저장한 경우 streak 갱신을 호출하지 않는다.
- [ ] **4. 기존 좋아요 성공을 캐시에 반영한다.** 이미 있는 weekly/monthly의 동일 quote만 갱신한다. 실패 시 낙관적 변경을 복구하거나 해당 날짜를 재검증하여 다음 카드 이동 때 오래된 좋아요로 되돌아가지 않게 한다. 통계는 서버 월간 재조회로 확정한다.
- [ ] **5. 계정·날짜 수명 주기를 정의한다.** logout/session expiration/account change에서 회원 창, 답변 draft, 저장 요청을 초기화·취소한다. request ID 또는 세션 generation 검증으로 오래된 응답을 무시한다. `FiilsaApp`의 scenePhase 활성 전환을 `AppFeature.Action.appBecameActive`로 전달하고, 기존 Home 조회 완료 이후 재진입일 때만 `HomeFeature.Action.revalidateServerToday`를 보낸다. 최초 주간 endpoint를 endDate 없이 재검증하여 서버 오늘이 바뀌었으면 창 anchor를 재설정한다. 날짜가 같으면 과거 선택과 미저장 draft를 유지한다. 앱의 모든 날짜 이동을 서버 오늘 재요청으로 바꾸지는 않는다.
- [ ] **6. App/Home/Calendar 테스트 green 후 커밋.** 예: `fix: synchronize quote caches after member mutations`.

## Task 6: 타이핑 저장 v2 불일치 확정

**Files**

- Inspect/conditional modify: `Fiilsa/Data/API/APIEndpoint.swift`, `Fiilsa/Data/Repositories/DefaultTypingRepository.swift`, `Fiilsa/Domain/Requests/QuoteRequests.swift`, `Fiilsa/Core/Dependencies/TypingClient.swift`
- Create test after contract confirmation: `FiilsaTests/TypingRepositoryContractTests.swift`
- Update evidence: `docs/superpowers/specs/2026-09-08-home-calendar-api-contract.md`

- [ ] **1. v2 typing의 요청·응답 명세를 확인한다.** 현재 Notion 페이지의 경로 표기만으로 body/Int 응답이 동일하다고 결론 내리지 않는다. 별도 명세가 없으면 이 task만 계약 확인 대기로 기록한다. 운영 사용자 데이터를 쓰는 실험은 하지 않는다.
- [ ] **2. 확인된 계약의 요청/응답 fixture 테스트를 먼저 작성한다.** GET이 v1, POST가 v2이며 명세의 body와 응답 타입을 사용하는지 검사한다. 기존 schema와 동일함이 확인되면 아래처럼 경로를 분리한다.

```swift
static func typingRead(dailyQuoteSeq: Int) -> String {
    "/api/v1/member-quotes/\(dailyQuoteSeq)/typing"
}
static func typingWrite(dailyQuoteSeq: Int) -> String {
    "/api/v2/member-quotes/\(dailyQuoteSeq)/typing"
}
```

- [ ] **3. read/write repository 경로와 확인된 응답 타입을 적용하고 테스트한다.** 기존 v1 POST가 여전히 지원된다는 확인을 받더라도 v2 계획과 현재 호환성 상태를 구분하여 spec에 기록한다. 이 task의 미확정을 신규 weekly/answer/monthly 전체의 실패로 표현하지 않는다.
- [ ] **4. 계약 증거와 관련 변경만 커밋한다.** 예: `fix: align typing write endpoint with verified contract`.

## Task 7: 문서 정리·전체 회귀·Figma 최종 검증

**Files**

- Update: `docs/screens/2_home.md`, `docs/screens/3_calendar.md`, `docs/development-progress.md`
- Create: `docs/design-qa/2026-09-08-home-api-binding-qa.md`, `docs/design-qa/2026-09-08-calendar-api-binding-qa.md`
- Update UI tests as needed: `FiilsaUITests/HomeUITests.swift`, `FiilsaUITests/CalendarUITests.swift`

- [ ] **1. API 문서를 실제 계약으로 갱신한다.** weekly/daily/answer/monthly를 화면별로 기록하고 세션 전용 답변 설명을 대체한다. 메모 미사용은 새 Home/Calendar에 한정한다. QuoteList 및 메모 화면을 삭제하지 않는다.
- [ ] **2. 전체 unit regression을 한 번 실행한다.** 위 검증 명령으로 FiilsaTests 전체를 실행하고 앱 빌드·통과 suite·실패 원인을 기록한다. 계약 fixture에는 no-assignment, done-today, 월 경계, 1003, trimmed answer, 새 월간 필드 누락/null, 비회원, stale response를 포함한다.
- [ ] **3. 실제 호출 수를 검증한다.** 최초 회원 Home은 weekly 1회와 기존 streak 조회, 창 내 날짜 이동 0회, 미캐시 창 이동 weekly 1회, Calendar 날짜 선택 0회, 답변 저장 POST 1회를 fixture 네트워크 로그로 확인한다. 저장 후 필요한 갱신 호출은 별도 이벤트로 구분한다.
- [ ] **4. UI 테스트 및 Figma 검증을 진행한다.** 같은 데이터 fixture·언어·모드로 Home과 Calendar를 캡처한다. 컴포넌트 검증 후 전체 화면을 비교하며 수정 포함 최대 5회를 적용한다. 기존 360pt Figma와 402pt simulator 폭 불일치가 해결되지 않으면 부분 증거만 남기고 UI 완료로 기록하지 않는다. 필요한 새 오류·null·비회원 표시 계약이 없으면 해당 상태만 미확정으로 남긴다.

```bash
xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa \
  -destination 'platform=iOS Simulator,id=89410CC6-A661-4252-B810-0E54DE5FB620' \
  -only-testing:FiilsaUITests/HomeUITests \
  -only-testing:FiilsaUITests/CalendarUITests CODE_SIGNING_ALLOWED=NO
```

- [ ] **5. 영향 범위를 검토하고 QA·문서 변경을 커밋한다.** `git diff --check`와 변경 파일 목록을 확인한다. API 계약 완료, 운영 API 미검증, UI QA 결과, Task 6 계약 확인 상태를 각각 기록한다.

## 수용 기준

- [ ] 회원 Home이 서버 기준 7일을 읽고 창 내 이동에 추가 호출이 없다.
- [ ] 질문·답변·언어·이미지가 선택 날짜와 일치하며 명언 미배정 날짜를 안전하게 처리한다.
- [ ] 답변은 서버 성공 후 완료되며 재조회로 복원된다. 실패·날짜 전환·계정 전환에서 다른 기록을 덮어쓰지 않는다.
- [ ] 답변만으로 필사 완료/연속 일수/월간 typingCount가 변하지 않는다.
- [ ] Calendar는 월간 응답의 상세를 사용하며 날짜 탭에 추가 조회가 없다.
- [ ] 좋아요·이미지·필사 후 두 화면 데이터가 일치하고 기존 비회원 동작이 회귀하지 않는다.
- [ ] 타이핑 v2 불일치의 결론과 근거가 기록되거나 그 기능만 계약 확인 대기로 명시된다.
- [ ] Figma 기준의 모든 영향 컴포넌트·전체 화면 QA 증거가 없으면 UI 완료라고 보고하지 않는다.

## 계획 자체 검토

- Notion의 신규 3개 API, 월간 확장, memo 범위, 기존 기능 보존을 task에 연결했다.
- 원문의 확정 계약과 비회원·문자 길이·typing schema·UI 상태 미확정을 분리했다.
- 모든 새 타입/메서드 이름은 이 문서에 정의했고 기존 코드의 v1 DTO/APIClient/use case 구조에 연결했다.
- 이번 산출물은 spec과 plan 두 문서다. 앱 코드는 수정하지 않았고 구현 테스트도 실행하지 않았다.
