TARGET = iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard
# 支持三种编译模式：
#   rootless  - 标准 rootless 越狱 (Dopamine, palera1n rootless)
#   roothide  - RELAXIN / RootHide 引导程序
# 通过 make package THEOS_PACKAGE_SCHEME=roothide 切换
THEOS_PACKAGE_SCHEME ?= rootless
export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MobileMeadowReborn

MobileMeadowReborn_FILES = $(shell find Sources/MobileMeadowReborn -name '*.swift') $(shell find Sources/MobileMeadowRebornC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
MobileMeadowReborn_SWIFTFLAGS = -ISources/MobileMeadowRebornC/include -I$(THEOS)/vendor/include -I$(THEOS)/include
MobileMeadowReborn_CFLAGS = -fobjc-arc -ISources/MobileMeadowRebornC/include -I$(THEOS)/vendor/include -I$(THEOS)/include
MobileMeadowReborn_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += MobileMeadowRebornApps
SUBPROJECTS += Preferences
SUBPROJECTS += MobileMeadowStandalone
include $(THEOS_MAKE_PATH)/aggregate.mk
