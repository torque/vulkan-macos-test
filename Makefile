.PHONY: all

all: swift.o main.o
	cc -L /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/lib/swift $^ -o test

main.o: main.c
	cc -std=c99 -I. -MMD -MF $(@:.o=.d) -c $< -o $@

swift.o: main.swift
	swiftc -emit-object -static -parse-as-library -whole-module-optimization -module-name swiftapp -import-objc-header c.h -I. -o $@ $^
# 	swiftc -emit-object -static -emit-objc-header -parse-as-library -whole-module-optimization -module-name test -emit-module-path test.swiftmod -emit-objc-header-path test-header.h -I. -o $@ $^

-include main.d
