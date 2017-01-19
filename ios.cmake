# This file is part of the ios-cmake project. It was retrieved from
# https://github.com/cristeab/ios-cmake.git, which is a fork of
# https://code.google.com/p/ios-cmake/. Which in turn is based off of
# the Platform/Darwin.cmake and Platform/UnixPaths.cmake files which
# are included with CMake 2.8.4
#
# The ios-cmake project is licensed under the new BSD license.
#
# Copyright (c) 2014, Bogdan Cristea and LTE Engineering Software,
# Kitware, Inc., Insight Software Consortium.  All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# This file is based off of the Platform/Darwin.cmake and
# Platform/UnixPaths.cmake files which are included with CMake 2.8.4
# It has been altered for iOS development.
#
# Updated by Alex Stewart (alexs.mac@gmail.com).
# Updated by Wang Bin (wbsecg1@gmail.com) (support IOS_ARCH, IOS_BITCODE, IOS_EMBEDDED_FRAMEWORK)
# The following variables control the behaviour of this toolchain:
# IOS_ARCH: Architectures being compiled for. Multiple architectures are seperated by ";". It MUST be set.
# IOS_DEPLOYMENT_TARGET=version: minimal target iOS version to run. Default is current sdk version.
# IOS_BITCODE=1/0: Enable bitcode or not. Only iOS >= 6.0 device build can enable bitcode. Default is enabled.
# IOS_EMBEDDED_FRAMEWORK=1/0: build as embedded framework for IOS_DEPLOYMENT_TARGET >= 8.0. Default is disabled and relocatable object is used.
# IOS_SDK_VERSION: Version of iOS SDK being used.
#
# This toolchain defines the following variables for use externally:
# XCODE_VERSION, IOS_DEPLOYMENT_TARGET, IOS_SDK_VERSION, IOS_BITCODE, IOS_EMBEDDED_FRAMEWORK
# IOS_UNIVERSAL: build for device(s) and simulator(s). Detected by IOS_ARCH, e.g. IOS_ARCH="armv7;arm64;x86_64"
# IOS_DEVICE: build for device(s) only. Detected by IOS_ARCH, e.g. IOS_ARCH="armv7;arm64"
# IOS_SIMULATOR: build for simulator(s) only. Detected by IOS_ARCH, e.g. IOS_ARCH=i386
# IOS_SIMULATOR64: build for x64 simulator only
#
# This toolchain defines the following macros for use externally:
#
# set_xcode_property (TARGET XCODE_PROPERTY XCODE_VALUE)
#   A convenience macro for setting xcode specific properties on targets
#   example: set_xcode_property (myioslib IPHONEOS_DEPLOYMENT_TARGET "3.1").
#
# find_host_package (PROGRAM ARGS)
#   A macro used to find executable programs on the host system, not within the
#   iOS environment.  Thanks to the android-cmake project for providing the
#   command.
# Get the Xcode version being used.

## TODO: bitcode (ld: warning: -headerpad_max_install_names (in CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS in Darwin.cmake) is ignored when used with -bitcode_bundle (Xcode setting ENABLE_BITCODE=YES))
## TODO: cmake object target in xcode is in wrong type

execute_process(COMMAND xcodebuild -version
  OUTPUT_VARIABLE XCODE_VERSION
  ERROR_QUIET
  OUTPUT_STRIP_TRAILING_WHITESPACE)
string(REGEX MATCH "Xcode [0-9\\.]+" XCODE_VERSION "${XCODE_VERSION}")
string(REGEX REPLACE "Xcode ([0-9\\.]+)" "\\1" XCODE_VERSION "${XCODE_VERSION}")
message(STATUS "Building with Xcode version: ${XCODE_VERSION}")

if(NOT DEFINED IOS_UNIVERSAL)
  if(IOS_ARCH)
    if(IOS_ARCH MATCHES ".*arm.*")
      if(IOS_ARCH MATCHES ".*86.*")
        set(IOS_UNIVERSAL TRUE)
        message("iOS universal")
      else ()
        set(IOS_DEVICE 1)
        message("iOS device")
      endif ()
    elseif (IOS_ARCH MATCHES "i386")
        message("iOS i386")
      set(IOS_SIMULATOR 1)
    elseif (IOS_ARCH MATCHES "x86_64")
        message("iOS x64")
      set(IOS_SIMULATOR64 1)
      set(IOS_SIMULATOR 1)
    else()
      message(FATAL_ERROR "unrecognized IOS_ARCH")
    endif()
  endif()
  if(NOT DEFINED IOS_UNIVERSAL)
    set(IOS_UNIVERSAL FALSE)
  endif()
endif()

if(NOT DEFINED IOS_BITCODE) #TODO: check xcode version. since xcode 7
  set(IOS_BITCODE 1)
endif()
# Determine the platform name and architectures for use in xcodebuild commands
# CMAKE_OSX_SYSROOT: appletvos, appletvsimullator, watchos, watch.....
if (IOS_DEVICE)
  set(IOS_SYSROOT iphoneos)
  set(CMAKE_XCODE_EFFECTIVE_PLATFORMS "-iphoneos")
elseif (IOS_SIMULATOR)
  set(IOS_SYSROOT iphonesimulator)
  set(IOS_BITCODE 0)
  set(CMAKE_XCODE_EFFECTIVE_PLATFORMS "-iphonesimulator")
elseif(IOS_UNIVERSAL)
  set(IOS_SYSROOT iphoneos)
  set(IOS_BITCODE 0)
  set(CMAKE_XCODE_EFFECTIVE_PLATFORMS "-iphoneos;-iphonesimulator")
endif()

message(STATUS "Configuring iOS build for platform: ${IOS_SYSROOT}, architecture(s): ${IOS_ARCH}")
# Get the SDK version information.
if (NOT DEFINED IOS_SDK_VERSION)
  execute_process(COMMAND xcodebuild -sdk ${IOS_SYSROOT} -version SDKVersion
    OUTPUT_VARIABLE IOS_SDK_VERSION
    ERROR_QUIET
    OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()
if (NOT DEFINED CMAKE_C_COMPILER)
  execute_process(COMMAND xcrun -sdk ${IOS_SYSROOT} -find clang
    OUTPUT_VARIABLE CMAKE_C_COMPILER
    ERROR_QUIET
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  message(STATUS "Using C compiler: ${CMAKE_C_COMPILER}")
endif()
if (NOT DEFINED CMAKE_CXX_COMPILER)
  execute_process(COMMAND xcrun -sdk ${IOS_SYSROOT} -find clang++
    OUTPUT_VARIABLE CMAKE_CXX_COMPILER
    ERROR_QUIET
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  message(STATUS "Using CXX compiler: ${CMAKE_CXX_COMPILER}")
endif()
if (NOT DEFINED IOS_LIBTOOL)
  execute_process(COMMAND xcrun -sdk ${IOS_SYSROOT} -find libtool
    OUTPUT_VARIABLE IOS_LIBTOOL
    ERROR_QUIET
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  message(STATUS "Using libtool: ${IOS_LIBTOOL}")
endif()
# Specify minimum version of deployment target.
# Unless specified, the latest SDK version is used by default.
set(IOS_DEPLOYMENT_TARGET "${IOS_SDK_VERSION}" CACHE STRING "Minimum iOS version to build for." )
message(STATUS "Building for minimum iOS version: ${IOS_DEPLOYMENT_TARGET} (SDK version: ${IOS_SDK_VERSION})")
set(CMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "${IOS_DEPLOYMENT_TARGET}")

# avoid duplicates
#set(XARCH_CFLAGS "" CACHE STRING "" FORCE)
#set(XARCH_LFLAGS "" CACHE STRING "" FORCE)
if(IOS_DEPLOYMENT_TARGET VERSION_LESS 7.0) # gnu stl does not support c++11
  set(CXX_FLAGS -stdlib=libc++) #TODO: check c++11
  if(IOS_DEPLOYMENT_TARGET VERSION_LESS 6.0)
    message("bitcode is disabled for iOS < 6.0") # link error if not static lib
    set(IOS_BITCODE 0)
    if(IOS_DEPLOYMENT_TARGET VERSION_LESS 5.0)
      message("-stdlib=libc++ requires iOS 5.0 or later (for C++11)")
    endif()
  endif()
endif()
if(NOT IOS_DEPLOYMENT_TARGET VERSION_LESS 8.0 AND IOS_EMBEDDED_FRAMEWORK)
  set(IOS_EMBEDDED_FRAMEWORK 1)
else()
  set(IOS_EMBEDDED_FRAMEWORK 0)
#[[
  set(CMAKE_XCODE_ATTRIBUTE_MACH_O_TYPE "Relocatable Object File")
  set(CMAKE_XCODE_ATTRIBUTE_LINK_WITH_STANDARD_LIBRARIES NO)
  set(CMAKE_XCODE_ATTRIBUTE_DEAD_CODE_STRIPPING NO)
  set(CMAKE_XCODE_ATTRIBUTE_GENERATE_MASTER_OBJECT_FILE YES) # perform single-object prelink: -r
  set(CMAKE_XCODE_ATTRIBUTE_STRIP_STYLE "Non-Global") # pass -x to ld
  set(CMAKE_XCODE_ATTRIBUTE_OTHER_LDFLAGS "-r") # why must add manually?
]]
endif()
message("IOS_EMBEDDED_FRAMEWORK: ${IOS_EMBEDDED_FRAMEWORK}")

macro(set_xarch_flags arch)
  unset(XARCH_VERSION_FLAGS)
  set(XARCH_VERSION_FLAGS "${XARCH_VERSION_FLAGS} -Xarch_${arch}")
  if("${arch}" MATCHES ".*arm.*")
    set(XARCH_SDK iphoneos)
    set(XARCH_OS iphoneos)
    if (XCODE_VERSION VERSION_LESS 7.0)
      set(XARCH_OS ios)
    endif()
    set(XARCH_VERSION_FLAGS "-m${XARCH_OS}-version-min=${IOS_DEPLOYMENT_TARGET}")
    if("${arch}" MATCHES "arm64" AND IOS_DEPLOYMENT_TARGET VERSION_LESS 7.0)
      set(XARCH_VERSION_FLAGS "-m${XARCH_OS}-version-min=7.0")
    endif()
  else()
    set(XARCH_SDK iphonesimulator)
    set(XARCH_OS iphonesimulator)
    if (XCODE_VERSION VERSION_LESS 7.0)
      set(XARCH_OS ios-simulator)
    endif()
    set(XARCH_VERSION_FLAGS "-m${XARCH_OS}-version-min=${IOS_DEPLOYMENT_TARGET}")
    if("${arch}" MATCHES "x86_64" AND IOS_DEPLOYMENT_TARGET VERSION_LESS 7.0)
      set(XARCH_VERSION_FLAGS "-m${XARCH_OS}-version-min=7.0")
    endif()
  endif()
  execute_process(COMMAND xcodebuild -version -sdk ${XARCH_SDK} Path
      OUTPUT_VARIABLE XARCH_SYSROOT
      ERROR_QUIET
      OUTPUT_STRIP_TRAILING_WHITESPACE)
  message(STATUS "Using SDK: ${XARCH_SYSROOT} for platform: ${XARCH_SDK} ${arch}")
  if (IOS_UNIVERSAL)
    # -arch ${arch} : active the arch. CMAKE_OSX_ARCHITECTURES also adds the flags, so not necessary if CMAKE_OSX_ARCHITECTURES is set
    set(XARCH_CFLAGS "${XARCH_CFLAGS} -arch ${arch} -Xarch_${arch} ${XARCH_VERSION_FLAGS} -Xarch_${arch} -isysroot${XARCH_SYSROOT}")
    set(XARCH_LFLAGS "${XARCH_LFLAGS} -arch ${arch} -Xarch_${arch} ${XARCH_VERSION_FLAGS} -Xarch_${arch} -Wl,-syslibroot,${XARCH_SYSROOT}")
  else()
    set(XARCH_CFLAGS "${XARCH_VERSION_FLAGS}") # set version flag only once
    set(XARCH_LFLAGS "${XARCH_VERSION_FLAGS}")
  endif()
  # TODO: precompile header -Xarch_xxx -include
endmacro()

if (NOT DEFINED XARCH_CFLAGS)
  foreach(a ${IOS_ARCH})
    set_xarch_flags(${a})
  endforeach()
endif()
set(IOS_DEVICE_ARCH ${IOS_ARCH})
set(IOS_SIMULATOR_ARCH ${IOS_ARCH})
list(FILTER IOS_DEVICE_ARCH INCLUDE REGEX "arm.*")
list(FILTER IOS_SIMULATOR_ARCH EXCLUDE REGEX "arm.*")
set(CMAKE_XCODE_ATTRIBUTE_ARCHS[sdk=iphoneos*] "${IOS_DEVICE_ARCH}")
set(CMAKE_XCODE_ATTRIBUTE_VALID_ARCHS[sdk=iphoneos*] "${IOS_DEVICE_ARCH}")
set(CMAKE_XCODE_ATTRIBUTE_ARCHS[sdk=iphonesimulator*] "${IOS_SIMULATOR_ARCH}")
set(CMAKE_XCODE_ATTRIBUTE_VALID_ARCHS[sdk=iphonesimulator*] "${IOS_SIMULATOR_ARCH}")

# Configure libtool to be used instead of ar + ranlib to build static libraries.
# This is required on Xcode 7+, but should also work on previous versions of
# Xcode.
set(CMAKE_C_CREATE_STATIC_LIBRARY "${IOS_LIBTOOL} -static -o <TARGET> <LINK_FLAGS> <OBJECTS> ")
set(CMAKE_CXX_CREATE_STATIC_LIBRARY "${IOS_LIBTOOL} -static -o <TARGET> <LINK_FLAGS> <OBJECTS> ")
# Export configurable variables for the try_compile() command.
set(CMAKE_TRY_COMPILE_PLATFORM_VARIABLES
  IOS_ARCH
  IOS_UNIVERSAL
  IOS_DEVICE
  IOS_SIMULATOR
  IOS_SIMULATOR64
  IOS_SYSROOT
)

# Standard settings.
set(CMAKE_SYSTEM_NAME Darwin) # iOS is unknown to cmake. if use Darwin, macOS sdk sysroot will be set
set(CMAKE_SYSTEM_VERSION ${IOS_SDK_VERSION})
set(UNIX TRUE)
set(APPLE TRUE)
set(IOS TRUE)
# Force unset of OS X-specific deployment target (otherwise autopopulated),
# required as of cmake 2.8.10.
set(CMAKE_OSX_DEPLOYMENT_TARGET "" CACHE STRING "Must be empty for iOS builds." FORCE)
# Set the architectures for which to build. required by try_compile()
set(CMAKE_OSX_ARCHITECTURES ${IOS_ARCH} CACHE STRING "iOS architectures" FORCE)
message("CMAKE_OSX_ARCHITECTURES: ${CMAKE_OSX_ARCHITECTURES}")
# Skip the platform compiler checks for cross compiling.
if(IOS_UNIVERSAL)
  if(CMAKE_GENERATOR MATCHES "Xcode")
    set(CMAKE_OSX_SYSROOT "${IOS_SYSROOT}")
  else()
    set(CMAKE_OSX_SYSROOT "" CACHE STRING "Must be empty for iOS universal builds." FORCE) # will add macOS sysroot for xcode
  endif()
else()
  set(CMAKE_OSX_SYSROOT "${IOS_SYSROOT}")
endif()
set(CMAKE_CXX_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_C_COMPILER_WORKS TRUE)
set(CMAKE_C_COMPILER_ID_RUN TRUE)
set(CMAKE_CXX_COMPILER_ID_RUN TRUE)
set(CMAKE_C_COMPILER_ID Clang)
set(CMAKE_CXX_COMPILER_ID Clang)

# In order to ensure that the updated compiler flags are used in try_compile()
# tests, we have to forcibly set them in the CMake cache, not merely set them
# in the local scope.
list(APPEND VARS_TO_FORCE_IN_CACHE
    CMAKE_C_FLAGS
    CMAKE_CXX_FLAGS
    CMAKE_CXX_FLAGS_RELEASE
    CMAKE_SHARED_LINKER_FLAGS
  )
foreach(VAR_TO_FORCE ${VARS_TO_FORCE_IN_CACHE})
  set(${VAR_TO_FORCE} "" CACHE STRING "" FORCE)
endforeach()

set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE ${IOS_BITCODE})
if(IOS_BITCODE)
  set(CMAKE_XCODE_ATTRIBUTE_BITCODE_GENERATION_MODE "bitcode") # Without this, Xcode adds -fembed-bitcode-marker compile options instead of -fembed-bitcode  set(CMAKE_C_FLAGS "-fembed-bitcode ${CMAKE_C_FLAGS}")
endif()
# ld: '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/arc/libarclite_iphonesimulator.a(arclite.o)' does not contain bitcode. You must rebuild it with bitcode enabled (Xcode setting ENABLE_BITCODE), obtain an updated library from the vendor, or disable bitcode for this target. for architecture x86_64

set(CMAKE_C_FLAGS "${XARCH_CFLAGS} ${CMAKE_C_FLAGS} -fobjc-abi-version=2") # -fobjc-arc
# Hidden visibilty is required for C++ on iOS.
set(CMAKE_CXX_FLAGS "${XARCH_CFLAGS} ${CXX_FLAGS} -std=c++11 -fvisibility=hidden -fvisibility-inlines-hidden ${CMAKE_CXX_FLAGS} -fobjc-abi-version=2") # -fobjc-arc
set(CMAKE_CXX_FLAGS_RELEASE "-DNDEBUG -O3 ${CMAKE_CXX_FLAGS_RELEASE}")
if(CMAKE_GENERATOR MATCHES "Xcode")
else()
  set(CMAKE_C_FLAGS "${XARCH_CFLAGS} ${CMAKE_C_FLAGS}")
  set(CMAKE_CXX_FLAGS "${XARCH_CFLAGS} ${CMAKE_CXX_FLAGS}")
  if(IOS_BITCODE)
    set(CMAKE_C_FLAGS "-fembed-bitcode ${CMAKE_C_FLAGS}")
    set(CMAKE_CXX_FLAGS "-fembed-bitcode ${CMAKE_CXX_FLAGS}")
  endif()
  if(NOT IOS_EMBEDDED_FRAMEWORK)
  # -r: relocatable object, only static dependency is needed. Adding shared libs like libc++ and libSystem will generate warnings
  # xcode: LINK_WITH_STANDARD_LIBRARIES = NO; MACH_O_TYPE = mh_object;
    set(CMAKE_SHARED_LINKER_FLAGS "-r -nostdlib ${CMAKE_SHARED_LINKER_FLAGS}")
  endif()
endif()
set(CMAKE_FIND_ROOT_PATH 
  ${IOS_SYSROOT}
  ${CMAKE_PREFIX_PATH}
  CACHE string  "iOS find search path root" FORCE)

# Only search the specified iOS SDK, not the remainder of the host filesystem.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# This little macro lets you set any XCode specific property.
macro(set_xcode_property TARGET XCODE_PROPERTY XCODE_VALUE)
  set_property(TARGET ${TARGET} PROPERTY
    XCODE_ATTRIBUTE_${XCODE_PROPERTY} ${XCODE_VALUE})
endmacro(set_xcode_property)
# This macro lets you find executable programs on the host system.
macro(find_host_package)
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER)
  set(IOS FALSE)
  find_package(${ARGN})
  set(IOS TRUE)
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endmacro(find_host_package)

 # http://stackoverflow.com/questions/14171740/cmake-with-ios-toolchain-cant-find-threads
# http://public.kitware.com/Bug/view.php?id=12288
# Fix for try_compile
SET(CMAKE_MACOSX_BUNDLE YES)
SET(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "iPhone Developer")
# http://stackoverflow.com/questions/11198878/how-do-you-specify-a-universal-ios-application-when-building-through-cmake
SET(CMAKE_XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2")

# https://github.com/ruslo/polly/blob/master/os/iphone.cmake
#set(CMAKE_OSX_SYSROOT "iphoneos" CACHE STRING "System root for iOS" FORCE)
# Set iPhoneOS architectures
# Introduced in iOS 9.0
#
# https://github.com/psiha/build/blob/master/toolchains/apple.cmake
#add_compile_options( -fconstant-cfstrings -fobjc-call-cxx-cdtors )
#add_compile_options( -fno-function-sections ) #for bitcode
#

#link_libraries( $<$<CONFIG:RELEASE>:-dead_strip> )