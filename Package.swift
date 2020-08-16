// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-mqtt",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "MQTT", targets: ["MQTT"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.20.2"),
    ],
    targets: [
        .target(
            name: "MQTT",
            dependencies: [.product(name: "NIO", package: "swift-nio")]
        ),
        .testTarget(
            name: "MQTTTests",
            dependencies: ["MQTT"]
        ),
        .target(
            name: "client",
            dependencies: ["MQTT"]
        ),
    ]
)
