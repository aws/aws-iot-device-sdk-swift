# MQTT5 Sandbox Sample

[**Return to main sample list**](../README.md)

This sample demonstrates how to establish a Mqtt Connection against AWS IoT service using X509 client certificates and execute MQTT operations using the Mqtt5 Client.

This sample uses the
[Message Broker](https://docs.aws.amazon.com/iot/latest/developerguide/iot-message-broker.html)
for AWS IoT to send and receive messages through an MQTT connection.

The provided arguments are used to create an `MQTT5ClientBuilder` with `Mqtt5ClientBuilder.mtlsFromPath()`. The `MQTT5ClientBuilder` is used to set various callbacks and a client id. The `Mqtt5ClientBuilder` is used to create an `Mqtt5Client`. From here the Client can be instructed to complete operations using the command line.

## Before running the sample

### Setup an AWS Account:
If you do not have an AWS account, complete [these steps](https://docs.aws.amazon.com/iot/latest/developerguide/setting-up.html) to create one. This will provide you an account specific endpoint.

### Understand IoT:
The [What is AWS IoT](https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html) developer guide will help you understand IoT.

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
swift run Mqtt5Sample \
    <endpoint> \
    <certificate path> \
    <private key path>
```

### Available Commands
* <b>start</b> - Instructs the Mqtt5 Client to start a session.
* <b>stop</b> - Instructs the Mqtt5 Client to stop a session.
* <b>subscribe</b> - format: `subscribe <qos> <topic>` Subscribes to a topic.
* <b>unsubscribe</b> - format: `unsubscribe <topic>` Unsubscribes from a topic.
* <b>publish</b> - format: `publish <qos> <topic> <payload text>` Publishes to a topic.
* <b>exit</b> - Exit the program

#### Exmaple
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

To enable logging in the samples, you need add the following line AFTER `IotDeviceSdk` has been initialized. The logger level has the following options: `trace`, `debug`, `info`, `warn`, `error`, `fatal`, or `none`.
```swift
// The IoT Device SDK must be initialized before it is used.
IotDeviceSdk.initialize();

// This will turn on SDK and underlying CRT logging to assist in troubleshooting.
try Logger.initialize(target: .standardOutput, level: .debug)
```
### I'm getting Error code 5134: AWS_ERROR_MQTT_UNEXPECTED_HANGUP
This error is most likely due to your IoT Core Thing's [Policy](https://docs.aws.amazon.com/iot/latest/developerguide/iot-policies.html) must provide privileges for this sample to connect. Below is a sample policy that can be used on your IoT Core Thing that will allow this sample to run as intended.

For the purposes of this sample, please make sure your policy allows all IoT actions when running the sample. Wildcard resource permission is not recommended in production.

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
