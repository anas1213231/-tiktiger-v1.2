# Build and Verify

## Command build

```bash
cd Xcode_Dylib_Project
./BUILD_TIKTIGER.command
```

## Manual xcodebuild equivalent

```bash
xcodebuild \
  -project TiktigerDylib.xcodeproj \
  -scheme TiktigerDylib \
  -configuration Release \
  -sdk iphoneos \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  clean build
```

## Verify

```bash
Scripts/verify_dylib.sh BuildOutput/Tiktiger.dylib
```

The verifier is fail-closed on macOS and requires `file`, `lipo`, `otool`, and `nm`. It checks Mach-O, `arm64`, `MH_DYLIB`, `@rpath/Tiktiger.dylib`, and the required public symbols. The build script records:

- `BuildLogs/toolchain.txt`
- `BuildLogs/latest-build.log`
- `BuildLogs/verification.txt`
- `BuildLogs/Tiktiger.dylib.sha256`

Expected:
- Mach-O
- arm64
- dylib / `MH_DYLIB`
- iOS-linked binary
- install name `@rpath/Tiktiger.dylib`

A Linux run is not a build attempt that can produce an iOS binary. If `xcodebuild` or `xcrun` is unavailable, the script exits with `XCODE BUILD NOT VERIFIED` and no success is claimed.
