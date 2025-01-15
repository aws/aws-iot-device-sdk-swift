# AWS IoT Device SDK for Swift

This document provides information about the AWS IoT Device SDK for Swift. This SDK is built on the [AWS Common Runtime](https://docs.aws.amazon.com/sdkref/latest/guide/common-runtime.html)

*__Jump To:__*
* [Build the Library](#build-the-library)
* [Use the SDK as a Dependency](#use-the-sdk-as-a-dependency)
* [Samples](samples)
* [Mac-Only TLS Behavior](#mac-only-tls-behavior)
* [Getting Help](#getting-help)
* [FAQ](./Documentation/FAQ.md)
* [MQTT5 User Guide](./Documentation/MQTT5_Userguide.md)

## Build the Library

### Minimum Requirements
* Swift 5.10+

```
# 1. Create a workspace directory to hold all the SKD files
mkdir sdk-workspace
cd sdk-workspace

# 2. Clone the repository. You can select the version of the SDK you desire to use.
git clone -b <SDK-VERSION> https://github.com/aws/aws-iot-device-sdk-swift.git

# 3. Install using swift
swift build
```

### Use the SDK as a Dependency
* If you want to consume the IoT Device SDK package in your Swift package, add it as a dependency in your `Package.swift` file.
```
dependencies: [
    .package(url: "https://github.com/aws/aws-iot-device-sdk-swift.git")
],
```
* If you are integrating into an Xcode project, you can add the Swift package directly in Xcode by going to File > Add Packages... and providing the AWS IoT Device SDK Swift Git URL.

## Samples

[Samples README](samples)

### Mac-Only TLS Behavior

Please note that on Mac, once a private key is used with a certificate, that certificate-key pair is imported into the Mac Keychain.  All subsequent uses of that certificate will use the stored private key and ignore anything passed in programmatically.  When a stored private key from the Keychain is used, the following will be logged at the "info" log level:

```
static: certificate has an existing certificate-key pair that was previously imported into the Keychain.  Using key from Keychain instead of the one provided.
```

## Getting Help

The best way to interact with our team is through GitHub. You can open a [discussion](https://github.com/aws/aws-iot-device-sdk-python-v2/discussions) for guidance questions or an [issue](https://github.com/aws/aws-iot-device-sdk-python-v2/issues/new/choose) for bug reports, or feature requests. You may also find help on community resources such as [StackOverFlow](https://stackoverflow.com/questions/tagged/aws-iot) with the tag [#aws-iot](https://stackoverflow.com/questions/tagged/aws-iot) or if you have a support plan with [AWS Support](https://aws.amazon.com/premiumsupport/), you can also create a new support case.

Please make sure to check out our resources too before opening an issue:

* [FAQ](./Documentation/FAQ.md)
* [IoT Guide](https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html) ([source](https://github.com/awsdocs/aws-iot-docs))
* Check for similar [Issues](https://github.com/aws/aws-iot-device-swift/issues)
* [AWS IoT Core Documentation](https://docs.aws.amazon.com/iot/)
* [Dev Blog](https://aws.amazon.com/blogs/?awsf.blog-master-iot=category-internet-of-things%23amazon-freertos%7Ccategory-internet-of-things%23aws-greengrass%7Ccategory-internet-of-things%23aws-iot-analytics%7Ccategory-internet-of-things%23aws-iot-button%7Ccategory-internet-of-things%23aws-iot-device-defender%7Ccategory-internet-of-things%23aws-iot-device-management%7Ccategory-internet-of-things%23aws-iot-platform)
* Integration with AWS IoT Services such as
[Device Shadow](https://docs.aws.amazon.com/iot/latest/developerguide/iot-device-shadows.html)
and [Jobs](https://docs.aws.amazon.com/iot/latest/developerguide/iot-jobs.html)
is provided by code that been generated from a model of the service.
* [Contributions Guidelines](./Documentation/CONTRIBUTING.md)

## License

This library is licensed under the [Apache 2.0 License](./Documentation/LICENSE).
