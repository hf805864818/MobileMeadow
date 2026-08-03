TARGET = iphone:clang:latest:15.0
export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = MobileMeadow

MobileMeadow_FILES = $(shell find Sources -name '*.swift')
MobileMeadow_SWIFTFLAGS = -I../Sources/MobileMeadowRebornC/include -I../Sources/MobileMeadowReborn -I$(THEOS)/vendor/include -I$(THEOS)/include
MobileMeadow_CFLAGS = -fobjc-arc -I../Sources/MobileMeadowRebornC/include -I$(THEOS)/vendor/include -I$(THEOS)/include
MobileMeadow_LDFLAGS = -undefined dynamic_lookup
MobileMeadow_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/application.mk