// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "BasicProvisioningSample",
  platforms: [
    .iOS(.v13),
    .macOS(.v12),
    .tvOS(.v13),
  ],
  products: [
    .executable(name: "BasicProvisioningSample", targets: ["BasicProvisioningSample"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/aws/aws-iot-device-sdk-swift",
      // TODO WIP Use the correct URL for your AWS IoT Device SDK Swift repo
      branch: "codegen"),
    // This package gives us the capability to do a argument parsing
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .executableTarget(
      name: "BasicProvisioningSample",
      dependencies: [
        .product(name: "IotIdentityClient", package: "aws-iot-device-sdk-swift"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "Sources")
  ]
)
