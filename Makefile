ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = TikTok
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = Tiktiger
Tiktiger_FILES = TiktigerPrefs.m TiktigerWindow.m TiktigerHooks.m
Tiktiger_RESOURCE_FILES = assets/tiktiger-main.png assets/tiktiger-download.png
Tiktiger_CFLAGS = -fobjc-arc -I. -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-function
Tiktiger_FRAMEWORKS = UIKit Foundation AVFoundation AVFAudio CoreMedia CoreVideo
Tiktiger_LDFLAGS = -rpath @executable_path/Frameworks -F. -framework CydiaSubstrate
include $(THEOS_MAKE_PATH)/tweak.mk
after-install::
	install.exec "killall -9 TikTok || true"
