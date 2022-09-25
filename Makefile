VULKAN_SDK := $(HOME)/Applications/VulkanSDK

VULKAN_PFX := $(VULKAN_SDK)/macOS
MOLTENVK_PFX := $(VULKAN_SDK)/MoltenVK

GLSLANG_VALIDATOR := $(VULKAN_PFX)/bin/glslangValidator

INCLUDES := -I$(VULKAN_PFX)/include -I$(MOLTENVK_PFX)/include
LINKDIRS := -L$(VULKAN_PFX)/lib -L$(MOLTENVK_PFX)/dylib/macOS
LINKDIRS += -L/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/lib/swift

.PHONY: all

all: swift.o main.o
	cc $(LINKDIRS) -lvulkan -lMoltenVK $^ -o test

main.o: main.c
	cc -std=c99 -I. $(INCLUDES) -MMD -MF $(@:.o=.d) -c $< -o $@

swift.o: main.swift
	swiftc -emit-object -static -parse-as-library -whole-module-optimization -module-name swiftapp -import-objc-header c.h -I. -o $@ $^
# 	swiftc -emit-object -static -emit-objc-header -parse-as-library -whole-module-optimization -module-name test -emit-module-path test.swiftmod -emit-objc-header-path test-header.h -I. -o $@ $^

cube/cube.vert.inc: cube/cube.vert
	$(GLSLANG_VALIDATOR) -V -x -o $@ $<

cube/cube.frag.inc: cube/cube.frag
	$(GLSLANG_VALIDATOR) -V -x -o $@ $<

-include main.d
