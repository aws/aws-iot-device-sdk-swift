// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
// SPDX-License-Identifier: Apache-2.0.

// This file is generated

import PackageDescription

let package = Package(
    name: "IotShadowClient",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "IotShadowClient",
            targets: ["IotShadowClient"]
        )
    ],
    dependencies: [
        .package(path: "../../")
    ],
    targets: [
        .target(
            name: "IotShadowClient",
            dependencies: [
                .product(name: "AwsIotDeviceSdkSwift", package: "aws-iot-device-sdk-swift")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "IotShadowClientTests",
            dependencies: ["IotShadowClient"],
            path: "Tests"
        ),
    ]
)
