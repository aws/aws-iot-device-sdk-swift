// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AwsIotDeviceSdkSwift",
    platforms: [
        .iOS(.v13), 
        .macOS(.v10_15), 
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "AwsIotDeviceSdkSwift",
            targets: ["AwsIotDeviceSdkSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/awslabs/aws-crt-swift.git", branch: "secitem_bindings"), // DEBUG WIP change 'branch' to `from: "aws-crt-swift version number"` when crt is updated.
    ],
    targets: [
        .target(
            name: "AwsIotDeviceSdkSwift",
            dependencies: [
                .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "AwsIotDeviceSdkSwiftTests",
            dependencies: ["AwsIotDeviceSdkSwift"]
        ),
    ]
)
