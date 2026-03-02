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
            checksum: "dc0ccce822232eb16f50a4ed0b83345d67612d40e5c8f1c0b62a992244f9be40"
        ),
        .binaryTarget(
            name: "jxl-dynamic",
            url: "\(baseURL)/libjxl-v\(version)-xcframework-dynamic.zip",
            checksum: "1b7aa9e932e9cece8dd58a3150c1287439b544017422dee7f2b3bee2845cc9e8"
        ),
    ]
)
