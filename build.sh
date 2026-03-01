#!/bin/sh

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
  # Exclude decoder-only lib (libjxl_dec) to avoid duplicate symbols,
  # and exclude test/gtest libraries
  STATIC_LIBS=$(find . -name "*.a" -type f \
    ! -name "libjxl_dec*" \
    ! -name "*test*" ! -name "*gtest*" \
    ! -path "*/CMakeFiles/*")

  if [ ! -z "${STATIC_LIBS}" ]; then
    libtool -static -o libjxl-merged.a ${STATIC_LIBS}
    mv libjxl-merged.a libjxl.a
  fi

  # Copy public headers into the build output so they're always available
  mkdir -p include/jxl
  cp ../../libjxl/lib/include/jxl/*.h include/jxl/

  # Copy generated export headers (these are produced by cmake)
  for EXPORT_HEADER in $(find . -name "*_export.h" -path "*/jxl/*" -type f); do
    cp ${EXPORT_HEADER} include/jxl/
  done

  # For static builds, force JXL_STATIC_DEFINE so export macros resolve to nothing
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

  # Build fat binary for the merged static library
  for LIBRARY in libjxl.a; do
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
    if [ -f "build-visionos/${S}/libjxl.a" ]; then
      cp "build-visionos/${S}/libjxl.a" "${OUTPUT_PATH}/libjxl.a"
    fi
  done

  echo "=== visionOS build complete ==="
}

# Create a single XCFramework combining all platform slices
make_xcframework() {
  echo "=== Creating combined XCFramework ==="

  # Prepare headers from any available build slice
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

  HEADERS_DIR="${OUTPUT_DIR}/include"
  rm -rf ${HEADERS_DIR}
  mkdir -p ${HEADERS_DIR}/jxl
  cp ${HEADER_SOURCE}/include/jxl/*.h ${HEADERS_DIR}/jxl/

  # Write module map
cat <<EOT > ${HEADERS_DIR}/module.modulemap
module jxl [system] {
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

  # Collect all platform fat binaries into one XCFramework
  XCF_ARGS=""

  # iOS
  for SLICE in ios-device ios-simulator ios-mac-catalyst; do
    LIB="build-ios/ios-output/${SLICE}/libjxl.a"
    if [ -f "${LIB}" ]; then
      XCF_ARGS+="-library ${LIB} -headers ${HEADERS_DIR} "
    fi
  done

  # macOS
  LIB="build-macos/macos-output/macos/libjxl.a"
  if [ -f "${LIB}" ]; then
    XCF_ARGS+="-library ${LIB} -headers ${HEADERS_DIR} "
  fi

  # tvOS
  for SLICE in tvos-device tvos-simulator; do
    LIB="build-tvos/tvos-output/${SLICE}/libjxl.a"
    if [ -f "${LIB}" ]; then
      XCF_ARGS+="-library ${LIB} -headers ${HEADERS_DIR} "
    fi
  done

  # visionOS
  for SLICE in visionos-device-arm64 visionos-simulator-arm64; do
    LIB="build-visionos/visionos-output/${SLICE}/libjxl.a"
    if [ -f "${LIB}" ]; then
      XCF_ARGS+="-library ${LIB} -headers ${HEADERS_DIR} "
    fi
  done

  if [ -z "${XCF_ARGS}" ]; then
    echo "Error: No libraries found. Build platforms first."
    exit 1
  fi

  mkdir -p ${OUTPUT_DIR}
  rm -rf ${OUTPUT_DIR}/libjxl.xcframework
  xcodebuild -create-xcframework ${XCF_ARGS} -output ${OUTPUT_DIR}/libjxl.xcframework

  echo "=== XCFramework created at ${OUTPUT_DIR}/libjxl.xcframework ==="
}

package() {
  echo "=== Packaging ==="

  if [ ! -d "${OUTPUT_DIR}/libjxl.xcframework" ]; then
    echo "Error: No xcframework found. Run 'sh build.sh all' first."
    exit 1
  fi

  cd ${OUTPUT_DIR}
  zip -r -y libjxl.xcframework.zip libjxl.xcframework
  cd ${BASE_PATH}

  echo ""
  echo "=== Checksum ==="
  CHECKSUM=$(swift package compute-checksum ${OUTPUT_DIR}/libjxl.xcframework.zip)
  echo "libjxl.xcframework.zip: ${CHECKSUM}"

  echo ""
  echo "=== Packaging complete ==="
  echo "Output: ${OUTPUT_DIR}/libjxl.xcframework.zip"
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
