// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AwsIotDeviceSdkSwift",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "AwsIotDeviceSdkSwift",
            targets: ["AwsIotDeviceSdkSwift"]),
        .library(
            name: "IotShadowClient",
            targets: ["IotShadowClient"]),
    ],
    dependencies: [
        .package(
            // url: "https://github.com/awslabs/aws-crt-swift.git", .upToNextMajor(from: "0.49.1"))
            url: "https://github.com/awslabs/aws-crt-swift.git", branch: "rr_streaming")  // TODO WIP revert this to point to the main branch
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
            dependencies: ["AwsIotDeviceSdkSwift"],
            path: "Tests/AwsIotDeviceSdkSwiftTests"
        ),
        .target(
            name: "IotShadowClient",
            dependencies: [
                .target(name: "AwsIotDeviceSdkSwift")
            ],
            path: "ServiceClients/AwsIotShadowClient"
        ),
        .testTarget(
            name: "IotShadowClientTests",
            dependencies: ["IotShadowClient"],
            path: "Tests/IotShadowClientTests"
        ),
    ]
)
