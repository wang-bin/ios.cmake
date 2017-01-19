# ios.cmake
Support bitcode, multi-arch build in command line. C++11 enabled. Minimal iOS version support is 5.0.

The original project is https://code.google.com/p/ios-cmake . I almost rewrote the whole code to support
new features and simplify the usage.

## Variables to Control:
- `IOS_ARCH`: Architectures being compiled for. Multiple architectures are seperated by ";". It **MUST** be set.
- `IOS_DEPLOYMENT_TARGET`: Minimal target iOS version to run. Default is current sdk version.
- `IOS_BITCODE`: Enable bitcode or not. Only iOS >= 6.0 device build can enable bitcode. Default is enabled.
- `IOS_EMBEDDED_FRAMEWORK`: Build as embedded framework for IOS_DEPLOYMENT_TARGET >= 8.0. Default is disabled and relocatable object is used.

## Known Issues
- xcode project is not well supported