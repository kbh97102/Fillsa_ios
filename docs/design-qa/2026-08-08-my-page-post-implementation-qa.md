# My Page post-implementation design QA

- Date: 2026-08-08
- Scope: My Page only; shared bottom navigation was inspected but not modified.
- Authority: Figma is the visual source of truth.
- Figma file: `VdFocqyqTgevMVCQxwAQ2X`
- Figma frames: light member `2438:11171`, light guest `2438:11242`, light theme dialog `2438:11318`, dark member `2438:11753`, dark guest `2438:11931`, dark theme dialog `2438:11834`.
- Runtime target: iPhone 17 Pro simulator (402 x 874 pt). Figma captures are 360 x 720; this report compares fixed view dimensions and visual treatment, rather than raw pixel positions across different device widths.

## Evidence collected

Figma screenshots were requested for all six frames above. Runtime captures were made from the test-only My Page launch configuration after installing the built app:

- `/private/tmp/my-page-member-light.png`
- `/private/tmp/my-page-guest-light.png`
- `/private/tmp/my-page-member-dark.png`
- `/private/tmp/my-page-guest-dark.png`

The deterministic launch arguments are `-ui-testing-my-page` plus the member/guest and light/dark arguments. The theme dialog simulator capture could not be produced because the Xcode UI-test runner could not reliably start its cloned simulator; see Test evidence.

## Results

| Area | Figma requirement | QA result |
| --- | --- | --- |
| Member card | 320 x 80 pt, 12 pt radius, profile image and name | Pass by source/layout audit; present in light and dark runtime captures. |
| Guest card | 320 x 114 pt; 65 pt prompt plus 49 pt login action | Pass by source/layout audit; present in light and dark runtime captures. |
| Menu cards | Three 320 x 60 pt cards with 12 pt gaps | Pass by source/layout audit and runtime captures. |
| Trailing arrows | Notice and Alert only; Theme has no arrow | Light mode passes. Dark mode fails: Notice and Alert chevrons are absent in runtime captures. Theme correctly has no arrow. |
| Icons | Original Figma-derived book, profile, info, bell, theme, radio, and arrow assets | Pass for visible profile/book/info/bell/theme assets. No SF Symbols are used in My Page. |
| Light/dark surfaces | Figma light and dark card/background/icon treatments | Pass for the visible surface, profile, and menu-icon mode variants. Dark arrow is the exception above. |
| Theme dialog | 320 x 237 pt, 8 pt radius, 80% dim, 24 pt radios, 296 x 49 pt confirm button | Pass by source/layout audit. Runtime interaction test is present but post-fix execution is blocked by the simulator runner. |
| Advertising | No advertisement or reserved blank ad region | Pass. No My Page ad view or blank ad spacer is rendered. |

## Fixed values audited

`MyPageLayout` defines the Figma values directly:

- Logo: 64 x 30 pt
- Member / guest cards: 320 x 80 pt / 320 x 114 pt
- Menu: 320 x 60 pt, 12 pt spacing
- Dialog: 320 x 237 pt, 8 pt radius
- Theme options / radios: 24 pt, 30 pt vertical spacing
- Confirmation button: 296 x 49 pt

## Mismatches requiring follow-up

1. **Dark-mode Notice and Alert chevrons are invisible** — high visual-parity impact. Figma frames `2438:11753` and `2438:11931` show a visible trailing chevron for those two rows; both runtime dark captures omit it. Theme must remain arrow-free. No production change was made in this QA-only pass.

2. **Dynamic member copy differs in test capture only** — the deterministic test state uses `필사`, while Figma uses placeholder account-name copy. The production view continues to render the stored user name; this is not a layout mismatch.

## Test evidence

- `xcodebuild build -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,id=23EAFC46-77AF-49E7-A4BC-42F7DB8F2789' -quiet` passed. This compiles the Asset Catalog, including all new Figma-derived image sets.
- Initial XCUITest execution reached the test bundle. It confirmed the dark guest frame, and surfaced 1 pt accessibility-frame rounding plus inaccessible member/dialog containers; both test-only accessibility issues were corrected in commit `2ebd898`.
- Re-running XCUITest after that correction was blocked by CoreSimulator/Xcode infrastructure: `Failed to clone device named 'iPhone 17 Pro'` with `Device was allocated but was stuck in creation state`, and repeated `DebuggerLLDB.DebuggerVersionStore.StoreError error 0` launch failures. Therefore, post-fix UI-test pass status and an automated dialog screenshot are not claimed.
- A focused unit-test invocation also hit pre-existing hosted-app dependency test failures from `SplashFeature` (`settingsClient`, `notificationPermissionClient`, and `pushRegistrationClient` lack test implementations). The My Page layout test itself passed.
