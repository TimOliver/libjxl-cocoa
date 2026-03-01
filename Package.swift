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
    ],
    targets: [
        .binaryTarget(
            name: "jxl",
            url: "\(baseURL)/libjxl.xcframework.zip",
            checksum: "TODO"
        ),
    ]
)
