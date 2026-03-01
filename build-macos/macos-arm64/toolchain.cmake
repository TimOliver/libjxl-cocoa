execute_process(COMMAND xcrun --sdk macosx --show-sdk-path OUTPUT_VARIABLE SYSROOT)
string(STRIP ${SYSROOT} SYSROOT)

set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_C_FLAGS "-Wall -arch arm64 -mmacosx-version-min=13.0 -funwind-tables")
set(CMAKE_CXX_FLAGS "-Wall -arch arm64 -mmacosx-version-min=13.0 -funwind-tables")
set(CMAKE_OSX_SYSROOT "${SYSROOT}")
