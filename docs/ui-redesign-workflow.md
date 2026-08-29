# Figma 기반 UI 개편 워크플로우

이 문서는 기존 화면을 포함한 **모든 iOS UI 수정 작업**의 필수 절차다. `AGENTS.md`의 지시에 따라 UI를 조사·구현·리뷰·검증하는 모든 에이전트는 작업 전에 이 문서를 끝까지 읽어야 한다.

## 1. 기준과 완료 조건

- Figma는 UI의 유일한 정답이다. Android 구현, 기존 iOS 화면, 임의의 플랫폼 관례는 UI 판단 또는 시각 검증 기준으로 사용할 수 없다.
- UI 작업은 Figma 파일 URL과 대상 프레임/노드 ID가 화면 문서에 기록되기 전에는 시작할 수 없다.
- 완료는 “구현했다”가 아니라, 영향을 받은 모든 컴포넌트와 조립된 화면이 Figma와 대조되어 불일치가 없다고 기록된 상태를 뜻한다.
- 최종 시각 결과를 `Pass`로 기록하려면 전체 조립 화면의 Figma 기준 프레임과 실제 런타임 캡처를 비교해야 한다. 자산·빌드·컴포넌트 검사는 부분 증거이며 최종 수용이 아니다.
- 런타임 캡처를 만들 수 없거나 화면에 도달할 수 없으면 결과는 `Blocked`다. 부분 검사를 근거로 `Pass` 또는 완료를 선언하지 않는다.
- Figma에 없는 UI, 상태, 문구, 애니메이션, 상호작용은 추가하지 않는다. 디자인에서 해석할 수 없는 결정은 사용자에게 확인한다.

## 2. 작업 시작 게이트

UI 작업을 받으면 다음 순서로 준비한다.

1. 대상 화면의 `docs/screens/*.md` 문서를 찾는다. 없으면 먼저 만든다.
2. 화면 문서의 `Figma UI 기준` 섹션에 아래 정보를 기록한다.
   - Figma 파일 URL
   - 대상 프레임/노드 ID와 이름
   - 대상 기기·프레임 크기, 색상 모드, 표시 상태
   - Figma MCP로 추출한 **전체 프레임** 기준 이미지의 경로 또는 재현 가능한 참조 정보(루트 배경, status bar, safe area, home indicator/navigation 영역 포함)
3. Figma MCP로 대상 프레임과 하위 계층을 확인하고, 검증에 쓸 기준 이미지를 추출한다. 기준 이미지는 구현 전에 확보한다.
4. 한 프레임에 여러 상태가 있으면 각각을 검증 대상으로 목록화한다. 예: light/dark, 로그인/비로그인, 선택/비선택, 팝업 표시 상태.

Figma URL·노드 ID·기준 이미지 중 하나라도 없으면 이 게이트는 실패다. 구현이나 추정으로 진행하지 말고 필요한 정보를 요청한다.

## 3. 컴포넌트 우선 개발

큰 화면을 통째로 구현하거나 한 번에 검증하지 않는다. Figma의 계층과 반복 구조를 기준으로 화면을 컴포넌트로 나눈다.

각 컴포넌트에는 다음을 화면 문서에 남긴다.

| 항목 | 기록 내용 |
|---|---|
| 이름 | Figma 레이어/영역과 대응되는 컴포넌트 이름 |
| Figma 범위 | 해당 컴포넌트의 노드 ID와 기준 이미지 영역 |
| 책임 | 표시하는 UI와 지원하는 Figma 상태 |
| 조립 위치 | 부모 화면 또는 상위 컴포넌트 |
| 검증 상태 | 미검증, 수정 필요, 부분 통과(최종 수용 아님), 최종 통과 중 하나 |

개발 순서는 하위·독립 컴포넌트부터 상위 컨테이너와 화면 조립 순서로 진행한다. TCA의 상태·액션·리듀서 경계도 이 UI 책임에 맞추되, 구조를 이유로 Figma 결과를 바꾸지 않는다.

각 컴포넌트는 구현 직후 해당 Figma 영역과 먼저 비교·수정한다. 개별 검증을 통과하지 않은 컴포넌트를 화면에 조립한 뒤 전체 화면 검증으로 넘기지 않는다.

## 4. 검증과 수정 루프

검증은 매 라운드에서 다음 순서를 지킨다.

1. Figma 기준 이미지와 같은 대상 기기 크기·색상 모드·상태로 iOS의 **전체 조립 화면**을 캡처한다. 캡처에는 루트 배경, status bar, safe area, home indicator/navigation 영역을 포함한다.
2. 영향을 받은 컴포넌트를 각각 비교한다.
3. 컴포넌트를 조립한 화면 전체를 다시 비교한다.
4. 불일치를 화면 문서와 QA 기록에 구체적으로 남긴다. 대상 노드/컴포넌트, 차이, 수정 위치, 수정 결과를 포함한다.
5. 불일치가 있으면 해당 컴포넌트를 수정하고 1번부터 재검증한다.

비교 항목은 최소한 다음을 포함한다.

- 프레임 크기, safe area를 제외한 콘텐츠 시작 위치, 정렬, 여백, 크기, 스크롤 범위
- 색상, 투명도, 테두리, 그림자, 모서리 반경
- 폰트, 크기, 무게, 줄 높이, 줄바꿈, 문구
- 아이콘·이미지의 원본 자산, 크기, 위치, 상태별 변형
- 시스템 surface 색상(배경·bar·material 등)과 아이콘의 색상·두께·모양·표시 상태
- 표시/숨김 조건, 선택 상태, 팝업·바텀시트 등 Figma에 정의된 모든 대상 상태

### 최대 5회 규칙

- 최초 구현 후 비교를 **1차 검증**으로 센다. 수정 후 수행하는 완전한 재비교가 2~5차 검증이다.
- 한 차수의 통과 조건은 영향을 받은 컴포넌트와 조립 화면 전체에서 모두 불일치가 없는 것이다.
- 자산 원본 확인, asset catalog 검증, 빌드 성공, 개별 컴포넌트 비교는 `부분 통과`로만 기록한다. 이들은 전체 런타임 프레임 비교를 대체하지 않는다.
- 5차 검증 뒤에도 차이가 있으면 작업을 완료로 표시하지 않는다. 남은 차이, 원인, 시도한 수정, Figma 기준을 QA 기록에 남기고 사용자에게 다음 판단을 요청한다.
- headless 환경, 시뮬레이터/기기 접근 불가, 또는 대상 상태 도달 불가로 전체 런타임 캡처를 비교하지 못하면 `Blocked`로 기록하고 사유와 확보한 부분 증거를 남긴다.
- 새로 발생한 조립 단계의 불일치는 해당 하위 컴포넌트를 다시 검증해야 한다. 전체 화면 통과만으로 개별 컴포넌트 검증을 생략할 수 없다.

## 5. 검증 증거와 기록

각 UI 변경에는 `docs/design-qa/YYYY-MM-DD-<screen>-<topic>-qa.md` QA 기록을 새로 만들거나 기존 기록을 갱신한다. 화면 문서는 그 QA 기록으로 링크한다.

QA 기록에는 아래를 반드시 남긴다.

```markdown
# <Screen> Figma UI QA

## Reference
- Figma URL: <URL>
- Target frames/nodes: <node ID and name>
- Full-frame reference image: <path or reproducible Figma MCP output; root background/status bar/safe area/home indicator or navigation area included>
- Runtime target: <platform, simulator/device model and OS, point size, color mode, state>
- Runtime full-frame capture: <path; same boundaries as the Figma reference>
- Crop boundaries: <full frame or exact crop origin/size for both reference and capture>
- Comparison method: <overlay or side-by-side path/tool>

## Component inventory
| Component | Figma node | Target state | Final result |
|---|---|---|---|

## Validation rounds
### Round 1
| Scope | Difference | Fix | Result |
|---|---|---|---|

각 차수에는 비교한 전체 프레임과 crop 경계, overlay 또는 side-by-side 산출물, 그리고 root background·system surface·status/navigation chrome·아이콘을 포함한 정확한 차이를 기록한다.

## Final assembled-screen result
- Full-frame reference/capture comparison: <paths and method>
- Final runtime capture: <path>
- Result: Pass / Blocked after round 5
- Remaining differences: none / <specific list>
```

이미지 파일은 재검증 가능한 프로젝트 내 경로 또는 유지되는 외부 산출물 경로를 기록한다. 일시 경로만 남겨 후속 검증자가 기준 또는 결과를 볼 수 없게 하지 않는다.

## 6. 에이전트 협업 규칙

- 별도 `SUBAGENTS.md`는 사용하지 않는다. `AGENTS.md`와 이 문서가 부모·하위 에이전트 모두의 공통 규칙이다.
- 부모 에이전트는 UI 작업을 위임할 때 Figma URL, 프레임/노드 ID, 맡길 컴포넌트 범위, 대상 상태를 전달한다.
- 하위 에이전트는 이 문서를 읽고 자신에게 할당된 컴포넌트만 구현·검증한다. Figma 범위 밖의 UI 결정을 내리지 않는다.
- 부모 에이전트는 하위 컴포넌트의 검증 증거를 취합한 뒤, 전체 프레임 Figma 기준과 런타임 캡처를 직접 비교하고 최종 조립 화면 sign-off를 수행한다. 하위 컴포넌트 또는 자산·빌드 통과만으로 화면 완료를 선언할 수 없다.

## 7. 화면 문서에 추가할 템플릿

모든 UI 수정 전 해당 화면 문서에 아래 섹션을 추가하거나 최신화한다.

```markdown
## Figma UI 기준

- Figma URL:
- 대상 프레임/노드:
- 대상 기기/프레임 크기:
- 검증 상태:
- 기준 이미지:
- QA 기록:

### 컴포넌트 분해
| 컴포넌트 | Figma 노드 | 책임 | 조립 위치 | 검증 상태 |
|---|---|---|---|---|
```

이 섹션은 작업의 체크리스트가 아니라 완료 판단의 증거다. 비어 있는 필수 항목이 있으면 UI 작업은 시작 또는 완료할 수 없다.
