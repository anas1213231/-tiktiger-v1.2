from collections import Counter
from pathlib import Path
import json
import re

script_path = Path(__file__).resolve()
repo_root = script_path.parent.parent
package_root = repo_root if (repo_root / '01_TigerIOSStarter').exists() else None
if package_root is not None:
    HOST = package_root / '01_TigerIOSStarter'
    HANDOFF = package_root / '02_Tiktiger_Developer_Handoff'
elif (repo_root / 'Tiktiger_1.1/TigerIOSStarter').exists():
    HOST = repo_root / 'Tiktiger_1.1/TigerIOSStarter'
    HANDOFF = repo_root / 'Tiktiger_1.1'
else:
    HOST = Path('/home/ubuntu/work/tiktiger/starter/TigerIOSStarter')
    HANDOFF = Path('/home/ubuntu/work/tiktiger_handoff/starter/Tiktiger_Developer_Handoff')
HOST_PBX = (HOST / 'TigerIOSStarter.xcodeproj/project.pbxproj').read_text(encoding='utf-8')
DY_PBX = (HANDOFF / 'Xcode_Dylib_Project/TiktigerDylib.xcodeproj/project.pbxproj').read_text(encoding='utf-8')
HOST_VIEW = (HOST / 'TigerHost/ContentView.swift').read_text(encoding='utf-8')
SERVICE = (HOST / 'TigerHost/Services/TiktigerMediaDownloadService.swift').read_text(encoding='utf-8')
HEADER = (HANDOFF / 'Xcode_Dylib_Project/TiktigerDylib/include/Tiktiger.h').read_text(encoding='utf-8')
ADAPTER = (HANDOFF / 'Integration/TiktigerHostAdapter.m').read_text(encoding='utf-8')
VERIFY = (HANDOFF / 'Xcode_Dylib_Project/Scripts/verify_dylib.sh').read_text(encoding='utf-8')
RUNTIME_C = (HANDOFF / 'Xcode_Dylib_Project/TiktigerDylib/src/TiktigerRuntime.c').read_text(encoding='utf-8')
COORDINATOR = (HOST / 'TigerHost/TiktigerRuntimeCoordinator.swift').read_text(encoding='utf-8')

checks = {
    'host_target_present': 'name = TigerHost;' in HOST_PBX and 'com.apple.product-type.application' in HOST_PBX,
    'core_target_present': 'name = TigerCore;' in HOST_PBX and 'com.apple.product-type.framework' in HOST_PBX,
    'host_service_in_sources': 'TiktigerMediaDownloadService.swift in Sources' in HOST_PBX and 'path = Services;' in HOST_PBX,
    'host_service_file': (HOST / 'TigerHost/Services/TiktigerMediaDownloadService.swift').exists(),
    'host_resources': all((HOST / x).exists() for x in ['TigerHost/Resources/tiktiger_logo.png', 'TigerHost/Resources/download_arrow.png', 'TigerHost/Assets.xcassets/TiktigerIcon.appiconset/Contents.json']),
    'host_info_usage_descriptions': 'INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription' in HOST_PBX and 'INFOPLIST_KEY_NSFaceIDUsageDescription' in HOST_PBX,
    'host_ios15': 'IPHONEOS_DEPLOYMENT_TARGET = 15.0;' in HOST_PBX,
    'host_no_maccatalyst': 'SUPPORTS_MACCATALYST = NO;' in HOST_PBX,
    'host_framework_link_embed': 'TigerCore.framework in Frameworks' in HOST_PBX and 'TigerCore.framework in Embed Frameworks' in HOST_PBX,
    'host_runtime_loader_file': (HOST / 'TigerHost/TiktigerRuntimeCoordinator.swift').exists() and 'dlopen' in (HOST / 'TigerHost/TiktigerRuntimeCoordinator.swift').read_text(encoding='utf-8'),
    'host_runtime_loader_in_sources': 'TiktigerRuntimeCoordinator.swift in Sources' in HOST_PBX,
    'host_dylib_embed_phase': 'Tiktiger.dylib in Embed Tiktiger' in HOST_PBX and 'name = "Embed Tiktiger dylib"' in HOST_PBX and 'CodeSignOnCopy' in HOST_PBX,
    'host_runtime_reference': 'path = Tiktiger.dylib;' in HOST_PBX and (HOST / 'TigerHost/Runtime/README_AR.md').exists(),
    'host_device_only_embed': 'platformFilters = (iphoneos, );' in HOST_PBX,
    'host_retained_handle': 'private var handle:' in COORDINATOR and 'dlclose(' not in COORDINATOR,
    'host_dlerror_dlsym_reporting': 'dlerror' in COORDINATOR and 'dlsym' in COORDINATOR and 'symbolReports' in COORDINATOR,
    'host_view_hierarchy_gate': 'view.window != nil' in COORDINATOR and 'view.superview != nil' in COORDINATOR and 'confirmPresented(from view' in COORDINATOR,
    'dylib_ios_arm64': 'SDKROOT = iphoneos;' in DY_PBX and 'ARCHS = arm64;' in DY_PBX and 'SUPPORTED_PLATFORMS = iphoneos;' in DY_PBX,
    'dylib_contract': 'MACH_O_TYPE = mh_dylib;' in DY_PBX and '@rpath/Tiktiger.dylib' in DY_PBX and 'CURRENT_PROJECT_VERSION = 11;' in DY_PBX,
    'dylib_features_in_sources': 'TiktigerFeatures.c in Sources' in DY_PBX and (HANDOFF / 'Xcode_Dylib_Project/TiktigerDylib/src/TiktigerFeatures.c').exists(),
    'dylib_runtime_in_sources': 'TiktigerRuntime.c in Sources' in DY_PBX and (HANDOFF / 'Xcode_Dylib_Project/TiktigerDylib/src/TiktigerRuntime.c').exists(),
    'constructor_no_ui_milestones': 'atomic_store(&g_ui_registered' not in RUNTIME_C[RUNTIME_C.index('static void tt_runtime_constructor'):RUNTIME_C.index('void tt_runtime_initialize')] and 'atomic_store(&g_ui_presented' not in RUNTIME_C[RUNTIME_C.index('static void tt_runtime_constructor'):RUNTIME_C.index('void tt_runtime_initialize')],
    'runtime_timestamps': 'timestamp=' in RUNTIME_C and 'time(NULL)' in RUNTIME_C,
    'runtime_api_contract': all(x in HEADER for x in ['tt_runtime_dylib_loaded', 'tt_runtime_initialize', 'tt_runtime_diagnostics_json']),
    'adapter_symbols_match': all(x in HEADER and x in ADAPTER for x in ['tt_validate_https_url', 'tt_set_feature_enabled', 'tt_sanitize_filename', 'tt_set_download_stage', 'tt_diagnostics_json']),
    'provider_abstraction': 'protocol TiktigerMediaProvider' in SERVICE and 'PROVIDER REQUIRED' in SERVICE,
    'https_only': 'httpsRequired' in SERVICE and 'url.scheme?.lowercased() == "https"' in SERVICE,
    'http_status_handling': 'httpStatus(Int)' in SERVICE and 'HTTPURLResponse' in SERVICE,
    'cancellation': 'Task.checkCancellation()' in SERVICE and 'func cancel()' in SERVICE,
    'retry_and_history': 'func retryLast()' in SERVICE and 'history' in SERVICE and 'saveHistory' in SERVICE,
    'photo_audio_paths': 'PHPhotoLibrary' in SERVICE and 'AVAssetExportSession' in SERVICE and 'UIActivityViewController' in HOST_VIEW,
    'diagnostics_honest': 'PROVIDER REQUIRED' in HOST_VIEW and 'PARTIAL' in HOST_VIEW and 'NOT IMPLEMENTED' in HOST_VIEW,
    'no_legacy_vibetok': 'VibeTok' not in HOST_VIEW,
    'no_force_unwrap_in_changed_files': 'try!' not in SERVICE and ' as!' not in SERVICE,
    'fail_closed_verifier': all(x in VERIFY for x in ['required Apple verification tool is missing', 'lipo -archs', 'MH_DYLIB', '@rpath/Tiktiger.dylib', 'nm -gU']),
    'no_build_artifact_claimed': not (HANDOFF / 'Xcode_Dylib_Project/BuildOutput/Tiktiger.dylib').exists(),
}
for key, ok in checks.items():
    print(f'{key}: ' + ('OK' if ok else 'MISSING'))

for label, pbx in [('host', HOST_PBX), ('dylib', DY_PBX)]:
    ids = re.findall(r'^\s*([A-Fa-f0-9]{24})\s+/\*.*?\*/\s*=\s*\{', pbx, re.MULTILINE)
    counts = Counter(ids)
    print(f'{label}_pbx_declared_ids: {len(ids)}')
    print(f'{label}_pbx_duplicate_ids: ' + json.dumps({k: v for k, v in counts.items() if v > 1}, ensure_ascii=False))

for name in ['TigerHost/Assets.xcassets/Contents.json', 'TigerHost/Assets.xcassets/TiktigerIcon.appiconset/Contents.json']:
    json.loads((HOST / name).read_text(encoding='utf-8'))
    print(f'{name}: JSON_OK')

print('note: this is static/source validation only; it is not an Xcode build.')
