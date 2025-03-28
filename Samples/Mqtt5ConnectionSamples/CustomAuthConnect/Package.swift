// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CustomAuthConnect",
        platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13)
    ],
    products: [
        .executable(name: "CustomAuthConnect", targets: ["CustomAuthConnect"])
    ],
    dependencies: [
        .package(path: "../../../"), // TODO: DEBUG WIP change 'branch' to `from: "aws-crt-swift version number"` when crt is updated.
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0") // This package gives us the capability to do a argument parsing
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "CustomAuthConnect",
            dependencies: [
                .product(name: "AwsIotDeviceSdkSwift", package: "aws-iot-device-sdk-swift"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources")
    ]
)
