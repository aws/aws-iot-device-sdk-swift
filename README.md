# AWS IoT Device SDK for Swift

> [!IMPORTANT]
> This project is in **DEVELOPER PREVIEW** while we gather feedback on interfaces and use cases. Please file issues and feature requests. Expect breaking API changes as we incorporate feedback.

The AWS IoT Device SDK for Swift connects your Swift applications and devices to the AWS IoT platform. It handles the complexities of secure communication, authentication, and device management so you can focus on your IoT solution. The SDK makes it easy to use AWS IoT services like Device Shadows, Jobs, and Fleet Provisioning.

**Supported Platforms**: macOS 14+, iOS 13+, tvOS 13+, Linux

*__Topics:__*
* [Features](#features)
* [Installation](#installation)
  * [Minimum Requirements](#minimum-requirements)
  * [Building from source](#building-from-source)
* [Getting Started](#getting-started)
* [Samples](./Samples/README.md)
* [MQTT5 User Guide](./Documentation/MQTT5_Userguide.md)
* [Getting Help](#getting-help)
* [Resources](#resources)

## Features

The primary purpose of the AWS IoT Device SDK for Swift is to simplify the process of connecting devices to AWS IoT Core and interacting with AWS IoT services on various platforms. The SDK provides:

* Integrated service clients for AWS IoT Core services
* Secure device connections to AWS IoT Core using MQTT protocol including MQTT 5.0
* Support for [multiple authentication methods and connection types](./Documentation/MQTT5_Userguide.md#creating-an-mqtt-5-client)

#### Supported AWS IoT Core services

* The [AWS IoT Device Shadow](https://docs.aws.amazon.com/iot/latest/developerguide/iot-device-shadows.html) service manages device state information in the cloud.
* The [AWS IoT Jobs](https://docs.aws.amazon.com/iot/latest/developerguide/iot-jobs.html) service sends remote operations to connected devices.
* The [AWS IoT fleet provisioning](https://docs.aws.amazon.com/iot/latest/developerguide/provision-wo-cert.html) service generates and delivers device certificates automatically.

## Installation

Add the AWS IoT Device SDK for Swift package as a dependency to your application.

### Minimum Requirements
* Swift 5.10+

### Use the SDK as a Dependency

If you want to consume the AWS IoT Device SDK package in your Swift package, add it as a dependency in your `Package.swift` file:

```
dependencies: [
    .package(url: "https://github.com/aws/aws-iot-device-sdk-swift.git")
],
```

### Building from source

```sh
# 1. Create a workspace directory to hold all the SDK files
mkdir sdk-workspace
cd sdk-workspace

# 2. Clone the repository. You can select the version of the SDK you desire to use.
git clone https://github.com/aws/aws-iot-device-sdk-swift.git
cd aws-iot-device-sdk-swift

# 3. Install using swift
swift build
```

## Getting Started

To get started with the AWS IoT Device SDK for Swift:

1. **Add the SDK to your project** - See the [Installation](#installation) section for dependency details

2. **Choose your connection method** - The SDK supports multiple authentication methods including X.509 certificates, AWS credentials, and custom authentication. [MQTT5 User Guide](./Documentation/MQTT5_Userguide.md) provides more guidance

3. **Follow a complete example** - Check out the [Samples](./Samples/README.md) directory

4. **Learn MQTT5 features** - For advanced usage and configuration options, see the [MQTT5 User Guide](./Documentation/MQTT5_Userguide.md)

## Samples

Check out the [Samples](./Samples/README.md) directory for working code examples that demonstrate:
- [Basic MQTT connection and messaging](./Samples/README.md#mqtt-5-connection-samples)
- [AWS IoT Device Shadow operations](./Samples/ServiceClientSamples/ShadowSample)
- [AWS IoT Jobs](./Samples/ServiceClientSamples/JobsSample)
- AWS IoT Fleet provisioning: [basic](./Samples/ServiceClientSamples/Provisioning/BasicProvisioningSample) and [with CSR](./Samples/ServiceClientSamples/Provisioning/CsrProvisioningSample)
- [iOS pub-sub sample application](./Samples/iOS/iOSPubSubSample)

The samples provide ready-to-run code with detailed setup instructions for each authentication method and use case.

## Mac-Only TLS Behavior

Note: On Mac, after a private key is used with a certificate, that certificate-key pair is imported into the Mac Keychain.  All subsequent uses of that certificate will use the stored private key and ignore anything passed in programmatically.  When a stored private key from the Mac Keychain is used, the following is logged at the "info" log level:

```
static: certificate has an existing certificate-key pair that was previously imported into the Keychain.
 Using key from Keychain instead of the one provided.
```

## Getting Help

The best way to interact with our team is through GitHub.
* Open [discussion](https://github.com/aws/aws-iot-device-sdk-swift/discussions): Share ideas and solutions with the SDK community
* Search [issues](https://github.com/aws/aws-iot-device-sdk-swift/issues): Find created issues for answers based on a topic
* Create an [issue](https://github.com/aws/aws-iot-device-sdk-swift/issues/new/choose): New feature request or file a bug

If you have a support plan with [AWS Support](https://aws.amazon.com/premiumsupport/), you can also create a new support case.

## Resources

Check out our resources for additional guidance too before opening an issue:
* [FAQ](./Documentation/FAQ.md)
* [AWS IoT Core Developer Guide](https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html)
* [MQTT5 User Guide](./Documentation/MQTT5_Userguide.md)
* [AWS IoT Core Documentation](https://docs.aws.amazon.com/iot/)
* [Dev Blog](https://aws.amazon.com/blogs/iot/category/internet-of-things/)
* [Contributions Guidelines](./Documentation/CONTRIBUTING.md)

## License

This library is licensed under the [Apache 2.0 License](./Documentation/LICENSE).
