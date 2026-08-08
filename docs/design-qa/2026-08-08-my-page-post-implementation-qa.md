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
| Trailing arrows | Notice and Alert only; Theme has no arrow | Pass after remediation. The dark Notice and Alert chevrons render visibly; Theme remains arrow-free. |
| Icons | Original Figma-derived book, profile, info, bell, theme, radio, and arrow assets | Pass for visible profile/book/info/bell/theme assets. No SF Symbols are used in My Page. |
| Light/dark surfaces | Figma light and dark card/background/icon treatments | Pass for the visible surface, profile, menu-icon, and chevron mode variants. |
| Theme dialog | 320 x 237 pt, 8 pt radius, 80% dim, 24 pt radios, 296 x 49 pt confirm button | Pass by source/layout audit and automated show/select/confirm test. |
| Advertising | No advertisement or reserved blank ad region | Pass. No My Page ad view or blank ad spacer is rendered. |

## Fixed values audited

`MyPageLayout` defines the Figma values directly:

- Logo: 64 x 30 pt
- Member / guest cards: 320 x 80 pt / 320 x 114 pt
- Menu: 320 x 60 pt, 12 pt spacing
- Dialog: 320 x 237 pt, 8 pt radius
- Theme options / radios: 24 pt, 30 pt vertical spacing
- Confirmation button: 296 x 49 pt

## Remediation and remaining differences

1. **Dark-mode chevrons remediated** — Figma design context reveals two original, overlapping arrow layers in dark frames: a `#424242` base plus a white overlay. The existing catalog included only the base, which matched the `#424242` card background and became invisible. The exact white Figma vector is now included as `my_page_arrow_dark_overlay` and overlaid only in dark mode. Runtime capture: `/private/tmp/my-page-member-dark-arrow-fixed.png`.

2. **Dynamic member copy differs in test capture only** — the deterministic test state uses `필사`, while Figma uses placeholder account-name copy. The production view continues to render the stored user name; this is not a layout mismatch.

## Test evidence

- `xcodebuild build-for-testing -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,id=23EAFC46-77AF-49E7-A4BC-42F7DB8F2789' -quiet` passed. This compiles the Asset Catalog, including the new white Figma arrow overlay.
- `xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,id=89410CC6-A661-4252-B810-0E54DE5FB620' -only-testing:FiilsaUITests/MyPageUITests -quiet` passed: five My Page UI tests, including the light/dark member/guest frames and theme dialog show/select/confirm flow.
- Xcode emitted non-fatal CoreSimulator clone-launch warnings (`DebuggerLLDB.DebuggerVersionStore.StoreError error 0` and one clone `ipc/mig server died`), but a second clone completed all tests with exit code 0.
- Evidence after remediation: light member `/private/tmp/my-page-member-light-arrow-fixed.png`, dark member `/private/tmp/my-page-member-dark-arrow-fixed.png`, and UI-test dialog attachment `/private/tmp/my-page-theme-attachment/14F57974-E9D7-493F-A97F-17367DDC7479.png`.
