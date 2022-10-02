vulkan-macos-test
-----------------

This is a weird experimental mess:

- A macOS GUI application that
- Runs the vulkan cube demo on metal via moltenvk
- Uses only swift (no Objective-C)
- Exposes a (trivial) C api from swift and is launched by C ``main``
- Calls back into the C code, passing through opaque handles
- Builds with a normal Makefile (no xcode required except to provide the SDK &
  compilers)
- Runs via the CLI

These features are desirable for ideological reasons rather than practical ones
