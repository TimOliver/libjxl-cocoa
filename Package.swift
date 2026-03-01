// swift-tools-version: 5.9

import PackageDescription

let version = "0.11.2"
let baseURL = "https://github.com/TimOliver/libjxl-cocoa/releases/download/\(version)"

let package = Package(
    name: "libjxl",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "jxl", targets: ["jxl"]),
    ],
    targets: [
        .binaryTarget(
            name: "jxl",
            url: "\(baseURL)/libjxl.xcframework.zip",
            checksum: "30dd27b0874d5c844c8d97c95c14b3b532abcd86e6f43da00bf5bd27c55b0f9b"
        ),
    ]
)
