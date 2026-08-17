# Inspection of the previous repository

The public repository `anas1213231/-tiktiger-v1.2` is an Objective-C/Theos project. Its current Makefile builds `TiktigerPrefs.m`, `TiktigerWindow.m`, and `TiktigerHooks.m`, targets `arm64 arm64e`, filters `com.zhiliaoapp.musically`, and already contains a macOS GitHub Actions workflow.

The previous Settings model already exposes the four requested keys: `unseenStories`, `unreadMessages`, `hideTyping`, and `anonymousProfiles`. The UI splits them into Stories, Messages, and Profile sections. `TiktigerHooks.m` already implements a guarded story-read hook for `TTKStoryManager markStoryReaded:` and uses `TTBool` for the `unseenStories` preference.

The current hook file does not yet implement the requested profile-visit, message-read-sync, or typing hooks. The older workflow also creates a CydiaSubstrate stub and packages a deb, but its extraction step must be validated after the privacy merge.

The previous README describes a more modular layout than the checked-in source currently builds. The safest merge is therefore to preserve the existing three-file architecture and its current UI/resources, add the four independent guarded hooks to `TiktigerHooks.m`, keep the existing flat preference keys for backward compatibility, and harden the existing workflow to upload the real dylib as an artifact. No push or remote mutation has been performed during inspection.
