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

Host-specific glue must be isolated from reusable library logic. The handoff includes `Integration/TiktigerHostAdapter.h` and `.m` as a small Objective-C contract that wraps URL validation, feature state, safe filenames, download stages, runtime milestones, and diagnostics.

The current `TigerHost` target also contains `TiktigerRuntimeCoordinator.swift`. Its verified call chain is designed as:

```text
TigerHost ContentView.onAppear
  -> TiktigerRuntimeCoordinator.start()
  -> dlopen(Tiktiger.dylib, RTLD_NOW | RTLD_GLOBAL)
  -> dlsym(tt_runtime_initialize)
  -> dlsym(tt_feature_count / tt_feature_key_at)
  -> tt_runtime_mark_ui_registered()
  -> ContentView presentation
  -> tt_runtime_mark_ui_presented()
```

The Host PBX target embeds the real binary at `TigerHost/Runtime/Tiktiger.dylib` into `Frameworks` with `CodeSignOnCopy`. The source tree intentionally does not contain a fake binary. A real iOS arm64 binary and matching signing setup are required before Host build/runtime verification.

The Adapter remains the Objective-C option for hosts that prefer a typed bridge. The Adapter is where SwiftUI, URLSession, Photos, AVFoundation, LocalAuthentication, and the authorized host API are coordinated. Do not couple Tiktiger core logic to one ViewController/View, and do not place credentials or private endpoints inside the dylib.

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
