// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShadowClient",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "ShadowClient", 
            targets: ["ShadowClient"])
    ],
    dependencies: [
        .package(path: "../../")
    ],
    targets: [
        .target(
            name: "ShadowClient",
            dependencies: [
                .product(name: "AwsIotDeviceSdkSwift", package: "aws-iot-device-sdk-swift")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "ShadowClientTests",
            dependencies: ["ShadowClient"],
            path: "Tests"
        )
    ]
)
