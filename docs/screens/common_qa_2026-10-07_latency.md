# 공통: 응답 속도 질문

- QA: [Notion 원문](https://app.notion.com/p/3f2e639fc7a48039ab7ec96feba74c9a) — 높음, Not started, Device 미지정. “전반적으로 호출하면 응답이 길어져 로딩바가 뜨는데 서버에서 속도를 느리게 주는가”라는 질문.
- 화면 계획: [공통 로딩](common.md), [Home](2_home.md), [Calendar](3_calendar.md)
- Figma: [공통 로딩 `2929:5969`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=2929-5969)
- 판단 범위: 실제 요청/서버 응답 시간과 재현 환경이 없어 **지연의 주원인은 미확정**. 로딩 표시 규칙과 현재 호출 흐름은 코드로 확인.

## 확인된 동작

`LoadingClient`는 비동기 작업이 시작될 때 토큰을 등록하고 모든 등록 작업이 끝나면 제거한다 (`Fiilsa/Core/Dependencies/LoadingClient.swift:9-16,19-33`). 앱은 활성 토큰이 하나라도 있으면 Splash 외 화면에 로딩 오버레이를 표시한다 (`Fiilsa/App/AppFeature.swift:24-25`, `Fiilsa/App/AppView.swift:193-218`). 따라서 긴 로딩 표시만으로 서버 지연을 단정할 수 없다.

Home 첫 진입은 daily 명언 조회와 완료 상태 조회를 병렬 실행하지만 **둘 다 종료될 때까지** 한 로딩 토큰을 유지한다 (`Fiilsa/Presentation/Home/HomeFeature.swift:65-78`). 회원의 명언 조회는 v1 daily API, 연속 일수 조회는 별도 API다 (`Fiilsa/Domain/UseCases/Home/HomeUseCases.swift:12-19`, `Fiilsa/Domain/UseCases/Common/MemberStreakUseCases.swift:24-36`). Home의 날짜 이동은 매번 daily 조회를 다시 호출한다 (`Fiilsa/Presentation/Home/HomeFeature.swift:80-95,316-322`). 2026-09-03 서버 가이드는 이 지연을 줄이기 위한 v2 weekly 응답을 제공하며, 이미 받은 7일 창의 날짜·카드 이동에는 추가 호출이 없도록 명시한다. 현재 구현에는 아직 반영되지 않았다. 이는 반복 로딩의 **확인된 클라이언트 기여 요인**이지만, 모든 화면의 지연 원인이라는 뜻은 아니다.

Debug 빌드의 `HTTPLogger`는 각 HTTP 요청의 Alamofire task 총 시간을 ms로 출력한다 (`Fiilsa/Data/API/APIClient.swift:202-210`). 이 값만으로 DNS/연결, 서버 처리, 응답 전송, 디코딩, 여러 작업의 합류 대기를 나눌 수는 없다.

## 원인 분리 및 해결 방안

1. QA 환경(기기, 앱 버전, 로그인 여부, 네트워크, 느린 화면·액션)과 재현 횟수를 기록한다. 동일 화면을 첫 진입/재진입/날짜 이동으로 나눠 측정한다.
2. 액션 시각 → API 요청 시작 → 응답 헤더/완료 → 디코딩 완료 → reducer 상태 반영 → 로딩 토큰 종료를 같은 요청 ID로 계측한다. Home의 병렬 작업은 daily와 streak 각각의 시간 및 늦게 끝난 작업을 기록한다. 민감한 토큰·답변·응답 본문은 성능 기록에서 제외한다.
3. 서버와 비교할 때 동일 요청 ID의 서버 처리 시간 및 응답 크기를 받는다. API task가 길고 서버 처리도 길면 서버 원인을, API는 빠른데 오버레이만 길면 클라이언트 작업/합류·상태 흐름을 조사한다. 401/403 refresh 재시도, 이미지 업로드 크기, 네트워크 조건도 별도 분류한다.
4. Home 날짜 반복 조회는 서버 가이드의 weekly 캐시로 바꾸는 것이 명시된 개선 경로다. 실제 측정에서 다른 병목이 확인되면 해당 경로를 따로 수정한다. 로딩 표시 시간을 임의로 줄여 작업 완료 전 터치를 허용하지 않는다.

## 검증 기준

- 느린 사례마다 화면 액션, 관련 요청 수, 각 구간 시간, 서버 처리 시간, 오버레이 시작/종료가 한 타임라인에 남는다.
- 개선 전후 같은 조건에서 요청 수와 사용자 대기 시간을 비교한다. 서버 원인 판단은 서버 측 측정값과 맞춘 뒤 확정한다.
- 로딩 UI를 수정한다면 공통 Figma 컴포넌트 및 전체 영향 화면을 [UI 절차](../ui-redesign-workflow.md)에 따라 검증한다.
