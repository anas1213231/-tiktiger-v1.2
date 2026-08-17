from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
hooks = (root / 'TiktigerHooks.m').read_text(encoding='utf-8')
prefs = (root / 'TiktigerPrefs.m').read_text(encoding='utf-8')
workflow = (root / '.github/workflows/build.yml').read_text(encoding='utf-8')
makefile = (root / 'Makefile').read_text(encoding='utf-8')
errors = []
checks = {
    'Anonymous Profile Visits': ('anonymousProfiles', 'TTKProfileViewsVisitor', 'p_shouldReportProfileView'),
    'Keep Story Unseen': ('unseenStories', 'TTKStoryMarkReadService', 'markAsRead:'),
    'Keep Messages Unseen': ('unreadMessages', 'AWEIMMessageReadComponent', 'p_markReadSyncToServerWithMessage:'),
    'Hide Typing': ('hideTyping', 'AWEIMSendMessageController', 'sendTyping:'),
}
for name, (key, cls, selector) in checks.items():
    if f'TTBool(@"{key}")' not in hooks: errors.append(f'{name}: hook does not read {key}')
    if cls not in hooks or selector not in hooks: errors.append(f'{name}: target class/selector missing')
    if f'@[[self item:' in prefs and key not in prefs: errors.append(f'{name}: Settings key missing')
    if key not in prefs: errors.append(f'{name}: preference key not present in Settings model')
if 'TTInstallCheckedHook' not in hooks: errors.append('Checked hook helper missing')
if 'CydiaSubstrate' not in makefile: errors.append('Makefile lost CydiaSubstrate framework')
for required in ('test -n "$DYLIB"', 'output/Tiktiger.dylib', 'otool -L', 'shasum -a 256', 'actions/upload-artifact@v4'):
    if required not in workflow: errors.append(f'Workflow missing {required}')
# Prevent accidental reuse of a single original IMP for both sender classes.
for name in ('TTOriginalTypingControllerBool', 'TTOriginalTypingControllerStatus', 'TTOriginalTypingSenderBool', 'TTOriginalTypingSenderStatus'):
    if hooks.count(name) < 2: errors.append(f'Original pointer not fully wired: {name}')
if 'http://' in hooks or 'https://' in hooks or 'NSURLSession' in hooks:
    errors.append('Privacy hooks unexpectedly contain network code')
report = ['# Previous repo privacy merge verification', '', f'Errors: {len(errors)}', '']
report += ['- None'] if not errors else [f'- {e}' for e in errors]
(root / 'docs/PRIVACY_MERGE_VERIFICATION.md').write_text('\n'.join(report) + '\n', encoding='utf-8')
print('\n'.join(report))
raise SystemExit(1 if errors else 0)
