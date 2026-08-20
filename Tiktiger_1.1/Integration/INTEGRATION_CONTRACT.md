# Integration Contract

This dylib is a reusable native library.

It does not include a third-party app injection mechanism.

For an authorized host application:

1. Define a small host adapter layer.
2. Keep host-specific classes out of the core.
3. Expose only the minimum public functions/classes needed.
4. Configure entitlements on the HOST target, not arbitrarily on the dylib.
5. Sign the final host application using the owner's Apple signing setup.

## Entitlements

Add only capabilities actually required by the host app.

Examples may include capabilities associated with:
- Photos usage descriptions in Info.plist
- LocalAuthentication usage description where applicable

Do not add arbitrary entitlements simply to make a signing error disappear.
