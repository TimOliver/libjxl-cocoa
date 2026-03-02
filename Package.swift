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
        .library(name: "jxl-dynamic", targets: ["jxl-dynamic"]),
    ],
    targets: [
        .binaryTarget(
            name: "jxl",
            url: "\(baseURL)/libjxl-v\(version)-xcframework-static.zip",
            checksum: "8e3a51094079e9070fc81163c8a5ac5e0e9d745a05cb279c1122e7c796be74c8"
        ),
        .binaryTarget(
            name: "jxl-dynamic",
            url: "\(baseURL)/libjxl-v\(version)-xcframework-dynamic.zip",
            checksum: "c9b879f8a2581ae25e54c8b6a5f0542e5ac9ca55d22874e7687c38fd868fa443"
        ),
    ]
)
