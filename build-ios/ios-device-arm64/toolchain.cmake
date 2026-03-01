execute_process(COMMAND xcrun --sdk iphoneos --show-sdk-path OUTPUT_VARIABLE SYSROOT)
string(STRIP ${SYSROOT} SYSROOT)

set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_C_FLAGS "-Wall -arch arm64 -miphoneos-version-min=16.0 -funwind-tables")
set(CMAKE_CXX_FLAGS "-Wall -arch arm64 -miphoneos-version-min=16.0 -funwind-tables")
set(CMAKE_OSX_SYSROOT "${SYSROOT}")
