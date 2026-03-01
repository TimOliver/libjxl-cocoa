// swift-tools-version: 5.9

import PackageDescription

let version = "0.11.1"
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
            url: "\(baseURL)/libjxl-static.xcframework.zip",
            checksum: "TODO"
        ),
        .binaryTarget(
            name: "jxl-dynamic",
            url: "\(baseURL)/libjxl-dynamic.xcframework.zip",
            checksum: "TODO"
        ),
    ]
)
