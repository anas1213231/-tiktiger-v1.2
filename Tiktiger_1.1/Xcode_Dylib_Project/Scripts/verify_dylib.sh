#!/bin/bash
set -euo pipefail

FILE="${1:-$(cd "$(dirname "$0")/.." && pwd)/BuildOutput/Tiktiger.dylib}"

if [ ! -f "$FILE" ]; then
  echo "ERROR: dylib not found: $FILE"
  exit 1
fi

for tool in file lipo otool nm; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: required Apple verification tool is missing: $tool"
    echo "Run this verifier on macOS with Xcode Command Line Tools installed."
    exit 10
  fi
done

echo "File: $FILE"
echo "Size: $(stat -f%z "$FILE" 2>/dev/null || stat -c%s "$FILE") bytes"

TYPE_OUTPUT="$(file "$FILE")"
echo "$TYPE_OUTPUT"
if [[ "$TYPE_OUTPUT" != *"Mach-O"* ]]; then
  echo "ERROR: Output is not a Mach-O binary."
  exit 2
fi

ARCHS="$(lipo -archs "$FILE")"
echo "Architectures: $ARCHS"
if [[ "$ARCHS" != *"arm64"* ]]; then
  echo "ERROR: arm64 slice is missing."
  exit 3
fi

HEADER="$(otool -hv "$FILE")"
echo
echo "Mach-O header:"
echo "$HEADER"
if [[ "$HEADER" != *"MH_DYLIB"* ]]; then
  echo "ERROR: Mach-O file type is not MH_DYLIB."
  exit 4
fi

echo
echo "Install name / linked libraries:"
otool -L "$FILE"
INSTALL_NAME="$(otool -D "$FILE" 2>/dev/null || true)"
if [[ "$INSTALL_NAME" != *"@rpath/Tiktiger.dylib"* ]]; then
  echo "ERROR: install name is not @rpath/Tiktiger.dylib."
  exit 5
fi

echo
echo "Public Tiktiger symbols:"
SYMBOLS="$(nm -gU "$FILE")"
REQUIRED_SYMBOLS='tt_(product_name|version|set_feature_enabled|validate_https_url|diagnostics_json|runtime_dylib_loaded|runtime_initialize|runtime_mark_ui_registered|runtime_mark_ui_presented|runtime_diagnostics_json)'
echo "$SYMBOLS" | grep -E "$REQUIRED_SYMBOLS" >/dev/null || {
  echo "ERROR: required public/runtime symbols are missing."
  exit 6
}
echo "$SYMBOLS" | grep -E "$REQUIRED_SYMBOLS" || true

echo
echo "Verification completed: Tiktiger.dylib is structurally valid for the configured build contract."
