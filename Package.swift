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
            checksum: "1417fb1265df07068116de4fe4c041e1e2920471554b0dca062b42f81ba7f56d"
        ),
        .binaryTarget(
            name: "jxl-dynamic",
            url: "\(baseURL)/libjxl-v\(version)-xcframework-dynamic.zip",
            checksum: "04ed73cc6fd9abe8f76c3420f5165e4bf9e70be00608524aea076eff6e69e9fc"
        ),
    ]
)
