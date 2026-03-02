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
            url: "\(baseURL)/libjxl-static.xcframework.zip",
            checksum: "31faccd94363c373356c325f391ddde10469f6d87956777fbc172b72ff8b1f83"
        ),
        .binaryTarget(
            name: "jxl-dynamic",
            url: "\(baseURL)/libjxl-dynamic.xcframework.zip",
            checksum: "194cfed026bf1e92366487f3ec81bc77ce6fe1862c4c57cf515e2bba28f2a13a"
        ),
    ]
)
