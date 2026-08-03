TARGET = iphone:clang:latest:15.0
export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = MobileMeadow

MobileMeadow_FILES = $(shell find Sources -name '*.swift')
MobileMeadow_CFLAGS = -fobjc-arc
MobileMeadow_LDFLAGS = -undefined dynamic_lookup
MobileMeadow_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/application.mk