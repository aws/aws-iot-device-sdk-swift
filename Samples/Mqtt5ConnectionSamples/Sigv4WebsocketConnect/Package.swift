// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Sigv4WebsocketConnect",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
  ],
  products: [
    .executable(name: "Sigv4WebsocketConnect", targets: ["Sigv4WebsocketConnect"])
  ],
  dependencies: [
    .package(path: "../../../"),
    // This package gives us the capability to do a argument parsing
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .executableTarget(
      name: "Sigv4WebsocketConnect",
      dependencies: [
        .product(name: "AwsIotDeviceSdkSwift", package: "aws-iot-device-sdk-swift"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "Sources")
  ]
)
