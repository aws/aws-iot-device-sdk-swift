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
            path: "../aws-crt-swift"),
        .package(url: "https://github.com/awslabs/aws-sdk-swift.git", from: "1.3.19")
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
        .target(
            name: "IotJobsClient",
            dependencies: [
                .target(name: "AwsIotDeviceSdkSwift")
            ],
            path: "ServiceClients/AwsIotJobsClient"
        ),
        .testTarget(
            name: "IotJobsClientTests",
            dependencies: [
                "IotJobsClient",
                .product(name:"AWSIoT", package: "aws-sdk-swift")
            ],
            path: "Tests/IotJobsClientTests"),
        .target(
            name: "IotIdentityClient",
            dependencies: [
                .target(name: "AwsIotDeviceSdkSwift")
            ],
            path: "ServiceClients/AwsIotIdentityClient"
        ),
    ]
)
