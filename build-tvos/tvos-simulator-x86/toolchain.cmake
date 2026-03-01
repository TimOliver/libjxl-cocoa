execute_process(COMMAND xcrun --sdk appletvsimulator --show-sdk-path OUTPUT_VARIABLE SYSROOT)
string(STRIP ${SYSROOT} SYSROOT)

set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(CMAKE_C_FLAGS "-Wall -arch x86_64 -mtvos-version-min=16.0 -target x86_64-apple-tvos-simulator -funwind-tables")
set(CMAKE_CXX_FLAGS "-Wall -arch x86_64 -mtvos-version-min=16.0 -target x86_64-apple-tvos-simulator -funwind-tables")
set(CMAKE_OSX_SYSROOT "${SYSROOT}")
