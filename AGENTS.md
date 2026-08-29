# AGENTS.md

## Project Context

- This repository is the iOS conversion of the existing Android project.
- Figma is the single source of truth for every UI decision: layout, copy, visual assets, component hierarchy, supported visual states, and UI interactions represented in the design.
- Do not compare an iOS UI implementation with Android or use Android code/assets as a UI decision or validation source.

## Architecture

- Follow MVI and Clean Architecture throughout the iOS project.
- For the MVI implementation, follow The Composable Architecture (TCA) style.
- Keep feature state, actions, reducers, effects, and view bindings separated in a TCA-consistent way.
- Keep domain, data, and presentation responsibilities clearly separated.

## Figma UI Source-Of-Truth Rules

- Every UI change must match its referenced Figma design exactly unless the user explicitly approves a change.
- Do not add UI elements, visual states, copy, animations, interactions, or shortcuts that are absent from the target Figma design.
- A Figma file URL and target frame/node ID are mandatory before a UI task begins. If either is unavailable, stop and request it; do not begin implementation from an assumption.
- The required UI implementation and validation procedure is in `docs/ui-redesign-workflow.md`. Read that document in full before any UI investigation, implementation, review, or validation work.
- This rule applies to every agent, including a delegated/sub-agent. A parent agent must include the target screen, Figma URL, frame/node ID, and assigned component area in each delegated UI task.

## Planning Documents

- The top-level planning document is `docs/planning.md`.
- Screen-specific planning documents live in `docs/screens/`.
- The UI redesign procedure and QA record format are documented in `docs/ui-redesign-workflow.md`.
- iOS development planning is documented in `docs/ios-development-plan.md`.
- TCA and SwiftUI lifecycle guidance for Android developers is documented in `docs/tca-guide.md`.
- The TCA learning entry point is `docs/tca-learning-roadmap.md`, with basic and advanced guides in `docs/tca-basic-guide.md` and `docs/tca-advanced-guide.md`.
- Development progress is tracked in `docs/development-progress.md`.
- Organize planning/specification documents by screen.
- Before implementing or modifying a screen, always find and consult that screen's planning document.
- If the relevant planning document does not exist, create or update it before implementing the screen.
- Before a UI change, update the relevant screen planning document with the Figma source URL, target frame/node ID, component breakdown, target states, and a link to its QA record.
- Planning documents should capture the Figma reference structure, displayed data, navigation/interactions represented in Figma, and visual edge cases for that screen.

## Workflow Expectations

- Follow the component-first Figma workflow, including its maximum five validation-and-correction rounds, for every UI change.
- Do not mark a UI task complete until every affected component and the assembled screen pass the final Figma validation round with recorded evidence.
- Ask for confirmation before making product decisions that are not directly supported by the target Figma design or the screen planning document.
- Keep changes scoped to the requested screen or feature.

## Collaboration And Explanation Style

- The user knows Android development but has no Swift or iOS background.
- When introducing or using an iOS/Swift concept, explain it in beginner-friendly terms.
- Prefer Android comparisons when explaining iOS concepts:
  - TCA feature/reducer/state/action vs Android ViewModel/MVI state/event.
  - SwiftUI View vs Jetpack Compose UI.
  - `@Dependency` vs Hilt dependency injection.
  - UserDefaults vs Android DataStore for lightweight settings.
  - Keychain vs secure token storage.
  - Bundle resources vs Android `res`.
  - Swift Package Manager vs Gradle dependencies.
- During implementation, explain:
  - Why the chosen iOS/Swift tool or pattern is being used.
  - What practical alternatives exist.
  - What tradeoffs those alternatives have.
  - Which Android concept it is closest to.
- After meaningful feature work, briefly summarize the iOS/Swift basics involved so the user can build context over time.
- Avoid assuming the user knows Swift syntax, iOS app lifecycle, Xcode behavior, simulator behavior, package resolution, resource bundling, or Apple permission flows.
