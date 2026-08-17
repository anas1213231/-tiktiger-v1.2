Tiktiger final pre-push audit
Mon Aug 17 19:47:41 UTC 2026

privacy_verifier_exit=0
# Previous repo privacy merge verification

Errors: 0

- None

git_diff_check_exit=0

assets:
-rw-r--r-- 1 ubuntu ubuntu 144K Aug 17 19:44 assets/tiktiger-developer-cover.jpg
-rw-r--r-- 1 ubuntu ubuntu 565K Aug 17 19:44 assets/tiktiger-download.png
-rw-r--r-- 1 ubuntu ubuntu 587K Aug 17 19:44 assets/tiktiger-main.png

make resource line:
Tiktiger_RESOURCE_FILES = assets/tiktiger-main.png assets/tiktiger-download.png assets/tiktiger-developer-cover.jpg

workflow artifact checks:
1:name: Build Tiktiger dylib
59:      - name: Extract and verify Tiktiger.dylib
64:          DYLIB="$(find .theos -type f -name 'Tiktiger.dylib' -print -quit)"
66:          cp "$DYLIB" output/Tiktiger.dylib
67:          file output/Tiktiger.dylib | tee BuildLogs/file.txt
68:          otool -L output/Tiktiger.dylib | tee BuildLogs/otool-L.txt
69:          shasum -a 256 output/Tiktiger.dylib | tee BuildLogs/sha256.txt
70:          test "$(file output/Tiktiger.dylib | grep -c 'Mach-O')" -eq 1
75:        uses: actions/upload-artifact@v4
77:          name: Tiktiger-dylib-${{ github.sha }}
80:            output/Tiktiger.dylib
