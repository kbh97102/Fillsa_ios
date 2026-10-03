# Global Loading All-Screens Video Report Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:test-driven-development and superpowers:verification-before-completion while executing this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Demonstrate the shared Figma loading overlay on every routable iOS screen and deliver a playable HTML report with one runtime clip and screenshot per screen.

**Architecture:** `AppView` already presents one root-level overlay driven by `AppFeature.isGlobalLoading`. Add one deterministic launch-only fixture that sets `activeLoadingCount = 1` for each `AppScreen` route and main tab; do not duplicate spinner UI or alter API wrappers. Record the actual iPhone simulator display for each fixture, and list all routes, evidence, and Figma full-frame limitations in one HTML report.

**Tech Stack:** SwiftUI/TCA, XCUITest, `simctl io recordVideo`, macOS `avconvert`, static HTML.

**Spec:** [Common loading UI source and QA](../../screens/common.md#figma-ui-기준).

## Global Constraints

- Shared Figma spinner frame: file `VdFocqyqTgevMVCQxwAQ2X`, node `2929:5969`; user override black alpha 0.2 and app-wide touch lock.
- Cover all `AppScreen` cases, expanding `.main` into Home, Quote List, Calendar, My Page: 14 runtime destinations total.
- Fixture is test-only and must not call live APIs or change production routing.
- Do not run the entire test suite; use targeted UI/unit tests per the earlier request.
- Record any unreachable screen and any missing matching Figma composite as `Blocked`, not `Pass`.

## Review Focus

- Every route appears in the HTML inventory and has an actual screenshot/video or a recorded blocker.
- Fixture screen identity is checked, not merely the presence of a spinner over the wrong screen.
- The root overlay remains topmost across main tabs, standalone routes, and common popup content.
- User taps do not reach a covered screen; the existing Home touch test remains green.
- Video links decode and load from the HTML file via relative paths.

---

### Task 1: Deterministic route coverage

**Files:** `Fiilsa/FiilsaApp.swift`, `FiilsaUITests/GlobalLoadingUITests.swift`, `docs/screens/common.md`.

**Interfaces:** Launch arg `-ui-testing-global-loading-screen=<route>` initializes the named App route with `activeLoadingCount = 1`; the existing `-ui-testing-global-loading` guard suppresses unrelated startup subscriptions.

- [x] Add one UI test iterating all 14 route names and checking the spinner plus a screen-specific marker.
- [x] Run it red; confirm failure due missing route fixture, not a test setup error.
- [x] Implement the smallest launch fixture using existing sample data and loaded feature states.
- [x] Run the targeted route test, prior Home touch test, and AppFeature loading-count test.

### Task 2: Runtime evidence and report

**Files:** `docs/design-qa/2026-10-03-global-loading-video-report.html`, `docs/design-qa/2026-10-03-global-loading-qa.md`, `docs/design-qa/2026-10-03-global-loading-*.png`, `docs/design-qa/2026-10-03-global-loading-*.mp4`.

**Interfaces:** One screenshot and one short H.264 MP4 for each of the 14 route names, referenced by relative paths from the report.

- [x] Launch each test fixture on the booted iPhone simulator and capture a full-screen PNG and short MP4.
- [x] Inspect poster frames and movie metadata; retry any capture showing the wrong screen or missing spinner.
- [x] Expand the HTML with a screen index and one section per route (shared Figma spinner source, runtime poster/video, result/blocker).
- [x] Validate all relative assets, report route count, and QA limitations without claiming unsupported full-frame Figma acceptance.

### Boundary discovered during recording

- [x] The Typing system keyboard sat above the app-root overlay. Added a failing UI check, dismissed active input when global loading starts, prevented Typing auto-focus during loading, and recaptured Typing media.
- [x] Confirmed Home's focused answer editor closes on loading and Typing still opens its keyboard without loading.
