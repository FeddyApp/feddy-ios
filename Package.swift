// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Feddy",
    platforms: [
        .iOS(.v14),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Feddy",
            targets: ["Feddy"]),
    ],
    targets: [
        .target(
            name: "Feddy"),
        .testTarget(
            name: "Feddy-iosTests",
            dependencies: ["Feddy"]
        ),
    ]
)
