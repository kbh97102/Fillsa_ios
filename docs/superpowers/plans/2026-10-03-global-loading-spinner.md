# Global Loading Spinner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show the Figma loading ring over a black 20% full-screen dim and block all touches while the existing global loading count is positive.

**Architecture:** Keep the existing `LoadingClient` and `AppFeature.isGlobalLoading` unchanged. `AppView` owns the presentation, above the screen and common popup. A single SVG asset preserves the Figma ring; a test-only Home fixture exposes the loading state for UI verification.

**Tech Stack:** SwiftUI, TCA, XCTest/XCUITest, Xcode asset catalog.

**Spec:** [Common screen Figma reference](../../screens/common.md#figma-ui-기준).

## Global Constraints

- Figma node `2929:5969` is the visual source; ring container 120×120 and original SVG 112×112.
- User override: black 0.2 opacity instead of Figma white background; no touch events pass through.
- Keep the existing API loading scope behavior and unrelated screens unchanged.
- Run only targeted tests, not the full suite.

## Review Focus

- Loading count 0 removes the overlay (existing `AppFeatureTests.test_loadingCountControlsGlobalVisibility`).
- Loading count > 0 covers the whole screen, including status/navigation areas (UI screenshot).
- A touch on the dimmed Home quote card cannot navigate (UI test).
- Spinner stays centered on a non-360×720 device (UI test geometry).
- Source SVG is local and visually identical to Figma (asset and screenshot check).

---

### Task 1: Overlay and touch lock

**Files:** `Fiilsa/App/AppView.swift`, `Fiilsa/FiilsaApp.swift`, `Fiilsa/Assets.xcassets/global_loading_spinner.imageset/*`, `FiilsaUITests/HomeUITests.swift`.

**Interfaces:** Consume `AppFeature.State.isGlobalLoading`; produce `GlobalLoadingOverlay` as the top layer of `AppView`.

- [x] Write a UI test that launches a loading Home fixture, checks centered spinner, dim color, and that tapping the quote card does not navigate.
- [x] Run that test and confirm it fails for the missing overlay.
- [x] Add the original Figma SVG, test fixture, and minimum SwiftUI overlay with full-screen hit interception.
- [x] Run the targeted UI test and `AppFeatureTests.test_loadingCountControlsGlobalVisibility` to green.
- [x] Capture the runtime frame and record component and assembled-screen comparison in `docs/design-qa/2026-10-03-global-loading-qa.md` (final Figma full-frame acceptance remains blocked; see QA record).
