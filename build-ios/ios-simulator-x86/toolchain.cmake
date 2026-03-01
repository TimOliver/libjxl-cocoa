execute_process(COMMAND xcrun --sdk iphonesimulator --show-sdk-path OUTPUT_VARIABLE SYSROOT)
string(STRIP ${SYSROOT} SYSROOT)

set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(CMAKE_C_FLAGS "-Wall -arch x86_64 -miphoneos-version-min=16.0 -target x86_64-apple-ios-simulator -funwind-tables")
set(CMAKE_CXX_FLAGS "-Wall -arch x86_64 -miphoneos-version-min=16.0 -target x86_64-apple-ios-simulator -funwind-tables")
set(CMAKE_OSX_SYSROOT "${SYSROOT}")
