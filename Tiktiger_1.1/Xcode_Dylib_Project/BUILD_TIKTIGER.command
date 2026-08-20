#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$ROOT/TiktigerDylib.xcodeproj"
DERIVED="$ROOT/Build/.DerivedData"
OUT="$ROOT/BuildOutput/Tiktiger.dylib"
LOG_DIR="$ROOT/BuildLogs"
BUILD_LOG="$LOG_DIR/latest-build.log"
VERIFY_LOG="$LOG_DIR/verification.txt"
TOOLCHAIN_LOG="$LOG_DIR/toolchain.txt"

if ! command -v xcodebuild >/dev/null 2>&1 || ! command -v xcrun >/dev/null 2>&1; then
  echo "XCODE BUILD NOT VERIFIED: xcodebuild/xcrun not found. Run this on macOS with Xcode installed."
  exit 1
fi

rm -rf "$DERIVED"
mkdir -p "$ROOT/BuildOutput" "$LOG_DIR"

{
  echo "==> xcodebuild -version"
  xcodebuild -version
  echo
  echo "==> xcrun --sdk iphoneos --show-sdk-version"
  xcrun --sdk iphoneos --show-sdk-version
} | tee "$TOOLCHAIN_LOG"

echo "==> Building Tiktiger.dylib for iPhoneOS arm64..."
if ! xcodebuild \
  -project "$PROJECT" \
  -scheme TiktigerDylib \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath "$DERIVED" \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  clean build 2>&1 | tee "$BUILD_LOG"; then
  echo "BUILD FAILED" | tee -a "$BUILD_LOG"
  exit 2
fi

if ! grep -q "BUILD SUCCEEDED" "$BUILD_LOG"; then
  echo "ERROR: xcodebuild exited without BUILD SUCCEEDED." | tee -a "$BUILD_LOG"
  exit 3
fi

if [ ! -f "$OUT" ]; then
  echo "ERROR: Build succeeded but $OUT was not created." | tee -a "$BUILD_LOG"
  echo "Searching DerivedData:"
  find "$DERIVED" -name 'Tiktiger.dylib' -print || true
  exit 4
fi

echo "==> Verifying output..."
if ! "$ROOT/Scripts/verify_dylib.sh" "$OUT" 2>&1 | tee "$VERIFY_LOG"; then
  echo "VERIFICATION FAILED" | tee -a "$VERIFY_LOG"
  exit 5
fi

if command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "$OUT" | tee "$ROOT/BuildLogs/Tiktiger.dylib.sha256"
else
  echo "WARNING: shasum is not available; SHA-256 not recorded." | tee -a "$VERIFY_LOG"
fi

echo
echo "BUILD SUCCEEDED"
echo "Your real iOS dylib is:"
echo "$OUT"
