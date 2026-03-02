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
            checksum: "cd8455b3295bfb872ffc1fc5d334bb491545b18088b1c111328a9ddda52da60f"
        ),
        .binaryTarget(
            name: "jxl-dynamic",
            url: "\(baseURL)/libjxl-v\(version)-xcframework-dynamic.zip",
            checksum: "b47e3895abc46004ed51ffa136c89bc8cf0420c59f27c594974b336dde33b79b"
        ),
    ]
)
