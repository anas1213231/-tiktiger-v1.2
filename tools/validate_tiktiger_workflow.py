from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
workflow = root / '.github/workflows/build-tiktiger-ios.yml'
project_root = root / 'Tiktiger_1.1/Xcode_Dylib_Project'
text = workflow.read_text(encoding='utf-8')
required = {
    'macos_runner': 'runs-on: macos-14' in text,
    'sw_vers': 'sw_vers' in text,
    'xcode_version': 'xcodebuild -version' in text,
    'xcode_select': 'xcode-select -p' in text,
    'ios_sdk': 'xcrun --sdk iphoneos --show-sdk-version' in text,
    'simulator_sdk': 'xcrun --sdk iphonesimulator --show-sdk-version' in text and '-sdk iphonesimulator' in text,
    'project_path': 'Tiktiger_1.1/Xcode_Dylib_Project' in text and 'TiktigerDylib.xcodeproj' in text,
    'scheme': '-scheme TiktigerDylib' in text,
    'release': '-configuration Release' in text,
    'iphoneos': '-sdk iphoneos' in text,
    'arm64': 'ARCHS=arm64' in text,
    'no_signing': 'CODE_SIGNING_ALLOWED=NO' in text and 'CODE_SIGNING_REQUIRED=NO' in text,
    'build_log': 'build.log' in text,
    'file': 'file "$OUTPUT"' in text,
    'lipo': 'lipo -info "$OUTPUT"' in text and 'lipo -archs "$OUTPUT"' in text and "test \"$ARCH_LIST\" = 'arm64'" in text,
    'otool_header': 'otool -hv "$OUTPUT"' in text,
    'otool_dependencies': 'otool -L "$OUTPUT"' in text,
    'nm': 'nm -gU "$OUTPUT"' in text and '[[:space:]_]' in text,
    'sha256': 'shasum -a 256 "$OUTPUT"' in text,
    'symbol_status_table': 'SYMBOL_STATUS_FILE' in text and 'for symbol in' in text and ': FOUND' in text and ': FAILED' in text,
    'mach_o_gate': "grep -Eiq 'Mach-O'" in text,
    'arm64_gate': "grep -Eiq 'arm64'" in text,
    'dylib_gate': "grep -Eiq 'MH_DYLIB'" in text,
    'install_name_gate': "grep -Fq '@rpath/Tiktiger.dylib'" in text,
    'build_succeeded_gate': "grep -q 'BUILD SUCCEEDED'" in text,
    'artifact_dylib': 'Tiktiger_1.1/Xcode_Dylib_Project/BuildOutput/Tiktiger.dylib' in text,
    'artifact_build_log': '\n            build.log' in text,
    'artifact_verification': '\n            verification.txt' in text,
    'checkout': 'actions/checkout@v4' in text,
    'legacy_guard': 'python3 tools/validate_legacy_active_references.py' in text,
    'upload': 'actions/upload-artifact@v4' in text,
    'no_build_ignore': 'xcodebuild' in text and not re.search(r'xcodebuild[^\n]*\|\|\s*true', text),
    'source_project_exists': (project_root / 'TiktigerDylib.xcodeproj').exists(),
    'features_preserved': (project_root / 'TiktigerDylib/src/TiktigerFeatures.c').exists(),
    'host_project_path': ('Tiktiger_1.1/TiktigerHost' in text and 'HOST_PROJECT="$HOST_DIR/TiktigerHost.xcodeproj"' in text),
    'host_scheme': '-scheme TiktigerHost' in text and "-destination 'generic/platform=iOS'" in text,
    'host_build_log': 'host_build.log' in text and 'grep -q' in text,
    'wire_real_dylib': 'cp -f "$OUTPUT" "$RUNTIME_DIR/Tiktiger.dylib"' in text,
    'host_embedding_gate': 'test -f "$HOST_APP/Frameworks/Tiktiger.dylib"' in text,
    'host_app_artifact': 'host_app/TiktigerHost.app' in text,
    'host_runtime_artifact': 'host_runtime_embedding.txt' in text,
    'simulator_build': 'Build TiktigerHost for iphonesimulator without device dylib' in text and 'simulator_build.log' in text,
    'simulator_runtime_guard': 'targetEnvironment(simulator)' in (root / 'Tiktiger_1.1/TiktigerHost/TigerHost/TiktigerRuntimeCoordinator.swift').read_text(encoding='utf-8'),
    'runtime_not_claimed_by_build': 'Runtime milestones: NOT CAPTURED in build-only job' in text,
    'symbol_status_artifact': 'symbol_status.txt' in text,
}
for name, ok in required.items():
    print(f'{name}: ' + ('OK' if ok else 'MISSING'))
if not all(required.values()):
    raise SystemExit(1)
print('workflow_static_validation: PASS')
