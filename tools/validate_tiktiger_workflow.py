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
    'mach_o_gate': "grep -Eiq 'Mach-O'" in text,
    'arm64_gate': "grep -Eiq 'arm64'" in text,
    'dylib_gate': "grep -Eiq 'MH_DYLIB'" in text,
    'install_name_gate': "grep -Fq '@rpath/Tiktiger.dylib'" in text,
    'build_succeeded_gate': "grep -q 'BUILD SUCCEEDED'" in text,
    'artifact_dylib': 'Tiktiger_1.1/Xcode_Dylib_Project/BuildOutput/Tiktiger.dylib' in text,
    'artifact_build_log': '\n            build.log' in text,
    'artifact_verification': '\n            verification.txt' in text,
    'checkout': 'actions/checkout@v4' in text,
    'upload': 'actions/upload-artifact@v4' in text,
    'no_build_ignore': 'xcodebuild' in text and not re.search(r'xcodebuild[^\n]*\|\|\s*true', text),
    'source_project_exists': (project_root / 'TiktigerDylib.xcodeproj').exists(),
    'features_preserved': (project_root / 'TiktigerDylib/src/TiktigerFeatures.c').exists(),
}
for name, ok in required.items():
    print(f'{name}: ' + ('OK' if ok else 'MISSING'))
if not all(required.values()):
    raise SystemExit(1)
print('workflow_static_validation: PASS')
