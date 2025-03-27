# Frequently Asked Questions

*__Topics:__*
* [Where should I start](#where-should-i-start)
* [How do I enable logging](#how-do-i-enable-logging)
* [I am getting OSStatus -34018 when adding a certificate](#i-am-getting-osstatus--34018-when-adding-a-certificate)
* [I keep getting AWS_ERROR_MQTT_UNEXPECTED_HANGUP](#i-keep-getting-aws_error_mqtt_unexpected_hangup)
* [What certificates do I need?](#what-certificates-do-i-need)
* [Error: unable to create symlink aws-common-runtime/config/s2n: Permission denied](#error-unable-to-create-symlink-aws-common-runtimeconfigs2n-Permission-denied)
* [To learn more about this SDK](#to-learn-more-about-this-sdk)

### Where should I start?

If you're just getting started, make sure you [build this SDK](https://github.com/aws/aws-iot-device-sdk-swift#build-the-library) before building and running the [Certificate and Key File Connect Sample](https://github.com/aws/aws-iot-device-sdk-swift/tree/main/Samples/Mqtt5ConnectionSamples/CertAndKeyFileConnect).

### Where can I get the API documentation?
Load the library in XCode and then go to **Product** > **Build Documentation**.

### How do I enable logging?

```
try? Logger.initialize(target: .standardOutput, level: .debug)
```
You can also enable [CloudWatch logging](https://docs.aws.amazon.com/iot/latest/developerguide/cloud-watch-logs.html) for AWS IoT, which provides you with additional information that's not available on the client-side SDK.

### I am getting OSStatus -34018 when adding a certificate

The `errSecMissingEntitlement` [OSStatus error](https://www.osstatus.com/search/results?platform=all&framework=all&search=-34018) indicates that a required entitlement is missing. For more information, see [errSecMissingEntitlement](https://developer.apple.com/documentation/security/errsecmissingentitlement) on Apple's developer website. You must provide entitlements to the app or binary you're building and running using the SDK to allow it permission to access the Mac Keychain on the device. This entitlement can't be given directly to the SDK library and must be provided to the application being built using the SDK library.


### I keep getting AWS_ERROR_MQTT_UNEXPECTED_HANGUP

This error is most likely due to a policy issue. Try using a super permissive IAM policy called `AWSIOTFullAccess`:

``` json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iot:*"
            ],
            "Resource": "*"
        }
    ]
}
```

After you resolve this error, make sure to only allow the actions and resources that you need. To learn more about IAM policies for AWS IoT, see [How AWS IoT works with IAM](https://docs.aws.amazon.com/iot/latest/developerguide/security_iam_service-with-iam.html) in the *AWS IoT Core Developer Guide*.

### What certificates do I need?

* You can download pre-generated certificates from the [AWS Management Console](https://console.aws.amazon.com/) (this is the simplest and is recommended for testing).
* You can also generate your own certificates to fit your specific use case. For more information, see [X.509 client certificates](https://docs.aws.amazon.com/iot/latest/developerguide/x509-client-certs.html) in the *AWS IoT Core Developer Guide* and [AWS IoT device provisioning](https://catalog.us-east-1.prod.workshops.aws/workshops/7c2b04e7-8051-4c71-bc8b-6d2d7ce32727/en-US/030-provisioning-options) in the *AWS IoT Device Management Workshop*.
* Certificates required to run the samples
    * Device certificate
        * An intermediate device certificate that is used to generate the key.
        * When using the samples, the certificate can look like this: `--cert abcde12345-certificate.pem.crt`
    * Key files
        * You must generated and downloaded the private and public keys that are used to verify that communications are coming from you.
        * When using the samples, you only need the private key. For example: `--key abcde12345-private.pem.key`
    * Root CA certificates
        * Download the root CA certificate file that corresponds to the type of data endpoint and cipher suite you're using (usually Amazon Root CA 1).
        * Root CA certificates are generated and provided by Amazon. You can [download a certificate](https://www.amazontrust.com/repository/) from Amazon Trust Service or while getting the other certificates from the [AWS Management Console](https://console.aws.amazon.com/).
        * When using the sample, the certificate can look like this: `--ca_file root-CA.crt`


### Error: unable to create symlink aws-common-runtime/config/s2n: Permission denied
If you encounter a "s2n Permission Denied" error, it's likely because you're attempting to use an unsupported platform. s2n-tls is a Unix-specific library.

The AWS IoT Device SDK for Swift supports the following platforms:
* macOS
* iOS
* tvOS
* Linux

### To learn more about this SDK

* [AWS IoT Core Developer Guide](https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html)
* [Discussions](https://github.com/aws/aws-iot-device-sdk-swift/discussions) are a great way to ask questions about this SDK.
* [Open an issue](https://github.com/aws/aws-iot-device-sdk-swift/issues) if you find a bug or have a feature request.
