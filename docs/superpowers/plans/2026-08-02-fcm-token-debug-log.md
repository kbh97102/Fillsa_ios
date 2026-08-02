# FCM Token Debug Log Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Print the complete FCM registration token in Xcode only for Debug builds.

**Architecture:** Reuse the existing `MessagingDelegate` callback in `AppDelegate`. Keep the FCM event publication unchanged; replace its masked debug output with one stable, copyable message.

**Tech Stack:** Swift, FirebaseMessaging, Xcode console logging.

## Global Constraints

- The app must retain existing FCM token event and server synchronization behavior.
- Token logging must be compiled only when `DEBUG` is defined.
- Release builds must not print an FCM token.

---

### Task 1: Print the received Debug token

**Files:**
- Modify: `Fiilsa/AppDelegate.swift:35-38`
- Test: Debug simulator build

**Interfaces:**
- Consumes: `MessagingDelegate.messaging(_:didReceiveRegistrationToken:)` and its non-empty `fcmToken: String`.
- Produces: Xcode console line `[FCM] registration token: <fcmToken>` in Debug builds.

- [ ] **Step 1: Confirm the existing callback only accepts usable tokens**

Verify this guard remains before every side effect:

```swift
guard let fcmToken, !fcmToken.isEmpty else { return }
```

- [ ] **Step 2: Replace the masked Debug log**

Inside the existing `#if DEBUG` section, use:

```swift
print("[FCM] registration token: \(fcmToken)")
```

Do not modify this preceding event publication:

```swift
FCMTokenEventCenter.post(token: fcmToken)
```

- [ ] **Step 3: Build the Debug app**

Run:

```bash
xcodebuild -quiet -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,id=89410CC6-A661-4252-B810-0E54DE5FB620' CODE_SIGNING_ALLOWED=NO build
```

Expected: build succeeds. A physical iPhone is required to observe the APNs-backed FCM token in the console.
