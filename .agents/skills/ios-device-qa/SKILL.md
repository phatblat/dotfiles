---
name: ios-device-qa
description: Drive QA of a SwiftUI app on a real iPhone over USB - screenshot, read the accessibility tree, inspect @Observable state, tap, swipe, and type through an HTTP bridge embedded in the app under test. Use when asked to test an iOS app on a physical device, find bugs on the device, or expose a connected iPhone to a remote agent over Tailscale. Requires the ios-agent-qa runtime; not for simulator or XCTest work.
---

# iOS Device QA

Drives a real iPhone over the USB CoreDevice tunnel. The app under test embeds a
loopback-only `StateServer`; a Mac-side daemon proxies to it and mints
capability-scoped tokens. No simulator, no XCTest, no WebDriverAgent.

## Runtime

The runtime lives at `~/dev/apple/ios-agent-qa` — daemon, Swift/ObjC bridge
templates, and the swift-syntax accessor codegen. **Read that repo's `README.md`
first**; it is the source of truth for setup, capability tiers, and the Tailscale
ACL shape. Do not work from memory.

Prerequisites: macOS with Xcode (`devicectl`, `swift` >= 5.9), bun >= 1.1, an
iPhone paired over USB, and app source containing at least one `@Observable`
class.

## Loop

1. **Codegen.** Walk the app source for `@Observable` classes, then
   `bun run gen-accessors`. First run builds swift-syntax (2-5 min); later runs
   are content-hash cached.
2. **Bridge.** Add the `DebugBridge` SPM dependency, gated
   `.when(configuration: .debug)`, and wire it from the `@main` App init inside
   `#if DEBUG`. Build and install to the device; launch via `devicectl`.
3. **Daemon.** Start `bin/ios-agent-qa-daemon`. It takes an exclusive flock, then
   immediately rotates the app's boot token so anything scraping `os_log` holds a
   dead credential within seconds.
4. **Drive.** Each iteration: `GET /screenshot` → `GET /elements` →
   `GET /state/snapshot` → decide → `POST /session/acquire` → act via `/tap`,
   `/swipe`, `/type`, or a `/state/<key>` write → re-screenshot → compare →
   `POST /session/release`.

Record a finding whenever observed behavior diverges from the intent of the
screen you are on. Screenshot before and after every state-changing action, so
the report carries evidence rather than assertion.

## Rules

- **Never bind the StateServer to anything but loopback.** Tailnet ingress is the
  daemon's job, and only the daemon validates identity against `tailscaled`.
- **Demo mode overrides everything.** If the user asks for a demo, drive every
  action through visible UI and never use `/state/*` writes to skip steps.
- **Release safety is structural**, not procedural: the SPM package declares
  debug-only targets and CI runs `swift build -c release`. Do not rely on manual
  cleanup to keep the bridge out of a shipping build.

## Failure modes

| Symptom | Cause | Action |
|---|---|---|
| connection refused to daemon | daemon died | Re-run; the spawn lock fails closed |
| `403 identity_not_allowed` | identity not allowlisted | `bin/ios-agent-qa-mint grant --remote <id>` |
| `409 schema_mismatch` | snapshot from an older build | Discard and re-capture |
| `503 device_disconnected` | USB tunnel dropped | Reconnect; daemon retries within 30s |
| `429 rate_limited` | >10 mints/min for one identity | Wait 60s; check the audit log |
