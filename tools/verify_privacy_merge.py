#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
prefs = (root / 'TiktigerPrefs.m').read_text(encoding='utf-8')
header = (root / 'TiktigerPrefs.h').read_text(encoding='utf-8')
window = (root / 'TiktigerWindow.m').read_text(encoding='utf-8')
hooks = (root / 'TiktigerHooks.m').read_text(encoding='utf-8')
resources = (root / 'TiktigerResources.h').read_text(encoding='utf-8')
makefile = (root / 'Makefile').read_text(encoding='utf-8')
workflow = (root / '.github/workflows/build.yml').read_text(encoding='utf-8')

errors = []
keys = ('anonymousProfiles', 'unseenStories', 'unreadMessages', 'hideTyping')
for key in keys:
    if prefs.count(f'@"{key}"') != 1:
        errors.append(f'preference catalog key count is not 1: {key}')
    if f'TTBool(@"{key}")' not in hooks:
        errors.append(f'hook preference read missing: {key}')
if 'TTPrivacyFeatureDefinitions()' not in window or 'toggleFeature:' not in window:
    errors.append('Settings feature catalog binding missing')
if 'feature[@"key"]' not in window:
    errors.append('Settings does not bind switches to catalog keys')

if 'TTInstallCheckedHook' not in hooks:
    errors.append('guarded hook helper missing')
if 'TiktigerPrefs.m TiktigerWindow.m TiktigerHooks.m' not in makefile:
    errors.append('Makefile contains unexpected source layout')
if '-Wl,-headerpad_max_install_names' not in makefile or '-Wl,-headerpad,0x10000' not in makefile:
    errors.append('Mach-O header padding missing')
if 'find .theos -type f -name \'Tiktiger.dylib\'' in workflow:
    errors.append('workflow still extracts possible dSYM from .theos')
for required in ('dpkg-deb -x', 'DynamicLibraries/Tiktiger.dylib', 'dSYM companion', 'lipo -info', 'otool -l', 'actions/upload-artifact@v4'):
    if required not in workflow:
        errors.append(f'workflow missing: {required}')
if 'TTExtractMediaURL' in header or 'TTDownloadMedia' in header or 'TTConfirm' in header:
    errors.append('legacy media/confirmation API remains in preferences header')
if 'kTiktigerMainLogoB64' in resources or 'kTiktigerDownloadIconB64' in resources:
    errors.append('legacy Base64 assets remain')
for legacy in ('hideAds', 'downloadButton', 'repeatMessages', 'tapBot', 'persistentSpeed', 'confirmLike', 'fakeCamera'):
    if legacy in prefs or legacy in window:
        errors.append(f'legacy feature remains in new Settings: {legacy}')
if 'Tiktiger.v2.' not in prefs:
    errors.append('v2 preference namespace missing')

print('# Tiktiger v2 redesign verification')
print(f'Errors: {len(errors)}')
for error in errors:
    print(f'- {error}')
if errors:
    sys.exit(1)
