# libjxl-cocoa

Native-compiled [libjxl](https://github.com/libjxl/libjxl) as static and dynamic XCFrameworks for Apple platforms, distributed via Swift Package Manager.

## Build

Requires cmake (`brew install cmake`) and Xcode. On this machine Xcode is at `/Applications/Xcode-beta.app` — ensure it's the active developer directory:

```sh
sudo xcode-select -s /Applications/Xcode-beta.app/Contents/Developer
export PATH="/opt/homebrew/bin:$PATH"
sh build.sh all
```

### Build commands

| Command | Description |
|---------|-------------|
| `all` | Full build: all platforms + combined xcframeworks + zip |
| `ios` / `macos` / `tvos` / `visionos` | Build a single platform |
| `xcframework` | Assemble combined xcframeworks from built platform outputs |
| `package` | Zip xcframeworks and compute SPM checksums |

Between re-runs, clean build artifacts (keeping toolchain files) to avoid duplicate-symbol issues:

```sh
for dir in build-ios/ios-device-arm64 build-ios/ios-simulator-arm64 build-ios/ios-simulator-x86 \
            build-ios/ios-mac-catalyst-arm64 build-ios/ios-mac-catalyst-x86 \
            build-macos/macos-arm64 build-macos/macos-x86 \
            build-tvos/tvos-device-arm64 build-tvos/tvos-simulator-arm64 build-tvos/tvos-simulator-x86 \
            build-visionos/visionos-device-arm64 build-visionos/visionos-simulator-arm64; do
  find "$dir" -mindepth 1 ! -name 'toolchain.cmake' -delete
done
rm -rf build-*/ios-output build-*/macos-output build-*/tvos-output build-*/visionos-output
rm -rf build-*/static build-*/dynamic output
```

## Project structure

- `build-{platform}/{slice}/toolchain.cmake` — cmake toolchain files, committed to the repo
- `output/` — final zip artifacts (git-ignored)

## Naming conventions

- Framework bundles: always `jxl.framework` with binary named `jxl`
- Per-platform xcframeworks: `jxl.xcframework` inside `build-{platform}/static/` or `build-{platform}/dynamic/`
- Combined xcframeworks: `jxl-static.xcframework` / `jxl-dynamic.xcframework` in `output/`
- **Zip artifacts**: `libjxl-v{version}-xcframework-{static|dynamic}.zip` (combined), `libjxl-v{version}-xcframework-{platform}-{static|dynamic}.zip` (per-platform)

## SPM products

| Product | Type | Target |
|---------|------|--------|
| `jxl` | static | `jxl` binary target |
| `jxl-dynamic` | dynamic | `jxl-dynamic` binary target |

## CI

GitHub Actions workflow at `.github/workflows/build.yml`, triggered manually with a `version` input. Runs on `macos-26`, installs cmake via brew, downloads tvOS/visionOS SDKs, builds, updates `Package.swift` checksums, commits, and creates a GitHub release.

- The checksum step matches on the stable suffix `xcframework-{variant}.zip` in `Package.swift` (since the URL contains Swift string interpolation `\(version)` which won't match a literal filename).
- The release upload uses `output/*.zip` (not `*.xcframework.zip`) to match the versioned filenames.
- The commit step runs `git pull --rebase` before `git push` to handle any commits pushed to `main` during the build (e.g. README updates).

## Known issues / fixes applied

- `build.sh` has `set -e` — any cmake/make/xcodebuild failure stops the script immediately
- The `C_FLAGS` sed extraction uses `s/.*"\(.*\)".*/\1/` (trailing `.*` is required to consume the closing `)` of the cmake `set(...)` call)
- Before merging static libs with `libtool`, `libjxl.a` is renamed to `libjxl-cmake.a` to prevent double-merging on re-runs
- `tools/` is excluded from the `libtool` merge to avoid duplicate `enc_fast_lossless.cc.o` symbols
- Static and dynamic frameworks are staged in `{slice}/static/` and `{slice}/dynamic/` subdirectories so both can be named `jxl.framework` without colliding
