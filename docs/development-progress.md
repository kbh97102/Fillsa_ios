# Development Progress

## Current Phase

Phase 0: Project Foundation

## Phase Checklist

### Phase 0. Project Foundation

- [x] Add TCA package dependency.
- [x] Resolve Swift Package dependencies.
- [x] Create foundation folder structure.
- [x] Create `AppFeature`.
- [x] Create `AppView`.
- [x] Create tab route model for Home/List/Calendar/My page.
- [x] Replace default `ContentView` entry with the app shell.
- [x] Add initial Android-derived color tokens.
- [x] Add initial Android-derived typography tokens.
- [x] Build generic iOS target successfully.

Build command used:

```bash
xcodebuild -project Fiilsa.xcodeproj -scheme Fiilsa -configuration Debug -destination generic/platform=iOS -derivedDataPath /private/tmp/FiilsaDerivedData CODE_SIGNING_ALLOWED=NO -skipMacroValidation build
```

Result:

```text
BUILD SUCCEEDED
```

Notes:

- TCA resolved to `swift-composable-architecture` 1.26.0.
- The first CLI build requires `-skipMacroValidation` unless Xcode has already trusted the package macros.
- The current UI is only a temporary routing shell. Android-parity screen UI starts after common UI and screen-specific implementation phases.

## Next Phase

Phase 1: Core Domain And Data Contracts

Planned next tasks:

- Define response/request models from Android domain objects.
- Define repository protocols.
- Add endpoint constants matching Android `ApiEndPoint.kt`.
- Build a URLSession-backed API client skeleton.
- Add token injection and refresh design, without wiring social login SDKs yet.
