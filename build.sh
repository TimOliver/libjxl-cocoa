#!/bin/sh
set -e

# Print a list of all of the build options this script supports
usage() {
cat <<EOF
Usage: sh $0 command [argument]
command:
  all:              builds all frameworks and packages them
  ios:              builds iOS frameworks
  macos:            builds macOS frameworks
  tvos:             builds tvOS frameworks
  visionos:         builds visionOS frameworks
  xcframework:      creates combined xcframework from all built platforms
  package:          zips xcframeworks and computes checksums
EOF
}

# Global values
readonly BASE_PATH=$(pwd)
readonly LIBRARY_REPO="https://github.com/libjxl/libjxl.git"
readonly LIBRARY_DIR="libjxl"
readonly COMPILER=$(xcode-select -p)"/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
readonly CXX_COMPILER=$(xcode-select -p)"/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"
readonly OUTPUT_DIR="${BASE_PATH}/output"

# Read the tag from ENV, or default to the last verified stable version
LIBRARY_VERSION="0.11.2"
if [ ! -z "${LIBJXL_TAG_VERSION}" ]; then
  LIBRARY_VERSION=${LIBJXL_TAG_VERSION}
fi

# Verify Xcode and its build tools are available
readonly XCODE=$(xcodebuild -version | grep Xcode | cut -d " " -f2)
if [ -z "${XCODE}" ]; then
  echo "Xcode not available"
  exit 1
fi

# Clone the library source with all submodules
download_library() {
  if [ -d "${LIBRARY_DIR}" ]; then
    echo "Library directory already exists, skipping download"
    return
  fi

  echo "Cloning libjxl v${LIBRARY_VERSION}..."
  git clone --depth 1 --branch v${LIBRARY_VERSION} \
    --recurse-submodules --shallow-submodules \
    ${LIBRARY_REPO} ${LIBRARY_DIR}
}

build() {
  CMAKE_PATH=$1

  cd ${CMAKE_PATH}

  cmake -G"Unix Makefiles" \
    -DCMAKE_TOOLCHAIN_FILE=toolchain.cmake \
    -DCMAKE_SYSTEM_NAME=Darwin \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TESTING=OFF \
    -DJPEGXL_ENABLE_TOOLS=OFF \
    -DJPEGXL_ENABLE_JPEGLI=OFF \
    -DJPEGXL_ENABLE_DOXYGEN=OFF \
    -DJPEGXL_ENABLE_MANPAGES=OFF \
    -DJPEGXL_ENABLE_BENCHMARK=OFF \
    -DJPEGXL_ENABLE_EXAMPLES=OFF \
    -DJPEGXL_ENABLE_JNI=OFF \
    -DJPEGXL_ENABLE_OPENEXR=OFF \
    -DJPEGXL_ENABLE_SJPEG=OFF \
    -DJPEGXL_ENABLE_PLUGINS=OFF \
    -DJPEGXL_ENABLE_VIEWERS=OFF \
    -DJPEGXL_ENABLE_TCMALLOC=OFF \
    -DJPEGXL_ENABLE_COVERAGE=OFF \
    -DJPEGXL_ENABLE_FUZZERS=OFF \
    -DJPEGXL_ENABLE_DEVTOOLS=OFF \
    -DJPEGXL_ENABLE_SKCMS=ON \
    -DJPEGXL_ENABLE_TRANSCODE_JPEG=ON \
    -DJPEGXL_ENABLE_BOXES=ON \
    -DCMAKE_C_COMPILER=${COMPILER} \
    -DCMAKE_CXX_COMPILER=${CXX_COMPILER} \
    ../../libjxl
  make -j$(sysctl -n hw.ncpu)

  # Merge all static libraries into a single libjxl.a
  # Rename cmake's libjxl.a first so the find below doesn't pick up a
  # previously-merged archive on re-runs (which would cause duplicate symbols).
  # Exclude decoder-only lib (libjxl_dec) to avoid duplicate symbols,
  # and exclude test/gtest libraries.
  mv libjxl.a libjxl-cmake.a 2>/dev/null || true
  STATIC_LIBS=$(find . -name "*.a" -type f \
    ! -name "libjxl_dec*" \
    ! -name "libjxl.a" \
    ! -name "*test*" ! -name "*gtest*" \
    ! -path "*/CMakeFiles/*" \
    ! -path "*/tools/*")

  if [ ! -z "${STATIC_LIBS}" ]; then
    libtool -static -o libjxl.a ${STATIC_LIBS}
  fi

  # Create dynamic library from merged static archive
  SDK=$(grep 'xcrun --sdk' toolchain.cmake | sed "s/.*--sdk \([^ ]*\) .*/\1/")
  SYSROOT=$(xcrun --sdk ${SDK} --show-sdk-path)
  C_FLAGS=$(grep 'set(CMAKE_C_FLAGS' toolchain.cmake | sed 's/.*"\(.*\)".*/\1/')

  ${CXX_COMPILER} -dynamiclib \
    -install_name @rpath/jxl.framework/jxl \
    -isysroot ${SYSROOT} \
    ${C_FLAGS} \
    -Wl,-all_load libjxl.a \
    -lc++ \
    -o libjxl.dylib

  # Copy public headers into the build output
  mkdir -p include/jxl
  cp ../../libjxl/lib/include/jxl/*.h include/jxl/

  # Copy generated export headers (produced by cmake)
  for EXPORT_HEADER in $(find . -name "*_export.h" -path "*/jxl/*" -type f); do
    cp ${EXPORT_HEADER} include/jxl/
  done

  # Create dynamic headers (original, without JXL_STATIC_DEFINE)
  mkdir -p include-dynamic
  cp -r include/jxl include-dynamic/jxl

  # For static headers, force JXL_STATIC_DEFINE so export macros resolve to nothing
  for HEADER in jxl_export.h jxl_cms_export.h jxl_threads_export.h; do
    HEADER_FILE="include/jxl/${HEADER}"
    if [ -f "${HEADER_FILE}" ]; then
      { echo "#ifndef JXL_STATIC_DEFINE"; echo "#define JXL_STATIC_DEFINE"; echo "#endif"; echo ""; cat "${HEADER_FILE}"; } > "${HEADER_FILE}.tmp"
      mv "${HEADER_FILE}.tmp" "${HEADER_FILE}"
    fi
  done

  cd ${BASE_PATH}
}

make_fat_binary() {
  DIRECTORY=$1
  shift
  OUTPUT=$1
  shift
  SLICES=("$@")

  # Define the destination for the fat binary and make it
  OUTPUT_PATH=${DIRECTORY}"/"${OUTPUT}
  mkdir -p ${OUTPUT_PATH}

  # Build fat binaries for both static and dynamic libraries
  for LIBRARY in libjxl.a libjxl.dylib; do
    # Check if the library exists in the first slice
    FIRST_SLICE=${SLICES[0]}
    if [ ! -f "${DIRECTORY}/${FIRST_SLICE}/${LIBRARY}" ]; then
      continue
    fi

    LIBRARY_PATHS=""
    for S in ${SLICES[@]}; do
      LIBRARY_PATHS+=${DIRECTORY}"/"${S}"/"${LIBRARY}" "
    done

    lipo -create ${LIBRARY_PATHS} -output ${OUTPUT_PATH}"/"${LIBRARY}
  done
}

# Create a .framework bundle for a single platform slice
# Usage: create_jxl_framework FW_PATH LIB_PATH HEADERS_DIR MODULEMAP_FILE
create_jxl_framework() {
  FW=$1
  LIB=$2
  HEADERS_DIR=$3
  MODULEMAP_FILE=$4

  rm -rf "${FW}"
  mkdir -p "${FW}/Headers" "${FW}/Modules"
  cp "${LIB}" "${FW}/jxl"
  cp -R ${HEADERS_DIR}/* "${FW}/Headers/"
  cp "${MODULEMAP_FILE}" "${FW}/Modules/module.modulemap"

cat > "${FW}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>jxl</string>
  <key>CFBundleIdentifier</key>
  <string>org.libjxl.jxl</string>
  <key>CFBundleName</key>
  <string>jxl</string>
  <key>CFBundleVersion</key>
  <string>${LIBRARY_VERSION}</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
</dict>
</plist>
PLIST
}

# Write a Clang module map to the given file path
write_modulemap() {
cat <<EOT > $1
framework module jxl [system] {
  header "jxl/jxl_export.h"
  header "jxl/jxl_cms_export.h"
  header "jxl/jxl_threads_export.h"
  header "jxl/types.h"
  header "jxl/memory_manager.h"
  header "jxl/stats.h"
  header "jxl/cms.h"
  header "jxl/cms_interface.h"
  header "jxl/color_encoding.h"
  header "jxl/compressed_icc.h"
  header "jxl/codestream_header.h"
  header "jxl/decode.h"
  header "jxl/encode.h"
  header "jxl/gain_map.h"
  header "jxl/parallel_runner.h"
  header "jxl/thread_parallel_runner.h"
  header "jxl/resizable_parallel_runner.h"
  export *
}
EOT
}

# Create per-platform static and dynamic xcframeworks
make_platform_xcframework() {
  BUILD_DIR=$1
  shift
  HEADER_SOURCE=$1
  shift
  SLICES=("$@")

  # Stage headers and modulemap
  STATIC_HEADERS="${BUILD_DIR}/${HEADER_SOURCE}/include"
  DYNAMIC_HEADERS="${BUILD_DIR}/${HEADER_SOURCE}/include-dynamic"
  MODULEMAP_FILE="${BUILD_DIR}/module.modulemap"
  write_modulemap "${MODULEMAP_FILE}"

  STATIC_ARGS=""
  DYNAMIC_ARGS=""

  for SLICE in ${SLICES[@]}; do
    STATIC_LIB="${BUILD_DIR}/${SLICE}/libjxl.a"
    DYNAMIC_LIB="${BUILD_DIR}/${SLICE}/libjxl.dylib"

    if [ -f "${STATIC_LIB}" ]; then
      FW="${BUILD_DIR}/${SLICE}/static/jxl.framework"
      create_jxl_framework "${FW}" "${STATIC_LIB}" "${STATIC_HEADERS}" "${MODULEMAP_FILE}"
      STATIC_ARGS+="-framework ${FW} "
    fi
    if [ -f "${DYNAMIC_LIB}" ]; then
      FW="${BUILD_DIR}/${SLICE}/dynamic/jxl.framework"
      create_jxl_framework "${FW}" "${DYNAMIC_LIB}" "${DYNAMIC_HEADERS}" "${MODULEMAP_FILE}"
      DYNAMIC_ARGS+="-framework ${FW} "
    fi
  done

  mkdir -p "${BUILD_DIR}/static" "${BUILD_DIR}/dynamic"

  if [ ! -z "${STATIC_ARGS}" ]; then
    rm -rf "${BUILD_DIR}/static/jxl.xcframework"
    xcodebuild -create-xcframework ${STATIC_ARGS} \
      -output "${BUILD_DIR}/static/jxl.xcframework"
  fi

  if [ ! -z "${DYNAMIC_ARGS}" ]; then
    rm -rf "${BUILD_DIR}/dynamic/jxl.xcframework"
    xcodebuild -create-xcframework ${DYNAMIC_ARGS} \
      -output "${BUILD_DIR}/dynamic/jxl.xcframework"
  fi
}

build_ios() {
  echo "=== Building iOS ==="

  SLICES=("ios-device-arm64" "ios-simulator-x86" "ios-simulator-arm64" "ios-mac-catalyst-x86" "ios-mac-catalyst-arm64")

  # Build for each slice
  for S in ${SLICES[@]}; do
    build "build-ios/${S}"
  done

  # Combine each group of libraries into fat binaries
  SLICES=("ios-device-arm64")
  make_fat_binary "build-ios" "ios-output/ios-device" "${SLICES[@]}"

  SLICES=("ios-simulator-x86" "ios-simulator-arm64")
  make_fat_binary "build-ios" "ios-output/ios-simulator" "${SLICES[@]}"

  SLICES=("ios-mac-catalyst-x86" "ios-mac-catalyst-arm64")
  make_fat_binary "build-ios" "ios-output/ios-mac-catalyst" "${SLICES[@]}"

  # Per-platform xcframeworks (static + dynamic)
  make_platform_xcframework "build-ios" "ios-device-arm64" \
    "ios-output/ios-device" "ios-output/ios-simulator" "ios-output/ios-mac-catalyst"

  echo "=== iOS build complete ==="
}

build_macos() {
  echo "=== Building macOS ==="

  SLICES=("macos-arm64" "macos-x86")

  # Build for each slice
  for S in ${SLICES[@]}; do
    build "build-macos/${S}"
  done

  # Combine into fat binaries
  SLICES=("macos-arm64" "macos-x86")
  make_fat_binary "build-macos" "macos-output/macos" "${SLICES[@]}"

  # Per-platform xcframeworks (static + dynamic)
  make_platform_xcframework "build-macos" "macos-arm64" \
    "macos-output/macos"

  echo "=== macOS build complete ==="
}

build_tvos() {
  echo "=== Building tvOS ==="

  SLICES=("tvos-device-arm64" "tvos-simulator-arm64" "tvos-simulator-x86")

  # Build for each slice
  for S in ${SLICES[@]}; do
    build "build-tvos/${S}"
  done

  # Combine simulator slices into fat binaries
  SLICES=("tvos-device-arm64")
  make_fat_binary "build-tvos" "tvos-output/tvos-device" "${SLICES[@]}"

  SLICES=("tvos-simulator-arm64" "tvos-simulator-x86")
  make_fat_binary "build-tvos" "tvos-output/tvos-simulator" "${SLICES[@]}"

  # Per-platform xcframeworks (static + dynamic)
  make_platform_xcframework "build-tvos" "tvos-device-arm64" \
    "tvos-output/tvos-device" "tvos-output/tvos-simulator"

  echo "=== tvOS build complete ==="
}

build_visionos() {
  echo "=== Building visionOS ==="

  SLICES=("visionos-device-arm64" "visionos-simulator-arm64")

  # Build for each slice
  for S in ${SLICES[@]}; do
    build "build-visionos/${S}"
  done

  # Each slice is single-arch, no lipo needed — just copy
  for S in ${SLICES[@]}; do
    OUTPUT_PATH="build-visionos/visionos-output/${S}"
    mkdir -p ${OUTPUT_PATH}
    for LIBRARY in libjxl.a libjxl.dylib; do
      if [ -f "build-visionos/${S}/${LIBRARY}" ]; then
        cp "build-visionos/${S}/${LIBRARY}" "${OUTPUT_PATH}/${LIBRARY}"
      fi
    done
  done

  # Per-platform xcframeworks (static + dynamic)
  make_platform_xcframework "build-visionos" "visionos-device-arm64" \
    "visionos-output/visionos-device-arm64" "visionos-output/visionos-simulator-arm64"

  echo "=== visionOS build complete ==="
}

# Create combined XCFrameworks with all platform slices
make_xcframework() {
  echo "=== Creating combined XCFrameworks ==="

  # Find header source from any available build slice
  HEADER_SOURCE=""
  for DIR in build-ios/ios-device-arm64 build-macos/macos-arm64 build-tvos/tvos-device-arm64 build-visionos/visionos-device-arm64; do
    if [ -d "${DIR}/include/jxl" ]; then
      HEADER_SOURCE="${DIR}"
      break
    fi
  done

  if [ -z "${HEADER_SOURCE}" ]; then
    echo "Error: No build output found. Build at least one platform first."
    exit 1
  fi

  mkdir -p ${OUTPUT_DIR}

  # Stage headers
  STATIC_HEADERS="${OUTPUT_DIR}/include-static"
  DYNAMIC_HEADERS="${OUTPUT_DIR}/include-dynamic"
  rm -rf ${STATIC_HEADERS} ${DYNAMIC_HEADERS}
  mkdir -p ${STATIC_HEADERS}/jxl ${DYNAMIC_HEADERS}/jxl
  cp ${HEADER_SOURCE}/include/jxl/*.h ${STATIC_HEADERS}/jxl/
  cp ${HEADER_SOURCE}/include-dynamic/jxl/*.h ${DYNAMIC_HEADERS}/jxl/

  # Write module map
  MODULEMAP_FILE="${OUTPUT_DIR}/module.modulemap"
  write_modulemap "${MODULEMAP_FILE}"

  # Create both static and dynamic combined xcframeworks
  for VARIANT in static dynamic; do
    if [ "${VARIANT}" = "static" ]; then
      HEADERS="${STATIC_HEADERS}"
      EXT="a"
    else
      HEADERS="${DYNAMIC_HEADERS}"
      EXT="dylib"
    fi

    XCF_ARGS=""

    # iOS
    for SLICE in ios-device ios-simulator ios-mac-catalyst; do
      LIB="build-ios/ios-output/${SLICE}/libjxl.${EXT}"
      if [ -f "${LIB}" ]; then
        FW="build-ios/ios-output/${SLICE}/${VARIANT}/jxl.framework"
        create_jxl_framework "${FW}" "${LIB}" "${HEADERS}" "${MODULEMAP_FILE}"
        XCF_ARGS+="-framework ${FW} "
      fi
    done

    # macOS
    LIB="build-macos/macos-output/macos/libjxl.${EXT}"
    if [ -f "${LIB}" ]; then
      FW="build-macos/macos-output/macos/${VARIANT}/jxl.framework"
      create_jxl_framework "${FW}" "${LIB}" "${HEADERS}" "${MODULEMAP_FILE}"
      XCF_ARGS+="-framework ${FW} "
    fi

    # tvOS
    for SLICE in tvos-device tvos-simulator; do
      LIB="build-tvos/tvos-output/${SLICE}/libjxl.${EXT}"
      if [ -f "${LIB}" ]; then
        FW="build-tvos/tvos-output/${SLICE}/${VARIANT}/jxl.framework"
        create_jxl_framework "${FW}" "${LIB}" "${HEADERS}" "${MODULEMAP_FILE}"
        XCF_ARGS+="-framework ${FW} "
      fi
    done

    # visionOS
    for SLICE in visionos-device-arm64 visionos-simulator-arm64; do
      LIB="build-visionos/visionos-output/${SLICE}/libjxl.${EXT}"
      if [ -f "${LIB}" ]; then
        FW="build-visionos/visionos-output/${SLICE}/${VARIANT}/jxl.framework"
        create_jxl_framework "${FW}" "${LIB}" "${HEADERS}" "${MODULEMAP_FILE}"
        XCF_ARGS+="-framework ${FW} "
      fi
    done

    if [ -z "${XCF_ARGS}" ]; then
      echo "Warning: No ${VARIANT} libraries found for combined xcframework."
      continue
    fi

    rm -rf "${OUTPUT_DIR}/jxl-${VARIANT}.xcframework"
    xcodebuild -create-xcframework ${XCF_ARGS} \
      -output "${OUTPUT_DIR}/jxl-${VARIANT}.xcframework"

    echo "=== Created ${OUTPUT_DIR}/jxl-${VARIANT}.xcframework ==="
  done
}

package() {
  echo "=== Packaging ==="

  mkdir -p ${OUTPUT_DIR}

  # Package per-platform xcframeworks (8 zips)
  for PLATFORM in ios macos tvos visionos; do
    for VARIANT in static dynamic; do
      XCF="build-${PLATFORM}/${VARIANT}/jxl.xcframework"
      if [ -d "${XCF}" ]; then
        ZIP_NAME="libjxl-v${LIBRARY_VERSION}-xcframework-${PLATFORM}-${VARIANT}.zip"
        cd "build-${PLATFORM}/${VARIANT}"
        zip -r -y "${OUTPUT_DIR}/${ZIP_NAME}" jxl.xcframework
        cd ${BASE_PATH}
        echo "${ZIP_NAME}: $(swift package compute-checksum "${OUTPUT_DIR}/${ZIP_NAME}")"
      fi
    done
  done

  # Package combined xcframeworks (2 zips)
  for VARIANT in static dynamic; do
    XCF="${OUTPUT_DIR}/jxl-${VARIANT}.xcframework"
    if [ -d "${XCF}" ]; then
      ZIP_NAME="libjxl-v${LIBRARY_VERSION}-xcframework-${VARIANT}.zip"
      cd ${OUTPUT_DIR}
      zip -r -y "${ZIP_NAME}" "jxl-${VARIANT}.xcframework"
      cd ${BASE_PATH}
      echo "${ZIP_NAME}: $(swift package compute-checksum "${OUTPUT_DIR}/${ZIP_NAME}")"
    fi
  done

  echo ""
  echo "=== Packaging complete ==="
}

# Commands
COMMAND="$1"
case "$COMMAND" in

    "all")
        download_library
        build_ios
        build_macos
        build_tvos
        build_visionos
        make_xcframework
        package
        exit 0
        ;;

    "ios")
        download_library
        build_ios
        exit 0
        ;;

    "macos")
        download_library
        build_macos
        exit 0
        ;;

    "tvos")
        download_library
        build_tvos
        exit 0
        ;;

    "visionos")
        download_library
        build_visionos
        exit 0
        ;;

    "xcframework")
        make_xcframework
        exit 0
        ;;

    "package")
        package
        exit 0
        ;;
esac

# Print usage instructions if no arguments were set
if [ "$#" -eq 0 -o "$#" -gt 3 ]; then
    usage
    exit 1
fi
