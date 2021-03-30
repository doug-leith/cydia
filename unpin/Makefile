TARGET := iphone:clang:latest:12.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = unpin

unpin_FILES = Tweak.m
unpin_CFLAGS=-DSUBSTRATE_BUILD

unpin_FRAMEWORKS = Security
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
