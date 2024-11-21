// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "aws-iot-device-sdk-swift",
    platforms: [
        .iOS(.v13), 
        .macOS(.v10_15), 
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "aws-iot-device-sdk-swift",
            targets: ["aws-iot-device-sdk-swift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/awslabs/aws-crt-swift.git", branch: "secitem_bindings"), // DEBUG WIP change 'branch' to `from: "aws-crt-swift version number"` when crt is updated.
    ],
    targets: [
        .target(
            name: "aws-iot-device-sdk-swift",
            dependencies: [
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift")
            ]
        ),
        .testTarget(
            name: "aws-iot-device-sdk-swiftTests",
            dependencies: ["aws-iot-device-sdk-swift"]
        ),
    ]
)
