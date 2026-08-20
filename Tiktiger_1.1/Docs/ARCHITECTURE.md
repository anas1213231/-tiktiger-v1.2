# Architecture

## Layer 1 — Public API

Public symbols should live in:

`TiktigerDylib/include/`

Keep the exported surface minimal.

## Layer 2 — Core

Core should contain:
- configuration
- feature state
- logger
- diagnostics
- shared errors

## Layer 3 — Services

Business logic must not live in UI.

Suggested boundaries:
- Download
- Audio
- Photos
- Authentication
- Translation
- Appearance

## Layer 4 — Host Integration

Host-specific glue must be isolated from reusable library logic. The handoff includes `Integration/TiktigerHostAdapter.h` and `.m` as a small Objective-C example that wraps URL validation, feature state, safe filenames, download stages, and diagnostics.

The Adapter is where SwiftUI, URLSession, Photos, AVFoundation, LocalAuthentication, and the authorized host API are coordinated. Do not couple Tiktiger core logic to one ViewController/View, and do not place credentials or private endpoints inside the dylib.

## Threading

- UI: main thread / MainActor
- network/download: background async tasks
- audio conversion: background
- Photos save completion: marshal results back to UI safely

## Security

- no embedded credentials
- no arbitrary entitlement escalation
- no hard-coded private endpoints
- no hidden remote command execution
- sanitize downloaded filenames and paths
