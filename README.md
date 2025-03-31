# AWS IoT Device SDK for Swift

This document provides information about the AWS IoT Device SDK for Swift. This SDK is built on the [AWS Common Runtime](https://docs.aws.amazon.com/sdkref/latest/guide/common-runtime.html).

**Supported Platforms**: macOS, iOS, tvOS, Linux

> [!IMPORTANT]
> This project is in **DEVELOPER PREVIEW** while we gather feedback on interfaces and use cases. Please file issues and feature requests. Expect breaking API changes as we incorporate feedback.


*__Topics:__*
* [Build the Library](#build-the-library)
    * [Build from source](#build-from-source)
* [Use the SDK as a Dependency](#use-the-sdk-as-a-dependency)
* [Mac-Only TLS Behavior](#mac-only-tls-behavior)
* [Getting Help](#getting-help)
* [Resources](#resources)
* [Samples](./Samples/README.md)
* [MQTT 5 User Guide](./Documentation/MQTT5_Userguide.md)

## Build the Library

### Minimum Requirements
* Swift 5.10+


### Build from Source

```
# 1. Create a workspace directory to hold all the SKD files
mkdir sdk-workspace
cd sdk-workspace

# 2. Clone the repository. You can select the version of the SDK you desire to use.
git clone https://github.com/aws/aws-iot-device-sdk-swift.git
cd aws-iot-device-sdk-swift

# 3. Install using swift
swift build
```

## Use the SDK as a Dependency
* If you want to consume the AWS IoT Device SDK package in your Swift package, add it as a dependency in your `Package.swift` file.
```
dependencies: [
    .package(url: "https://github.com/aws/aws-iot-device-sdk-swift.git")
],
```
* If you're integrating into an Xcode project, you can add the Swift package directly in Xcode by going to **File** > **Add Packages Dependencies...** and providing the AWS IoT Device SDK Swift Git URL.

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
* [AWS IoT Core Documentation](https://docs.aws.amazon.com/iot/)
* [Dev Blog](https://aws.amazon.com/blogs/?awsf.blog-master-iot=category-internet-of-things%23amazon-freertos%7Ccategory-internet-of-things%23aws-greengrass%7Ccategory-internet-of-things%23aws-iot-analytics%7Ccategory-internet-of-things%23aws-iot-button%7Ccategory-internet-of-things%23aws-iot-device-defender%7Ccategory-internet-of-things%23aws-iot-device-management%7Ccategory-internet-of-things%23aws-iot-platform)
* [Contributing Guidelines](./Documentation/CONTRIBUTING.md)


## License

This library is licensed under the [Apache 2.0 License](./Documentation/LICENSE).
