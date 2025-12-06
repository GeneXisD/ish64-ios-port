cmake_minimum_required(VERSION 3.25)
project(ish64_ios C OBJC)

# iOS cross settings
set(CMAKE_SYSTEM_NAME iOS)
set(CMAKE_OSX_SYSROOT iphoneos)
set(CMAKE_OSX_ARCHITECTURES arm64)
set(CMAKE_IOS_INSTALL_COMBINED YES)
set(CMAKE_OSX_DEPLOYMENT_TARGET 16.0)

# Where the main iSH sources live relative to ios/
set(ISH_ROOT "${CMAKE_SOURCE_DIR}/..")

# Pull in the core C code (adjust these globs as needed)
file(GLOB_RECURSE ISH_CORE_SOURCES
# The VDSO object depends on a generated libvdso.so.elf incbin and
# Meson-specific build steps. Our iOS CMake bridge does not yet
# generate that, so exclude vdso.c for now.
list(FILTER ISH_CORE_SOURCES EXCLUDE REGEX ".*/vdso\\.c$")
    "${ISH_ROOT}/kernel/*.c"
    "${ISH_ROOT}/fs/*.c"
    "${ISH_ROOT}/emu/*.c"
    "${ISH_ROOT}/util/*.c"
    "${ISH_ROOT}/misc/*.c"
)
# Exclude VDSO integration for iOS:
# kernel/vdso.c wants a generated vdso/libvdso.so.elf (Meson-only step).
# Our CMake/Xcode iOS bridge doesn't build that yet, so skip vdso.c here.
list(FILTER ISH_CORE_SOURCES EXCLUDE REGEX ".*/vdso\\.c$")

# Static library for the core emulator + syscall/fs/kernel bits
add_library(ishcore STATIC ${ISH_CORE_SOURCES})

target_include_directories(ishcore PUBLIC
    "${ISH_ROOT}"
    "${ISH_ROOT}/include"
    "${ISH_ROOT}/kernel"
    "${ISH_ROOT}/fs"
    "${ISH_ROOT}/emu"
    "${ISH_ROOT}/util"
)

# iOS app executable
add_executable(ish64_ios
    "${CMAKE_SOURCE_DIR}/main.m"
)

set_source_files_properties("${CMAKE_SOURCE_DIR}/main.m" PROPERTIES
    LANGUAGE OBJC
)

target_link_libraries(ish64_ios
    ishcore
    "-framework UIKit"
    "-framework Foundation"
)

set_target_properties(ish64_ios PROPERTIES
    MACOSX_BUNDLE YES
    MACOSX_BUNDLE_GUI_IDENTIFIER "net.ritualmesh.ish64.ios"
    MACOSX_BUNDLE_BUNDLE_NAME "iSH64 iOS"
    MACOSX_BUNDLE_INFO_PLIST ""
)
