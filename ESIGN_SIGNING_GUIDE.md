# Tiktiger 1.1 — eSign Re-signing Guide

## Package and identity

Use the artifact named `TiktigerHost-unsigned-signable.ipa`. It is an unsigned/signable IPA produced from the verified `iphoneos` Host build. The application identity must remain:

| Item | Required value |
|---|---|
| Host Bundle Identifier | `com.ucorc.Tiktiger` |
| Embedded Core Bundle Identifier | `com.ucorc.TiktigerCore` |
| Embedded dylib path | `Payload/TiktigerHost.app/Frameworks/Tiktiger.dylib` |
| Dylib install name | `@rpath/Tiktiger.dylib` |
| Host runtime path | `@executable_path/Frameworks` |
| Pre-signing dylib SHA-256 | `c74d63937efdb58421382910e0de0c5cd23dd8ee046c986f8f4698e678a31c80` |
| Required special entitlements | None in the project entitlement file |

## eSign procedure

Import the unsigned IPA into eSign and select the owner’s authorized signing certificate and provisioning profile. The provisioning profile must be valid for the exact App ID `com.ucorc.Tiktiger`; do not change the Bundle Identifier to a wildcard or to another product name. If eSign exposes an option to sign embedded frameworks or dynamic libraries, keep recursive signing enabled so the Host executable, `TigerCore.framework`, and `Frameworks/Tiktiger.dylib` are signed consistently.

Do not add capabilities that are not present in the project. The app’s Photos Add Only and Face ID permission strings are already present in `Info.plist`; they are usage descriptions, not extra entitlements. Do not add push notifications, iCloud, App Groups, keychain groups, or other capabilities unless the owner explicitly creates and authorizes them in Apple Developer for this App ID.

After signing, install the resulting IPA on the authorized iPhone. A code signature is expected to change the final file bytes, so the supplied SHA-256 is the **pre-signing identity of the approved dylib artifact**. Do not rebuild or replace the dylib before signing. The path and install name must remain unchanged.

## Post-install Runtime verification

Open Tiktiger, go to **Diagnostics → Runtime Verification**, and wait for the main interface to appear. Exercise the requested existing features only, then press **Export Runtime Report**. Send these three files without editing them:

- `device-runtime.json`
- `device-console.log`
- `DEVICE_RUNTIME_VERIFICATION.md`

The runtime sequence is accepted only when the report contains real timestamped lines for `dylib_loaded`, `initializer_executed`, `core_started`, `feature_registry_ready`, `ui_registered`, and `ui_presented`. The final `ui_presented` event must be backed by the Host view-hierarchy confirmation; the presence of a dylib in the IPA is not sufficient.

## Safety boundary

Do not provide Apple ID passwords, two-factor codes, private keys, or certificate passwords in chat. Use only the owner’s authorized signing materials inside eSign. No code-signing bypass or fake signature is permitted.
