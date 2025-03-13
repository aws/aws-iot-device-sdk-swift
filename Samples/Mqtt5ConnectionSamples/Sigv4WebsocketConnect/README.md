# Websocket with Sigv4a Connect Sample

[**Return to main sample list**](../../README.md)

This sample demonstrates how to establish a Mqtt Connection against AWS IoT service through a websocket using Sigv4-based authentication. 

This sample uses the
[Message Broker](https://docs.aws.amazon.com/iot/latest/developerguide/iot-message-broker.html)
for AWS IoT to send and receive messages through an MQTT connection using MQTT5.

The provided arguments are used to create a `CredentialsProvider` which is then used to create an `MQTT5ClientBuilder` with `Mqtt5ClientBuilder.websocketsWithDefaultAwsSigning()`. `MQTT5ClientBuilder` is used to set various callbacks and a client id. Once configured, the `Mqtt5ClientBuilder` is used to create an `Mqtt5Client`. The `Mqtt5Client` is instructed to `start()` at which point it connects to the provided endpoint. Once it successfully connects and the `onLifecycleEventConnectionSuccess` is emitted, the `Mqtt5Client` is instructed to `stop()` at which point the `Mqtt5Client` will disconnect.

## Before running the sample

### Setup an AWS Account:
If you do not have an AWS account, complete [these steps](https://docs.aws.amazon.com/iot/latest/developerguide/setting-up.html) to create one. This will provide you an account specific endpoint.

### Understand IoT:
The [What is AWS IoT](https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html) developer guide will help you understand IoT.

### Sigv4
Sigv4-based authentication requires a credentials provider capable of sourcing valid AWS credentials. Sourced credentials will sign the websocket upgrade request made by the client while connecting. The default credentials provider chain supported by the SDK is capable of resolving credentials in a variety of environments according to a chain of priorities:
```
Environment -> Provilde (local file system) -> STS Web Identity -> IMDS (ec2) or ECS
```
### Required Arguments:
* <b>endpoint</b> - account specific endpoint
* <b>region</b> - Signging region
### Optional Arguments:
<note>Static credentials can be set and used by providing access-key, secret, and session-token optional arguments. </note>
* <b>access-key</b> - AWS Access Key ID to obtain credentials
* <b>secret</b> - AWS Secret Access Key to obtain credentials
* <b>session-token</b> - AWS Session Token to obtain credentials
* <b>client-id</b> - Mqtt5 client id to use. If not provided, "test-<UUID>" will be used.

### Build the sample
```
// The sample should be built from the sample's folder
cd aws-iot-device-sdk-swift/Samples/Mqtt5ConnectionSamples/Sigv4WebsocketConnect

// build the sample
swift build
```
### Run the sample
```
// Obtain Credentials from your environment
swift run Sigv4WebsocketConnect \
    <endpoint> \
    <region>

// Provide static credentials to use
swift run Sigv4WebsocketConnect \
    <endpoint> \
    <region> \
    --access-key <AWS Access Key ID> \
    --secret <AWS Secret Access Key> \
    --session-token <AWS Session Token>
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
### I'm getting Error code 5134: AWS_ERROR_MQTT_UNEXPECTED_HANGUP
This error is most likely due to your IoT Core Thing's [Policy](https://docs.aws.amazon.com/iot/latest/developerguide/iot-policies.html) must provide privileges for this sample to connect. Below is a sample policy that can be used on your IoT Core Thing that will allow this sample to run as intended.

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
