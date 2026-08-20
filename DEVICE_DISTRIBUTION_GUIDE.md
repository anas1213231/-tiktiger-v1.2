# Tiktiger 1.1 — Device Distribution Guide

## Purpose

This guide explains how to sign and install the **TiktigerHost** application on a real iPhone through an authorized Apple distribution path, then collect runtime evidence from inside the app. A simulator launch is not treated as proof that the device-only `Tiktiger.dylib` was loaded or that the real device UI hierarchy was presented.

> **Current status:** the source and CI build are ready. The repository does not contain a project-specific `DEVELOPMENT_TEAM`, provisioning profile, or distribution certificate, so the final signing step must be performed by the project owner in Xcode or through the owner’s authorized Apple distribution account.

## Project identifiers

| Item | Value |
|---|---|
| Host project | `Tiktiger_1.1/TiktigerHost/TiktigerHost.xcodeproj` |
| Host scheme | `TiktigerHost` |
| Host bundle identifier | `com.ucorc.Tiktiger` |
| Dylib project | `Tiktiger_1.1/Xcode_Dylib_Project/TiktigerDylib.xcodeproj` |
| Dylib product | `Tiktiger.dylib` |
| Required dylib SHA-256 | `c74d63937efdb58421382910e0de0c5cd23dd8ee046c986f8f4698e678a31c80` |
| Deployment target | iOS 15.0 |

## Option A — Install from Xcode on an authorized Mac

1. Open `Tiktiger_1.1/TiktigerHost/TiktigerHost.xcodeproj` in Xcode on a Mac with the required Apple developer account.
2. Select the **TiktigerHost** scheme and select a connected, trusted iPhone as the run destination.
3. In the Host target’s **Signing & Capabilities** tab, enable **Automatically manage signing**, select the owner’s **Team**, and keep the bundle identifier `com.ucorc.Tiktiger`. Xcode will create or select the provisioning assets required for that team.[^1]
4. Confirm that the target’s embedded `Frameworks/Tiktiger.dylib` is the device build whose SHA-256 is the value shown above. Do not replace it with the simulator build.
5. Trust the iPhone on the Mac and on the iPhone if prompted, then select **Run**. Xcode must report a successful build and installation before the app is considered installed on the device.[^1]
6. Open Tiktiger and navigate to **Diagnostics → Runtime Verification**.

## Option B — TestFlight or App Store Connect distribution

For a broader authorized test group, archive the `TiktigerHost` scheme with the owner’s distribution team, validate the archive, and upload it to App Store Connect. After processing, add internal or external testers and install the build through TestFlight. This route requires the owner’s Apple distribution credentials and App Store Connect access; it cannot be completed from the Linux build environment alone.[^2]

## Runtime evidence collection on iPhone

After installation, perform the following actions on the iPhone:

1. Launch Tiktiger and leave it open until the main interface is visible.
2. Open **Diagnostics → Runtime Verification** and confirm that the screen displays live milestone states rather than fixed values.
3. Exercise the requested features one at a time. The Feature Runtime Audit records `action_started`, `service_called`, success or failure, errors, and timestamps without recording tokens, cookies, credentials, or private content.
4. Press **Export Runtime Report**. Use the iOS share sheet to send or save all three generated files:
   - `device-runtime.json`
   - `device-console.log`
   - `DEVICE_RUNTIME_VERIFICATION.md`
5. Send the exported files back for review. The device runtime will be marked verified only when the report contains a real `ui_presented` event confirmed by the Host view-hierarchy probe, together with the preceding runtime milestones.

## Signing and security constraints

Do not disable code signing, bypass provisioning, or install an unsigned device application. The project intentionally leaves the Apple development team unset so the owner can apply the correct team and provisioning assets. Keep the device-only dylib separate from the simulator build; the simulator guard is designed to skip loading the device dylib on iOS Simulator.

## Current CI evidence

The latest GitHub Actions run built the dylib, built the Host application for `iphoneos`, built the Host application for `iphonesimulator`, signed and installed the simulator app, launched it, and captured a screenshot. The run did **not** verify real-device dylib loading, initializer execution, core startup, registry readiness, or Host-confirmed `ui_presented`; those statuses remain pending until the exported iPhone report is available.

[^1]: [Apple Developer — Running your app in Simulator or on a device](https://developer.apple.com/documentation/xcode/running-your-app-in-simulator-or-on-a-device)
[^2]: [Apple Developer — Upload builds to App Store Connect](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
