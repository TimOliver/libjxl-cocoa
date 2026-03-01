execute_process(COMMAND xcrun --sdk macosx --show-sdk-path OUTPUT_VARIABLE SYSROOT)
string(STRIP ${SYSROOT} SYSROOT)

set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_C_FLAGS "-Wall -arch arm64 -funwind-tables -miphoneos-version-min=16.0 -target aarch64-apple-ios16.0-macabi")
set(CMAKE_CXX_FLAGS "-Wall -arch arm64 -funwind-tables -miphoneos-version-min=16.0 -target aarch64-apple-ios16.0-macabi")
set(CMAKE_OSX_SYSROOT "${SYSROOT}")
