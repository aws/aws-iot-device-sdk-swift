// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
// SPDX-License-Identifier: Apache-2.0.

// This file is generated

import PackageDescription

let package = Package(
    name: "IotJobsClient",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "IotJobsClient",
            targets: ["IotJobsClient"]
        )
    ],
    dependencies: [
        .package(path: "../../")
    ],
    targets: [
        .target(
            name: "IotJobsClient",
            dependencies: [
                .product(name: "AwsIotDeviceSdkSwift", package: "aws-iot-device-sdk-swift")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "IotJobsClientTests",
            dependencies: ["IotJobsClient"],
            path: "Tests"
        ),
    ]
)
