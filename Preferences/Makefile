TARGET := iphone:clang:latest:14.5
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = MobileMeadowRebornPrefs

MobileMeadowRebornPrefs_FILES = $(shell find Sources/MobileMeadowRebornPrefs -name '*.swift') $(shell find Sources/MobileMeadowRebornPrefsC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
MobileMeadowRebornPrefs_SWIFTFLAGS = -ISources/MobileMeadowRebornPrefsC/include -ISources/MobileMeadowRebornPrefsC -I$(THEOS)/vendor/include -I$(THEOS)/include
MobileMeadowRebornPrefs_INSTALL_PATH = /Library/PreferenceBundles
MobileMeadowRebornPrefs_CFLAGS = -fobjc-arc -ISources/MobileMeadowRebornPrefsC/include -ISources/MobileMeadowRebornPrefsC -I$(THEOS)/vendor/include -I$(THEOS)/include
MobileMeadowRebornPrefs_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/bundle.mk
