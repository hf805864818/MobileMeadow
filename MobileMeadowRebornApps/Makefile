TARGET = iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard
export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MobileMeadowRebornApps

MobileMeadowRebornApps_FILES = $(shell find Sources/MobileMeadowRebornApps -name '*.swift') $(shell find Sources/MobileMeadowRebornAppsC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
MobileMeadowRebornApps_SWIFTFLAGS = -ISources/MobileMeadowRebornAppsC/include -I$(THEOS)/vendor/include -I$(THEOS)/include
MobileMeadowRebornApps_CFLAGS = -fobjc-arc -ISources/MobileMeadowRebornAppsC/include -I$(THEOS)/vendor/include -I$(THEOS)/include
MobileMeadowRebornApps_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk
