// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-mqtt",
    products: [
        .library(name: "MQTT", targets: ["MQTT"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "MQTT",
            dependencies: [
              .product(name: "NIO", package: "swift-nio"),
              .product(name: "NIOSSL", package: "swift-nio-ssl"),
            ]
        ),
        .testTarget(
            name: "MQTTTests",
            dependencies: ["MQTT"]
        ),
        .target(
            name: "SampleClient",
            dependencies: ["MQTT"]
        ),
    ]
)
