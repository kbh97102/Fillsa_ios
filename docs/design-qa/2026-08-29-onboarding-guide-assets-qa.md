# Onboarding Guide Assets Figma UI QA

## Reference

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3088-30089
- Target frames/nodes: `0.onboarding_new_01` (`3088:30089`) / `app_visual` (`3110:31993`); `0.onboarding_new_02` (`3088:30215`) / `app_visual` (`3110:32702`); `0.onboarding_new_03` (`3088:30412`) / `app_visual` (`3110:33500`)
- Reference image(s): exports bundled in `Fiilsa/Assets.xcassets/onboarding_guide_{home,list,calendar}.imageset/`
- Runtime target: iOS build, light mode, guide pages 1–3

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Home guide image | `3110:31993` | page 1, light | bundled Figma PNG; asset compilation passed |
| List guide image | `3110:32702` | page 2, light | bundled Figma PNG; asset compilation passed |
| Calendar guide image | `3110:33500` | page 3, light | bundled Figma PNG; asset compilation passed |

## Validation rounds

### Round 1

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Guide illustration assets | Existing hand-built placeholders differ from Figma `app_visual` exports. | Replaced with direct Figma PNG exports registered as both `@2x` and `@3x`, preserving the Figma display sizes: 288×430, 288×430, 280×430 points. `xcrun actool` completed with exit code 0. | Pass |

## Final assembled-screen result

- Final runtime capture: not captured — CoreSimulatorService is unavailable in this environment.
- Result: asset component pass; assembled-screen visual validation blocked before round 2.
- Remaining differences: assembled runtime comparison to the Figma reference has not been captured. The temporary-package build also stopped before app sources because SwiftSyntax macro modules were unresolved.
