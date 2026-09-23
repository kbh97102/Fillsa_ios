# Home Answer Keyboard Figma UI QA

## Reference
- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/2.home?node-id=3110-34152
- Target frames/nodes: `3110:34152` (`02 · 답변 기록 중`), `3139:1399` (`Question`, focus)
- Full-frame reference image: Figma MCP `get_design_context` output for `3110:34152`
- Runtime target: iPhone 17 Pro, iOS 26.5, light mode, answer editor focused with software keyboard visible
- Round 1 capture: `docs/design-qa/assets/home-answer-keyboard/2026-09-23/runtime-ios-home-answer-keyboard-round1.png`
- Final runtime capture: `docs/design-qa/assets/home-answer-keyboard/2026-09-23/runtime-ios-home-answer-keyboard-final.png`
- Crop boundaries: full frame
- Comparison method: side-by-side

## Component inventory
| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Home scroll content | `3110:34152` | Keyboard visible; quote content scrolls behind the fixed header; bottom navigation is covered | Pass at runtime; strict full-frame acceptance blocked by viewport mismatch |
| Question/answer | `3139:1399` | Focused editor and record CTA remain reachable | Pass |

## Validation rounds
### Round 1
| Scope | Difference | Fix | Result |
|---|---|---|---|
| Focused answer flow | Fixed Home content leaves `home.answerRecord` outside the keyboard-reduced viewport. | Make Home body scrollable and scroll the answer card into view when the software keyboard appears. | Regression reproduced by a failing `isHittable` assertion before the fix. |

### Round 2
| Scope | Difference | Fix | Result |
|---|---|---|---|
| Keyboard composition | The app bottom navigation moved above the keyboard, unlike Figma `3110:34152`, and consumed answer-space height. | Hide the Home bottom navigation while the software keyboard is presented; allow interactive scroll dismissal. | Pass: final capture keeps the CTA directly above the keyboard and removes the extra navigation row. |
| Interaction regression | The CTA needed deterministic proof that it is tappable while the keyboard is present and that recording dismisses the keyboard. | Add `HomeUITests.testAnswerRecordButtonRemainsVisibleAboveKeyboard`. | Pass: two consecutive runs plus the final capture run succeeded. |

## Verification
- `HomeUITests`: 6/6 passed, including the focused keyboard regression.
- `HomeFeatureTests`: 15/15 passed.
- App build: passed for the iPhone 17 Pro simulator destination.
- Related `AppFeatureTests`: 3/4 passed; the existing account-deletion test remains blocked by a missing `pushRegistrationClient` test dependency at `SplashFeature.swift:26`, outside this UI change.

## Final assembled-screen result
- Full-frame reference/capture comparison: Figma `360×821` versus iPhone 17 Pro runtime `402×874`.
- Final runtime capture: `docs/design-qa/assets/home-answer-keyboard/2026-09-23/runtime-ios-home-answer-keyboard-final.png`
- Result: Blocked for strict assembled-screen acceptance; focused keyboard interaction passes.
- Remaining differences: the available runtime viewport does not match the authoritative Figma frame, so pixel-identical full-frame validation is not valid. The runtime fixture answer text also intentionally differs from the Figma sample copy.
