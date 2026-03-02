# libjxl for Apple Platforms

Pre-built [libjxl](https://github.com/libjxl/libjxl) (JPEG XL) XCFrameworks for Apple platforms, distributed via Swift Package Manager.

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

- **Static** (`jxl`) — linked into your binary at build time.
- **Dynamic** (`jxl-dynamic`) — loaded at runtime.

## Swift Package Manager

Add this package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/TimOliver/libjxl-cocoa.git", from: "0.11.2")
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

Or add it via Xcode: **File > Add Package Dependencies**, and enter the repository URL.

### Linking Note

When using the **static** library, your project must also link against the C++ standard library (`libc++`). Xcode typically handles this automatically, but if you encounter linker errors, add `-lc++` to your "Other Linker Flags" build setting. This is not required for the dynamic variant.

## Manual Download

Per-platform XCFrameworks are available as individual downloads from each [release](https://github.com/TimOliver/libjxl-cocoa/releases). Files follow the naming pattern `libjxl-v{version}-xcframework-{platform}-{static|dynamic}.zip`:

| Platform | Static | Dynamic |
|----------|--------|---------|
| iOS | `libjxl-v{version}-xcframework-ios-static.zip` | `libjxl-v{version}-xcframework-ios-dynamic.zip` |
| macOS | `libjxl-v{version}-xcframework-macos-static.zip` | `libjxl-v{version}-xcframework-macos-dynamic.zip` |
| tvOS | `libjxl-v{version}-xcframework-tvos-static.zip` | `libjxl-v{version}-xcframework-tvos-dynamic.zip` |
| visionOS | `libjxl-v{version}-xcframework-visionos-static.zip` | `libjxl-v{version}-xcframework-visionos-dynamic.zip` |

## Building from Source

### Prerequisites

- Xcode (with command-line tools)
- CMake (`brew install cmake`)
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
- `jxl.xcframework` — static or dynamic XCFramework for a single platform

**Combined** (in `output/`):
- `jxl-static.xcframework` — static XCFramework with all platforms
- `jxl-dynamic.xcframework` — dynamic XCFramework with all platforms

**Zips** (in `output/`):
- 8 per-platform zips (e.g. `libjxl-v0.11.2-xcframework-ios-static.zip`)
- 2 combined zips (`libjxl-v0.11.2-xcframework-static.zip`, `libjxl-v0.11.2-xcframework-dynamic.zip`)

## CI / Releases

Releases are built via a GitHub Actions workflow (`.github/workflows/build.yml`), triggered manually with a version number input. The workflow builds all platforms, updates `Package.swift` with the new version and checksums, commits, and uploads all 10 zip files as release assets.

## License

This build system is released under the BSD 3-Clause License. libjxl itself is distributed under the BSD 3-Clause License — see the [libjxl license](https://github.com/libjxl/libjxl/blob/main/LICENSE) for details.
