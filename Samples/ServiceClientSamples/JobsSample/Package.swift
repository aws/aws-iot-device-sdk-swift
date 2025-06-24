// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "JobsSample",
  platforms: [
    .iOS(.v13),
    .macOS(.v12),
    .tvOS(.v13),
  ],
  products: [
    .executable(name: "JobsSample", targets: ["JobsSample"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/aws/aws-iot-device-sdk-swift", .upToNextMajor(from: "0.3.0")),
    // This package gives us the capability to do a argument parsing
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    .package(
      url: "https://github.com/awslabs/aws-sdk-swift.git",
      branch: "aws-iot-device-sdk-swift-testing-branch"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .executableTarget(
      name: "JobsSample",
      dependencies: [
        .product(name: "IotJobsClient", package: "aws-iot-device-sdk-swift"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "AWSIoT", package: "aws-sdk-swift"),
      ],
      path: "Sources")
  ]
)
