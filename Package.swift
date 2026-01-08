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
    .library(
      name: "IotIdentityClient",
      targets: ["IotIdentityClient"]),
    .library(
      name: "IotJobsClient",
      targets: ["IotJobsClient"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/awslabs/aws-crt-swift.git", .upToNextMajor(from: "0.56.0")),
    // aws-sdk-swift is only used in test targets to help with setup and cleanup of testing service clients
    // We use "aws-iot-device-sdk-swift-testing-branch" to maintain aws-crt-swift version pairity between it
    // and our SDK for testing. As aws-sdk-swift depends on swift-smithy, which also uses aws-crt-swift, we
    // keep the versions in sync using a fork https://github.com/sbSteveK/smithy-swift
    // Steps for updating the versions:
    //    1. Update crt version for smithy-swift
    //        a. fork from https://github.com/sbSteveK/smithy-swift.git
    //        b. pull in latest https://github.com/smithy-lang/smithy-swift and update aws-crt-swift version in `Package.swift`
    //        c. create a PR to sbSteveK/smithy, and submit for @sbstevek to review and merge
    //        d. go to latest Package.swift from awslabs/aws-crt-swift, and look for `clientRuntimeVersion`. This is the version tag of smithy-swift that aws-sdk-swift is using.
    //        e. cut a release in sbSteveK/smithy using the same version tag as `clientRuntimeVersion`
    //    2. Update crt version for https://github.com/awslabs/aws-sdk-swift
    //        a. branch from "aws-iot-device-sdk-swift-testing-branch"
    //        b. pull in the latest main and update crt version as needed
    //        c. submit PR against "aws-iot-device-sdk-swift-testing-branch" for review and merge
    // Once the PRs are merged, you can update the version here for aws-crt-swift, remember to test locally to make sure the Package.swift resolves correctly.
    .package(
      url: "https://github.com/awslabs/aws-sdk-swift.git",
      branch: "aws-iot-device-sdk-swift-testing-branch"),
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
        .product(name: "AWSIoT", package: "aws-sdk-swift"),
      ],
      path: "Tests/IotJobsClientTests"),
    .target(
      name: "IotIdentityClient",
      dependencies: [
        .target(name: "AwsIotDeviceSdkSwift")
      ],
      path: "ServiceClients/AwsIotIdentityClient"
    ),
    .testTarget(
      name: "IotIdentityClientTests",
      dependencies: [
        "IotIdentityClient",
        .product(name: "AWSIoT", package: "aws-sdk-swift"),
      ],
      path: "Tests/IotIdentityClientTests"
    ),
  ]
)
