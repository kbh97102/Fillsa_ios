# AGENTS.md

## Project Context

- This repository is the iOS conversion of the existing Android project.
- The Android source project is located at `/Users/gangbohun/AndroidStudioProjects/Fillsa`.
- Use the Android project as the source of truth for existing behavior, screens, flows, copy, and visual design.

## Architecture

- Follow MVI and Clean Architecture throughout the iOS project.
- For the MVI implementation, follow The Composable Architecture (TCA) style.
- Keep feature state, actions, reducers, effects, and view bindings separated in a TCA-consistent way.
- Keep domain, data, and presentation responsibilities clearly separated.

## Android Parity Rules

- The iOS app must match the Android app's design exactly unless the user explicitly approves a change.
- The iOS app must provide only the features already provided by the Android app.
- Do not add extra screens, UI elements, interactions, features, states, copy, animations, or shortcuts without explicit user approval.
- When implementation details are unclear, inspect the Android project first instead of inventing behavior.

## Planning Documents

- The top-level planning document is `docs/planning.md`.
- Screen-specific planning documents live in `docs/screens/`.
- Android source analysis is documented in `docs/android-analysis.md`.
- iOS development planning is documented in `docs/ios-development-plan.md`.
- Development progress is tracked in `docs/development-progress.md`.
- Organize planning/specification documents by screen.
- Before implementing or modifying a screen, always find and consult that screen's planning document.
- If the relevant planning document does not exist, create or update it before implementing the screen.
- Planning documents should capture the Android reference behavior, UI structure, data displayed, navigation, and edge cases for that screen.

## Workflow Expectations

- Before building an iOS screen, inspect the corresponding Android implementation and assets.
- Preserve naming, copy, layout intent, and user-visible behavior from Android wherever possible.
- Ask for confirmation before making product decisions that are not directly supported by the Android implementation or the screen planning document.
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
