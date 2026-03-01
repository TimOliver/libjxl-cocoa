# libjxl for Apple Platforms

Pre-built [libjxl](https://github.com/libjxl/libjxl) (JPEG XL) xcframeworks for Apple platforms, distributed via Swift Package Manager.

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

Both **static** and **dynamic** XCFrameworks are provided, each containing the full libjxl encoder, decoder, threading support, and all bundled dependencies (Highway, Brotli, skcms).

- **Static** (`jxl`) — linked into your binary at build time. Requires linking `libc++` (Xcode handles this automatically in most cases).
- **Dynamic** (`jxl-dynamic`) — loaded at runtime. No additional linker flags needed.

## Swift Package Manager

Add this package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/TimOliver/libjxl-cocoa.git", from: "0.11.1")
]
```

Then add either the static or dynamic product to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        // Static (default)
        .product(name: "jxl", package: "libjxl-cocoa"),

        // — or dynamic —
        // .product(name: "jxl-dynamic", package: "libjxl-cocoa"),
    ]
)
```

Or add it via Xcode: File > Add Package Dependencies, and enter the repository URL.

### Linking Note

When using the **static** library, your project must also link against the C++ standard library (`libc++`). Xcode typically handles this automatically, but if you encounter linker errors, add `-lc++` to your "Other Linker Flags" build setting. This is not required for the dynamic variant.

## Manual Download

Per-platform XCFrameworks are available as individual downloads from each [release](https://github.com/TimOliver/libjxl-cocoa/releases):

| Platform | Static | Dynamic |
|----------|--------|---------|
| iOS | `libjxl-ios-static.xcframework.zip` | `libjxl-ios-dynamic.xcframework.zip` |
| macOS | `libjxl-macos-static.xcframework.zip` | `libjxl-macos-dynamic.xcframework.zip` |
| tvOS | `libjxl-tvos-static.xcframework.zip` | `libjxl-tvos-dynamic.xcframework.zip` |
| visionOS | `libjxl-visionos-static.xcframework.zip` | `libjxl-visionos-dynamic.xcframework.zip` |

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

# Create combined xcframeworks from already-built platforms
sh build.sh xcframework

# Package all xcframeworks into zips with checksums
sh build.sh package
```

### Custom Version

Override the libjxl version with an environment variable:

```sh
LIBJXL_TAG_VERSION=0.11.0 sh build.sh all
```

Default version: **0.11.2**

## Output

After running `sh build.sh all`, you'll find:

**Per-platform** (in `build-<platform>/static/` and `build-<platform>/dynamic/`):
- `libjxl.xcframework` — Static or dynamic framework for a single platform

**Combined** (in `output/`):
- `libjxl-static.xcframework` — Static XCFramework with all platforms
- `libjxl-dynamic.xcframework` — Dynamic XCFramework with all platforms

**Zips** (in `output/`):
- 8 per-platform zips (e.g., `libjxl-ios-static.xcframework.zip`)
- 2 combined zips (`libjxl-static.xcframework.zip`, `libjxl-dynamic.xcframework.zip`)

## CI / Releases

Releases are built via a GitHub Actions workflow (`build.yml`), triggered manually with a version number input. The workflow builds all platforms and uploads all 10 xcframework zips as release assets.

## License

This build system is released under the BSD 3-Clause License. libjxl itself is distributed under the BSD 3-Clause License — see the [libjxl license](https://github.com/libjxl/libjxl/blob/main/LICENSE) for details.
