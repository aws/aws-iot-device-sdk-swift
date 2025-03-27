# MQTT5 Sandbox Sample

[**Return to main sample list**](../README.md)

This sample demonstrates how to establish an MQTT connection with the [AWS IoT Core message broker](https://docs.aws.amazon.com/iot/latest/developerguide/iot-message-broker.html) using X509 client certificates and execute MQTT operations using the MQTT 5 Client.

## Before Running the Sample

### Setup an AWS Account:
If you don't have an AWS account, complete [these steps](https://docs.aws.amazon.com/iot/latest/developerguide/setting-up.html) to create one. This will provide you with an account specific endpoint.

### Understand IoT:
The [What is AWS IoT](https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html) developer guide will help you understand IoT.

### Required Arguments:
* <b>endpoint</b> - account specific endpoint
* <b>cert</b> - Path to certificate file
* <b>key</b> - Path to private key file
### Optional Arguments:
* <b>client-id</b> - Mqtt5 client id to use. If not provided, "test-\<UUID\>" will be used.
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
swift run Mqtt5Sample \
    --endpoint <endpoint> \
    --cert <certificate path> \
    --key <private key path>
```

### Available Commands
* <b>start</b> - Instructs the Mqtt5 Client to start a session.
* <b>stop</b> - Instructs the Mqtt5 Client to stop a session.
* <b>subscribe</b> - format: `subscribe <qos> <topic>` Subscribes to a topic.
* <b>unsubscribe</b> - format: `unsubscribe <topic>` Unsubscribes from a topic.
* <b>publish</b> - format: `publish <qos> <topic> <payload text>` Publishes to a topic.
* <b>exit</b> - Exit the program

#### Example
```
start
// Client attempts to start a session. It will try to connect and emit lifecycle events reporting its progress.

subscribe qos1 test/topic
// Client subscribes to topic "test/topic" with QoS1. A Suback packet will be logged if available.

publish qos1 test/topic payload
// Client publishes to topic "test/topic" with QoS1. A Puback packet will be logged if available.
// If the previous subscribe was successful, the outbound publish packet will be received by the
// Client and logged.

unsubscribe test/topic
// Client unsubscribes from topic "test/topic". An Unsuback packet will be logged if available.

stop
// Client will end its session. It will disconnect and emit lifecycle events reporting its progress
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

For the purposes of this sample, please make sure your policy allows all IoT actions when running the sample. Wildcard resource permission is **NOT** recommended in production.

<details>
<summary>(see sample policy)</summary>

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iot:Connect",
        "iot:Subscribe",
        "iot:Publish",
        "iot:Receive"
      ],
      "Resource": [
        "*"
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
If you encounter a "s2n Permission Denied" error, it's likely because you're attempting to use an unsupported platform. s2n-tls is a Unix-specific library.

The AWS IoT Device SDK for Swift supports the following platforms:
* macOS
* iOS
* tvOS
* Linux

### Other Resources
Check out our resources to learn more:
* [FAQ](../../../Documentation/FAQ.md)
* [MQTT 5 User Guide](../../../Documentation/MQTT5_Userguide.md)
* [What is AWS IOT?](https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html)
* [Check for similar issues](https://github.com/aws/aws-iot-device-sdk-swift/issues)
* [AWS IoT Core Documentation](https://docs.aws.amazon.com/iot/)
* [Dev Blog](https://aws.amazon.com/blogs/?awsf.blog-master-iot=category-internet-of-things%23amazon-freertos%7Ccategory-internet-of-things%23aws-greengrass%7Ccategory-internet-of-things%23aws-iot-analytics%7Ccategory-internet-of-things%23aws-iot-button%7Ccategory-internet-of-things%23aws-iot-device-defender%7Ccategory-internet-of-things%23aws-iot-device-management%7Ccategory-internet-of-things%23aws-iot-platform)
