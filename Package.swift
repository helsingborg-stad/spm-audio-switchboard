// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AudioSwitchboard",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13)],
    products: [
        .library(
            name: "AudioSwitchboard",
            targets: ["AudioSwitchboard"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "AudioSwitchboard",
            dependencies: []),
        .testTarget(
            name: "AudioSwitchboardTests",
            dependencies: ["AudioSwitchboard"]),
    ]
)
