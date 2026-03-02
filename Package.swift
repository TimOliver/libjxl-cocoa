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
            checksum: "5a5287ec0bc69a2143c2fae32d09873e78f6bb149e5490381a3a592b9d4c0338"
        ),
        .binaryTarget(
            name: "jxl-dynamic",
            url: "\(baseURL)/libjxl-v\(version)-xcframework-dynamic.zip",
            checksum: "40fd60662829d637c7ebe167ece5b276833c06e0f2b5a0736013a535d9d6a08d"
        ),
    ]
)
