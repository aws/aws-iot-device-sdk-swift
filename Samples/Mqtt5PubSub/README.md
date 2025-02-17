# Basic MQTT5 PubSub Sample

[**Return to main sample list**](../README.md)

This sample demonstrates how to establish a Mqtt Connection against AWS IoT service using X509 client certificates and then subscribe to and publish to a topic. 

This sample uses the
[Message Broker](https://docs.aws.amazon.com/iot/latest/developerguide/iot-message-broker.html)
for AWS IoT to send and receive messages through an MQTT connection.

The provided arguments are used to create an `MQTT5ClientBuilder` with `Mqtt5ClientBuilder.mtlsFromPath()`. The `MQTT5ClientBuilder` is used to set various callbacks and a client id. The `Mqtt5ClientBuilder` is used to create an `Mqtt5Client`. The `Mqtt5Client` is instructed to `start()` at which point it connects to the provided endpoint. Once it successfully connects and the `onLifecycleEventConnectionSuccess` is emitted, the `Mqtt5Client` subscribes to a topic using `subscribe()`, publishes to the same topic uqing `publish()`, receives and processes the `PublishReceivedData`, and then the `Mqtt5Client` is instructed to `stop()` at which point the `Mqtt5Client` will disconnect.

## Before running the sample

### Required Arguments:
* <b>endpoint</b> - account specific endpoint
* <b>cert</b> - Path to certificate file
* <b>key</b> - Path to private key file
### Optional Arguments:
* <b>client-id</b> - Mqtt5 client id to use. If not provided, "test-<UUID>" will be used.
* <b>topic</b> - Topic to subscribe and publish to. If not provided, "test/topic" will be used.
* <b>payload-message</b> - Payload message to use in the publish packet. If not provided, "Sample payload message." will be used.

### Build the sample
```
// The sample should be built from the sample's folder
cd aws-iot-device-sdk-swift/Samples/Mqtt5PubSub

// build the sample
swift build
```
### Run the sample
```
swift run X509Connect \
    <endpoint> \
    <certificate path> \
    <private key path>

```

## Troubleshooting
### Enable logging in samples

To enable logging in the samples, you need add the following line AFTER `IotDeviceSdk` has been initialized. The logger level has the following options: `trace`, `debug`, `info`, `warn`, `error`, `fatal`, or `none`.
```swift
// The IoT Device SDK must be initialized before it is used.
IotDeviceSdk.initialize();

// This will turn on SDK and underlying CRT logging to assist in troubleshooting.
try Logger.initialize(target: .standardOutput, level: .debug)
```
### AWS IoT Policy
Your IoT Core Thing's [Policy](https://docs.aws.amazon.com/iot/latest/developerguide/iot-policies.html) must provide privileges for this sample to connect. Below is a sample policy that can be used on your IoT Core Thing that will allow this sample to run as intended.

For the purposes of this sample, please make sure your policy allows a client ID of `test-*` to connect or use the `--client_id <client ID here>` argument when running the sample to use a client ID your policy supports.

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

  Replace with the following with the data from your AWS account:
  * `<region>`: The AWS IoT Core region where you created your AWS IoT Core thing you wish to use with this sample. For example`us-east-1`.
  * `<account>`: Your AWS IoT Core account ID. This is the set of numbers in the top right next to your AWS account name whenusing the AWS IoT Core website.

  Note that in a real application, you may want to avoid the use of wildcards in your ClientID or use them selectively. Please follow best practices when working with AWS on production applications using the SDK.

</details>

### Other Resources
Please make sure to check out our resources too before opening an DISCUSSION:
* [FAQ](../../../Documentation/FAQ.md)
* [MQTT5 User Guide](../../../Documentation/MQTT5_Userguide.md)
* [What is AWS IOT?](https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html)
* [IoT Guide](https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html)
* [Check for similar issues](https://github.com/aws/aws-iot-device-sdk-swift/issues)
* [AWS IoT Core Documentation](https://docs.aws.amazon.com/iot/)
* [Dev Blog](https://aws.amazon.com/blogs/?awsf.blog-master-iot=category-internet-of-things%23amazon-freertos%7Ccategory-internet-of-things%23aws-greengrass%7Ccategory-internet-of-things%23aws-iot-analytics%7Ccategory-internet-of-things%23aws-iot-button%7Ccategory-internet-of-things%23aws-iot-device-defender%7Ccategory-internet-of-things%23aws-iot-device-management%7Ccategory-internet-of-things%23aws-iot-platform)
