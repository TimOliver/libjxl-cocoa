# libjxl for Apple Platforms

Pre-built [libjxl](https://github.com/libjxl/libjxl) (JPEG XL) xcframework for Apple platforms, distributed via Swift Package Manager.

## Supported Platforms

| Platform | Architectures | Minimum Version |
|----------|--------------|-----------------|
| iOS | arm64 | 16.0 |
| iOS Simulator | arm64, x86_64 | 16.0 |
| Mac Catalyst | arm64, x86_64 | 16.0 |
| macOS | arm64, x86_64 | 13.0 |
| tvOS | arm64 | 16.0 |
| tvOS Simulator | arm64, x86_64 | 16.0 |
| visionOS | arm64 | 1.0 |
| visionOS Simulator | arm64 | 1.0 |

## Library

A single static XCFramework containing the full libjxl encoder, decoder, threading support, and all bundled dependencies (Highway, Brotli, skcms). All platforms are combined into one XCFramework.

## Swift Package Manager

Add this package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/TimOliver/libjxl-cocoa.git", from: "0.11.1")
]
```

Then add it to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "jxl", package: "libjxl-cocoa"),
    ]
)
```

Or add it via Xcode: File > Add Package Dependencies, and enter the repository URL.

### Linking Note

libjxl is a C++ library with a C API. When linking the static library, your project must also link against the C++ standard library (`libc++`). Xcode typically handles this automatically, but if you encounter linker errors, add `-lc++` to your "Other Linker Flags" build setting.

## Building from Source

### Prerequisites

- Xcode (with command-line tools)
- CMake
- Git

### Build Commands

```sh
# Build all platforms and package
sh build.sh all

# Build a single platform
sh build.sh ios
sh build.sh macos
sh build.sh tvos
sh build.sh visionos

# Create combined xcframework from already-built platforms
sh build.sh xcframework

# Package xcframework into zip with checksum
sh build.sh package
```

### Custom Version

Override the libjxl version with an environment variable:

```sh
LIBJXL_TAG_VERSION=0.11.0 sh build.sh all
```

Default version: **0.11.1**

## Output

After running `sh build.sh all`, you'll find:

- `output/libjxl.xcframework` — Combined XCFramework with all platforms
- `output/libjxl.xcframework.zip` — Zipped for distribution

## CI / Releases

Releases are built via a GitHub Actions workflow (`build.yml`), triggered manually with a version number input. The workflow builds all platforms and uploads the xcframework zip as a release asset.

## License

This build system is released under the BSD 3-Clause License. libjxl itself is distributed under the BSD 3-Clause License — see the [libjxl license](https://github.com/libjxl/libjxl/blob/main/LICENSE) for details.
