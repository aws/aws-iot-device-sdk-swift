# Certificate and Key File Sample

[**Return to main sample list**](../../README.md)

This sample demonstrates how to establish an MQTT connection with an AWS IoT service using X509 client certificate files.

You will uses the
[message broker](https://docs.aws.amazon.com/iot/latest/developerguide/iot-message-broker.html)
for AWS IoT to send and receive messages through an MQTT connection.

The provided arguments are used to create an `MQTT5ClientBuilder` with `Mqtt5ClientBuilder.mtlsFromPath()`. `MQTT5ClientBuilder` is used to set various callbacks and a client id. Once configured, the `Mqtt5ClientBuilder` is used to create an `Mqtt5Client`. The `Mqtt5Client` is instructed to `start()` at which point it connects to the provided endpoint. Once it successfully connects and the `onLifecycleEventConnectionSuccess` is emitted, the `Mqtt5Client` is instructed to `stop()` at which point the `Mqtt5Client` will disconnect.

## Before Running the Sample

### Setup an AWS Account:
If you don't have an AWS account, complete [these steps](https://docs.aws.amazon.com/iot/latest/developerguide/setting-up.html) to create one. This will provide you with an account specific endpoint.

### Understand AWS IoT:
See the [AWS IoT Developer Guide](https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html) to learn about AWS IoT.

### Required Arguments:
* <b>--endpoint</b> - Account specific endpoint
* <b>--cert</b> - Path to certificate file
* <b>--key</b> - Path to private key file
### Optional Arguments:
* <b>--client-id</b> - The MQTT 5 client ID the sample use. If an ID isn't provided, "test-\<UUID\>" will be used.

### Build the sample
```
// The sample should be built from the sample's folder
cd aws-iot-device-sdk-swift/Samples/Mqtt5ConnectionSamples/CertAndKeyFileConnect

// build the sample
swift build
```
### Run the sample
```
swift run CertAndKeyFileConnect \
    --endpoint <endpoint> \
    --cert <certificate path> \
    --key <private key path>

```

## Troubleshooting
### Enable logging in samples

To enable logging in the samples, you must add the following line *after* initializing `IotDeviceSdk`. The logger level has the following options: `trace`, `debug`, `info`, `warn`, `error`, `fatal`, or `none`.
```swift
// The IoT Device SDK must be initialized before it is used.
IotDeviceSdk.initialize();

// This will turn on SDK and underlying CRT logging to assist in troubleshooting.
try Logger.initialize(target: .standardOutput, level: .debug)
```
### I'm getting error code 5134: AWS_ERROR_MQTT_UNEXPECTED_HANGUP
This error is most likely due to your AWS IoT Core thing's [policy](https://docs.aws.amazon.com/iot/latest/developerguide/iot-policies.html). The policy must provide privileges for this sample to connect. The following is a sample policy that can be used on your AWS IoT Core thing that allows this sample to run as intended.

For the purposes of this sample, make sure your policy allows a client ID of `test-*` to connect or use the `--client_id <client ID here>` argument to use a client ID that your policy supports.

<details>
<summary>(see sample policy)</summary>

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iot:Connect"
      ],
      "Resource": [
        "arn:aws:iot:<b>region</b>:<b>account</b>:client/test-*"
      ]
    }
  ]
}
```

  Replace the following with the data from your AWS account:
  * `<region>`: The AWS Region where you created the AWS IoT Core thing you wish to use with this sample. For example, `us-east-1`. For more information, see [AWS IoT Core endpoints](https://docs.aws.amazon.com/general/latest/gr/iot-core.html).
  * `<account>`: Your AWS account ID. For more information, see [View AWS account identifiers](https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-identifiers.html)

  Note: In a real application, you might want to avoid the use of wildcards in your policy or use them selectively. Follow best practices when using the SDK to work with AWS on production applications.

</details>

### Error: unable to create symlink aws-common-runtime/config/s2n: Permission denied
s2n is a Unix-specific library, and if you encounter a "Permission Denied" error, it is most likely because you are attempting to use it on an unsupported platform. The AWS IoT Device SDK for Swift supports the following platforms: macOS, iOS, tvOS, and Linux.

### Other Resources
Check out our resources to learn more:
* [FAQ](../../../Documentation/FAQ.md)
* [MQTT 5 User Guide](../../../Documentation/MQTT5_Userguide.md)
* [What is AWS IOT?](https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html)
* [Check for similar issues](https://github.com/aws/aws-iot-device-sdk-swift/issues)
* [AWS IoT Core Documentation](https://docs.aws.amazon.com/iot/)
* [Dev Blog](https://aws.amazon.com/blogs/?awsf.blog-master-iot=category-internet-of-things%23amazon-freertos%7Ccategory-internet-of-things%23aws-greengrass%7Ccategory-internet-of-things%23aws-iot-analytics%7Ccategory-internet-of-things%23aws-iot-button%7Ccategory-internet-of-things%23aws-iot-device-defender%7Ccategory-internet-of-things%23aws-iot-device-management%7Ccategory-internet-of-things%23aws-iot-platform)
