TARGET = iphone:clang:6.1:6.0
ARCHS = armv7

include $(THEOS)/makefiles/common.mk

# Loaded into Settings only: takes the slopkit tweaks' rows off the main page.
TWEAK_NAME = SlopKit
SlopKit_FILES = Tweak.x
SlopKit_FRAMEWORKS = Foundation UIKit
SlopKit_LIBRARIES = substrate
SlopKit_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/tweak.mk

SUBPROJECTS += slopkitprefs
include $(THEOS)/makefiles/aggregate.mk
