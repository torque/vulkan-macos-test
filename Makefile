VULKAN_SDK := $(HOME)/Applications/VulkanSDK

VULKAN_PFX := $(VULKAN_SDK)/macOS
MOLTENVK_PFX := $(VULKAN_SDK)/MoltenVK

GLSLANG_VALIDATOR := $(VULKAN_PFX)/bin/glslangValidator

BUILDDIR := build

INCLUDES := -I$(VULKAN_PFX)/include -I$(MOLTENVK_PFX)/include -I$(BUILDDIR)
LINKDIRS := -L$(VULKAN_PFX)/lib -L$(MOLTENVK_PFX)/dylib/macOS
LINKDIRS += -L/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/lib/swift


.PHONY: all clean

all: $(BUILDDIR)/test

$(BUILDDIR)/test: $(BUILDDIR)/swift.o $(BUILDDIR)/main.o | $(BUILDDIR)
	cc $(LINKDIRS) -lvulkan -lMoltenVK $^ -o $@

$(BUILDDIR)/main.o: main.c | $(BUILDDIR)/cube.vert.inc $(BUILDDIR)/cube.frag.inc $(BUILDDIR)
	cc -std=c99 -I. $(INCLUDES) -MMD -MF $(@:.o=.d) -c $< -o $@

$(BUILDDIR)/swift.o: main.swift | $(BUILDDIR)
	swiftc -emit-object -static -parse-as-library -whole-module-optimization -module-name swiftapp -emit-module-path $(BUILDDIR)/test.swiftmod -import-objc-header c.h -I. -o $@ $^
# 	swiftc -emit-object -static -emit-objc-header -parse-as-library -whole-module-optimization -module-name test -emit-module-path test.swiftmod -emit-objc-header-path test-header.h -I. -o $@ $^

$(BUILDDIR)/cube.vert.inc: cube/cube.vert | $(BUILDDIR)
	$(GLSLANG_VALIDATOR) -V -x -o $@ $<

$(BUILDDIR)/cube.frag.inc: cube/cube.frag | $(BUILDDIR)
	$(GLSLANG_VALIDATOR) -V -x -o $@ $<

$(BUILDDIR):
	@mkdir -p $@

clean:
	rm -r $(BUILDDIR)


-include $(BUILDDIR)/main.d
