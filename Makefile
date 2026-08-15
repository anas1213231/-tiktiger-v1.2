ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = TikTok
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = Tiktiger
Tiktiger_FILES = TiktigerPrefs.m TiktigerUI.m TiktigerFeed.m TiktigerDownload.m TiktigerMessages.m TiktigerProfile.m TiktigerConfirm.m TiktigerMisc.m TiktigerMedia.m
Tiktiger_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-objc-protocol-property-synthesis
Tiktiger_FRAMEWORKS = UIKit Foundation AVFoundation AVFAudio CoreMedia CoreVideo SafariServices LocalAuthentication
Tiktiger_LIBRARIES = substrate
include $(THEOS_MAKE_PATH)/tweak.mk
after-install::
	install.exec "killall -9 TikTok || true"
