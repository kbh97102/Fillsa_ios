# 2026-10-07 QA Five Issues Implementation Plan

> **For agentic workers:** Work through the five issue branches in separate Git worktrees, using a failing test before each production fix. Merge verified branches into `release` sequentially and record actual runtime evidence.

**Goal:** Resolve the five 2026-10-07 Notion QA reports in iOS and publish a local HTML report with playable verification videos.

**Architecture:** Preserve TCA feature state/action/effect boundaries and Clean Architecture repository/use case layers. UI is defined by the referenced Figma frames; domain API behavior is defined by the Notion v2 guide. Keep each issue in a separate worktree and integrate after focused verification.

**Tech Stack:** SwiftUI, TCA, Alamofire, XCTest/XCUITest, Xcode simulator, HTML5 video.

**Spec:** [Issue index](../../screens/2026-10-07-qa-issues.md) and its five linked screen documents.

## Global Constraints

- Preserve the unrelated Xcode user state file in the primary checkout.
- Follow `docs/ui-redesign-workflow.md` for any UI change; verify component and assembled screen against Figma.
- Preserve Android independence for all UI decisions.
- The Notion `Device` field is blank; conclusions about the reported device require runtime evidence.
- Do not claim a performance root cause without client and server timing evidence.

## Review Focus

- Answer save succeeds only after the server response and survives app restart.
- Calendar actions change the selected day's data, not another day's data.
- Image conversion handles JPEG, PNG, HEIC, orientation, and the server's exact size limit.
- Image popup bounds remain stable across source image aspect ratios.
- Loading ends after each operation; network errors do not leave an indefinite overlay.

---

### Task 1: Answer persistence worktree

**Files:** Home/Calendar response models, endpoint, repository, use case, features, question views, focused tests, screen plans and QA records.

- [ ] Add a failing test for Home answer save and Calendar answer callback, including server failure and reload.
- [ ] Implement the v2 answer request/response and state synchronization with the smallest needed surface.
- [ ] Run focused tests and the full test suite; capture Home and Calendar video states.
- [ ] Validate answer UI and toast against Figma and record results.

### Task 2: Calendar quote actions worktree

**Files:** Calendar feature/view/action row, monthly model, focused tests, screen plan and QA record.

- [ ] Add a failing test for each quote action on the selected completed date.
- [ ] Connect existing copy, share, like and image behavior without adding a new navigation path absent from Figma.
- [ ] Run focused tests and the full suite; record the selected-date interaction video and Figma comparison.

### Task 3: Image size worktree

**Files:** Home photo preparation and upload boundary, focused conversion tests, screen plan and QA record.

- [ ] Add failing tests for oversized and mismatched-format image data.
- [ ] Convert/compress before upload to the confirmed server limit and clean up temporary files.
- [ ] Run image tests and the full suite; capture upload success/failure evidence.

### Task 4: Image popup worktree

**Files:** Home image dialog layout, image-present UI test, screen plan and QA record.

- [ ] Reproduce the image-dependent bounds change in an image-present UI test.
- [ ] Constrain the dialog shell to the Figma size relationship, then crop image content within it.
- [ ] Run UI and full tests; capture wide/tall image videos and full-frame Figma comparisons.

### Task 5: Response latency worktree

**Files:** Home loading/request path, timing instrumentation or tests, screen plan and QA record.

- [ ] Record client stage timings and request counts for the reported flows before changing behavior.
- [ ] Address the measured client cause; use the documented weekly API for repeated Home date lookups if measurement confirms that path.
- [ ] Compare before/after under the same conditions and capture loading video. Separate any server-side unknowns.

### Task 6: Integration and report

**Files:** `docs/design-qa/2026-10-07-qa-report.html`, linked MP4/PNG evidence, issue documents.

- [ ] Merge the five verified branches into `release` in dependency order.
- [ ] Run the complete test suite and affected runtime scenarios on the integrated build.
- [ ] Produce a self-contained local HTML report with issue status, root cause, fix, test output, Figma comparison, and playable video for each issue.
- [ ] Verify every media path and video playback locally; record any unavailable verification as blocked.
