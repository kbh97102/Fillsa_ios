# 전역 로딩 Splash 제외 QA

## Reference
- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/%25E2%259C%2592%25EF%25B8%258F%25ED%2595%2584%25EC%2582%25AC?node-id=2929-5969&t=rysafF9DyBGoWDL9-11
- Target frames/nodes: `2929:5969` loading, `2929:5971` progress indicator. 사용자가 Splash 화면에서는 이 컴포넌트를 제거하도록 지정함.
- Full-frame reference image: [기존 로딩 Figma 프레임](2026-10-03-global-loading-figma.png). Splash 전용 Figma 프레임은 이 저장소에 기록되어 있지 않음.
- Runtime target: iPhone 17 Pro simulator, iOS 26.5, light mode, Splash with active loading count 1.
- Runtime full-frame capture: [2026-10-03-global-loading-splash-excluded.png](2026-10-03-global-loading-splash-excluded.png), 1206×2622px; status bar와 화면 하단을 포함한 전체 시뮬레이터 화면.
- Crop boundaries: 전체 화면, (0, 0)부터 1206×2622px. 기준 Figma 로딩 프레임은 360×720px이며 Splash 합성 프레임이 없어 동일 경계로 비교할 수 없음.
- Comparison method: Splash 런타임 캡처 육안 확인, `globalLoading.spinner` 부재 UI 테스트, 다른 13개 라우트의 스피너 존재·중앙 정렬 UI 테스트. [변경 전 Splash 캡처](2026-10-03-global-loading-splash.png)는 제거 증거로만 사용하고 Figma 기준으로 사용하지 않음.

## Component inventory
| Component | Figma node | Target state | Final result |
|---|---|---|---|
| 전역 로딩 오버레이 | `2929:5969` | Splash에서는 숨김; 나머지 13개 화면에서는 로딩 중 표시 | 런타임 부분 통과; 전체 Splash Figma 비교 Blocked |

## Validation rounds
### Round 1
| Scope | Difference | Fix | Result |
|---|---|---|---|
| Splash | 기존 앱 루트가 로딩 카운트만 검사해 Splash에도 스피너와 딤을 표시함. | `isGlobalLoading` 표시 조건에서 `.splash` 제외; 활성 로딩 카운트는 유지. | 로딩 카운트 1인 Splash에서 스피너 부재 UI 테스트 통과. 전체 캡처에 딤·원형 스피너 없음. |
| 다른 13개 화면 | Splash 제외로 다른 화면의 스피너 노출이 바뀔 수 있음. | 기존 화면 표시 조건 유지. | 13개 라우트의 화면 마커·스피너 존재·중앙 정렬 UI 테스트 통과. |

## Verification
- Red: `AppFeatureTests.test_splashHidesGlobalLoadingWithoutDiscardingActiveScope`가 수정 전 예상한 `false` 대신 `true`를 받아 실패함.
- Green: `AppFeatureTests` 7개와 Splash UI 테스트 1개, 총 8개 통과, 0개 실패 (2026-10-03 22:58 KST).
- 회귀: 전체 `FiilsaTests`와 Splash 제외 13개 라우트 UI 테스트, 총 75개 통과, 0개 실패 (2026-10-03 23:01 KST).
- 런타임 캡처: iPhone 17 Pro iOS 26.5, `-ui-testing-global-loading-screen=splash`로 활성 로딩 카운트 1을 주입한 상태에서 전체 화면을 캡처하고 육안 확인함.

## Final assembled-screen result
- Full-frame reference/capture comparison: [기존 Figma 로딩 프레임](2026-10-03-global-loading-figma.png)과 [Splash 캡처](2026-10-03-global-loading-splash-excluded.png). 로딩 컴포넌트가 Splash에서 제거됐는지 확인했으나 Splash 전용 Figma 전체 프레임이 없어 전체 조립 화면을 일대일 비교할 수 없음.
- Final runtime capture: [Splash 전체 화면](2026-10-03-global-loading-splash-excluded.png).
- Result: 런타임 동작 부분 통과; Figma 전체 프레임 수용은 기준 부재로 Blocked.
- Remaining differences: Splash의 Figma 전체 프레임·노드 ID가 없어 화면 전체의 시각적 일치 여부를 판단할 수 없음.
