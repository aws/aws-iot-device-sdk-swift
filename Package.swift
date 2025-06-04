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
      // url: "https://github.com/awslabs/aws-crt-swift.git", .upToNextMajor(from: "0.52.2"))
      // TODO WIP revert this to point to the main branch
      url: "https://github.com/awslabs/aws-crt-swift.git", branch: "rr_streaming"),
    // aws-sdk-swift is only used in test targets to help with setup and cleanup of testing service clients
    .package(
      url: "https://github.com/awslabs/aws-sdk-swift.git", from: "1.3.19"),
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
