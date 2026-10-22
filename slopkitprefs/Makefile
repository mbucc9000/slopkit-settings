TARGET = iphone:clang:6.1:6.0
ARCHS = armv7

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SlopKitPrefs
SlopKitPrefs_FILES = SKRootListController.m
SlopKitPrefs_INSTALL_PATH = /Library/PreferenceBundles
SlopKitPrefs_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics
SlopKitPrefs_CFLAGS = -fobjc-arc

# Link Preferences if the SDK ships it; otherwise let dyld resolve PSListController/PSSpecifier
# at load time (Settings already has Preferences.framework loaded).
ifneq ($(wildcard $(THEOS)/sdks/iPhoneOS6.1.sdk/System/Library/PrivateFrameworks/Preferences.framework),)
SlopKitPrefs_PRIVATE_FRAMEWORKS = Preferences
else
SlopKitPrefs_LDFLAGS = -Wl,-undefined,dynamic_lookup
endif
# libprefs' -specifiersFromEntry:... is looked up at run time (respondsToSelector:).

include $(THEOS)/makefiles/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SlopKit.plist$(ECHO_END)
