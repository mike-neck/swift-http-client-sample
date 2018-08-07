// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HTTP-CLIENT",
    products: [
        .executable(
            name: "HTTP-CLIENT",
            targets: ["HTTP-CLIENT"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.7.2")
    ],
    targets: [
        .target(
            name: "HTTP-CLIENT",
            dependencies: ["NIO", "NIOHTTP1"]),
        .testTarget(
            name: "HTTP-CLIENTTests",
            dependencies: ["HTTP-CLIENT"]),
    ]
)
