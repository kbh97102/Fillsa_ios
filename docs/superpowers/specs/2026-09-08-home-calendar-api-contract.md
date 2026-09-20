# 홈·캘린더 API 변경 계약 조사

- 조사일: 2026-09-08
- 원문: [홈·캘린더 리뉴얼 API 연동 가이드](https://app.notion.com/p/Fillsa-3d0e639fc7a480589e90d3245234ee3a)
- 원문 배포 표기: 2026-09-03 운영 배포 및 동작 확인 완료. 이는 문서의 설명이며 이번 조사에서 Fillsa 운영 API를 호출하여 검증한 것은 아니다.
- 조회 방법: 갱신된 `fillsa-notion` 설정으로 새 MCP 프로세스를 실행하고 `API-retrieve-page-markdown`으로 전체 문서를 읽었다. 응답은 `truncated: false`, `unknown_block_ids: []`였다.
- 범위: API 계약 비교와 구현 계획. 앱 구현, 운영 데이터 쓰기, Figma 디자인 변경은 수행하지 않았다.
- 실행 계획: [홈·캘린더 API 연동 계획](../plans/2026-09-08-home-calendar-api-migration.md)

## 확인된 서버 계약

| 구분 | 계약 | 클라이언트 요구사항 |
|---|---|---|
| 신규 주간 조회 | `GET /api/v2/member-quotes/weekly`, 선택 query `endDate` | 최초 요청에서 query 생략. 응답 `startDate`, `endDate`, `days` 보관 |
| 주간 범위 | `endDate-6`부터 `endDate`까지 7일 | 달력의 월요일~일요일 주간과 다름. 최초 응답의 서버 오늘을 기준으로 이전/다음 창을 ±7일 이동 |
| 주간 날짜 선택 | 7일의 카드 콘텐츠가 응답에 포함됨 | 이미 받은 창 안의 날짜 선택·카드 스와이프는 추가 호출 없음 |
| 신규 답변 저장 | `POST /api/v2/member-quotes/{dailyQuoteSeq}/answer` | 요청 `{"answer":"..."}`. 등록과 수정에 동일 API 사용 |
| 저장 응답 | `memberQuoteSeq: Int`, `answer: String`, `answeredAt: String` | 서버가 정리한 answer를 저장 완료 값으로 반영 |
| 답변 검증 | 최대 200자, 공백만 입력 불가, 미래 날짜 불가 | 위반은 HTTP 400 / `errorCode: 1003`. 서버는 앞뒤 공백을 제거 |
| 답변과 필사 | 답변 저장은 필사 완료가 아님 | 답변만으로 `completed`, `state`, streak, typingCount를 변경하지 않음 |
| 신규 단일 조회 | `GET /api/v2/member-quotes/daily?quoteDate=yyyy-MM-dd` | weekly `days` 원소와 동일 모델. 저장 후 갱신·특정 날짜 진입 보조용 |
| 미래 단일 날짜 | 문장·질문이 null | 디코딩 실패 또는 가짜 문장으로 대체하지 않음 |
| 월간 확장 | `GET /api/v2/member-quotes/monthly?yearMonth=yyyy-MM` | 기존 필드·타입·통계 계산식 유지, 상세 8개 필드 추가 |
| 기존 기능 | 좋아요, 이미지 등록/삭제, 필사, streak 유지 | 답변 구현을 memo 또는 typing API에 연결하지 않음 |
| 메모 | v1 memo endpoint 유지, 신규 화면에서 미사용 | 기존 기록 목록·메모 데이터 삭제의 근거가 아님 |

### 주간 및 v2 daily 공통 날짜 모델

- `date`, `dayOfWeek`, `state`
- `dailyQuoteSeq` (명언이 배정되지 않은 날짜는 null)
- `korQuote`, `engQuote`, `korAuthor`, `engAuthor`, `authorUrl`
- `questionKo`, `questionEn`, `answer`, `answeredAt`
- `likeYn`, `imagePath`, `completed`
- 상태: `none`은 미완료 과거, `today`는 미완료 오늘, `done`은 완료. 완료한 오늘은 `done`이 우선한다.
- 서버의 `state`·`dayOfWeek`를 사용한다. 과거 창의 마지막 날을 오늘로 간주하지 않는다. 오늘 기준은 최초 응답의 `endDate`를 별도로 보관한다.
- 미래 `endDate`는 서버가 오늘로 보정한다. 서버 응답 경계를 캐시 키로 사용한다.
- 명언 미배정 날짜도 날짜 칸으로 유지한다. 데이터 식별자는 nullable quote ID 대신 날짜 문자열을 사용한다.
- 연월 배지는 선택 날짜 기준으로 계산한다. 창이 월을 넘더라도 배지 갱신에 API 호출이 필요하지 않다.

### 월간 응답

기존 날짜 필드: `dailyQuoteSeq`, `quoteDate`, `quote`, `author`, `completed`, `todayCompleted`, `likeYn`.

추가 필드: `engQuote`, `engAuthor`, `authorUrl`, `questionKo`, `questionEn`, `answer`, `answeredAt`, `imagePath`.

요약: `typingCount`, `likeCount`, `streakCount`는 그대로다. `quote`/`author`를 주간의 `korQuote`/`korAuthor`와 혼동하지 않는다.

## 현재 iOS 구현과 차이

| 위치 | 현재 코드 | 영향 |
|---|---|---|
| `Fiilsa/Data/API/APIEndpoint.swift` | 회원 daily는 v1, weekly/answer 없음 | 새 endpoint 별도 추가 필요 |
| `Fiilsa/Domain/Responses/QuoteResponses.swift` | `DailyQuote.dailyQuoteSeq`는 필수 Int, 질문·답변·서버 상태 없음 | v2 전용 모델 필요. v1 경로를 전역 치환하면 호환성 위험 |
| `Fiilsa/Domain/Responses/CalendarResponses.swift` | 기존 7개 필드만 보유 | 새 필드는 현재 무시됨. 상세 노출을 위해 optional 필드 추가 |
| `Fiilsa/Presentation/Home/HomeFeature.swift` | 날짜 변경마다 `loadDailyQuote`; 완료 날짜는 local streak 목록에서 구성 | 회원의 주간 캐시와 서버 완료 상태로 전환 |
| 같은 파일의 `answerRecordTapped` | 메모리 변수만 바꾸고 즉시 성공 토스트 | 비동기 서버 저장 성공 후에만 완료 처리 |
| `Fiilsa/Presentation/Home/HomeFigmaComponents.swift` | 질문 문구 고정, 선택 날짜 기준으로 7일 strip 생성 | 서버 질문·고정된 응답 창을 주입하는 binding 필요 |
| `Fiilsa/Presentation/Calendar/CalendarFeature.swift` | `daySelected`는 선택 상태만 변경 | 추가 호출 없는 기존 동작 보존 |
| `Fiilsa/Presentation/Calendar/CalendarSelectedQuoteSection.swift` | 질문 입력은 로컬 `@State`, 저장 CTA는 동작 없음 | 월간 데이터·TCA action 연결 필요 |
| `Fiilsa/Data/Repositories/DefaultTypingRepository.swift` | GET과 POST 모두 같은 v1 typing endpoint 사용 | 문서의 POST v2와 불일치. 별도 계약 확인 필요 |
| `Fiilsa/App/AppFeature.swift` | 화면별 상태를 소유하고 경로 전환 처리 | 저장 결과·캐시 무효화의 화면 간 전달 위치 |

`APIClient`는 Foundation `JSONDecoder`를 사용한다. 따라서 월간 응답에 새로운 키가 추가되었다는 이유만으로 기존 디코딩이 실패하지 않는다. 이번 조사는 실제 운영 응답의 기존 타입/nullable 여부까지 확인한 것은 아니다.

## 구현 전 확인이 필요한 부분

1. **200자의 계산 단위:** 서버 문서는 문자 단위를 명시하지 않았다. 기존 iOS는 Swift `String.count`(사용자가 보는 문자 묶음)를 사용한다. 한글·이모지·조합 문자에 대해 서버의 UTF-16/code point/grapheme 기준을 확인해야 한다. 그 전에는 기존 제한을 유지하고 서버 1003 오류를 처리한다.
2. **비회원 질문/답변:** 신규 계약은 회원 경로만 제공한다. 기존 비회원 조회·로컬 기록은 보존한다. 비회원에게 새 저장 기능이나 로그인 UX를 적용하는 정책은 Figma/기획 근거 확인 후 결정한다.
3. **질문 없는 날짜/미래 daily 상태:** null 문장·질문은 명시되어 있으나 모든 필드의 null 허용 범위와 미래 `state` 값은 완전한 예제가 없다. 모델은 nullable 콘텐츠를 허용하고, 표시 정책은 Figma에서 확인한다.
4. **타이핑 POST v2:** 문서는 경로만 명시한다. v2 요청/응답 상세가 없으므로 기존 Int 응답 및 body가 동일하다고 단정하지 않는다. 전체 명세 또는 테스트 계정 응답으로 확정한 뒤 경로를 수정한다.
5. **기존 7일 UI와 서버 창:** 현재 문서는 선택 날짜를 오른쪽 끝에 놓는다고 적혀 있으나 서버 가이드는 창을 유지하고 내부 선택만 이동시킨다. 서버 캐시 계약은 적용하되, 주간 strip의 실제 움직임은 Figma `3204:2435`와 대상 프레임에서 다시 확인한다.
6. **오류 표시·저장 중 UX:** 새로운 문구·spinner·동작을 추정하여 추가하지 않는다. 현재 Figma의 관련 상태를 확인하고 표현이 없으면 해당 표현 결정만 사용자에게 확인한다.

이 확인 항목은 모델·repository·호환성 테스트 계획 작성의 장애물이 아니다. 확정되지 않은 API 또는 UI 정책에 의존하는 구현만 해당 결론까지 보류한다.

## 공통 제약

- MVI와 Clean Architecture, TCA 스타일을 유지한다.
- Reducer → use case dependency → domain repository → data repository → APIClient 순서를 지킨다.
- Domain use case는 TCA 및 concrete data repository를 import하지 않는다.
- UI는 Figma가 유일한 기준이다. UI 구현 전 화면 문서, Figma URL/노드, 기준 이미지, 상태·컴포넌트 분해, QA 링크를 확보한다.
- UI 변경은 컴포넌트 우선 개발 및 최대 5회 검증을 적용한다. 전체 런타임 프레임 비교 없이 완료로 기록하지 않는다.
- 현재 Xcode 프로젝트의 `IPHONEOS_DEPLOYMENT_TARGET = 26.4`, `SWIFT_VERSION = 5.0`을 변경하지 않는다.
- 기존 작업 중인 Home 문서·QA·Xcode 사용자 상태 파일을 덮어쓰거나 되돌리지 않는다.
