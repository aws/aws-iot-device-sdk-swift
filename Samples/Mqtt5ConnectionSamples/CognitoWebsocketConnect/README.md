# Websocket with Cognito Connect Sample

[**Return to main sample list**](../../README.md)

This sample demonstrates how to establish a Mqtt Connection against AWS IoT service through a websocket using a [Cognito Identity](https://aws.amazon.com/cognito/) to authorize the connection. This has the advantage of not requiring the need to store AWS credentials on the device itself with permissions to perform the IoT actions your device requires, but instead just having AWS credentials for the Cognito identity instead. This provides a layer of security and indirection that gives you better security.

You will uses the
[Message Broker](https://docs.aws.amazon.com/iot/latest/developerguide/iot-message-broker.html)
for AWS IoT to send and receive messages through an MQTT connection using MQTT5.

The sample performs the following actions:
1. Initializes the Device SDK library
2. Sets up the MQTT 5 Client
3. Starts the connection session
4. Stops the connection session

## Before Running the Sample

### Setup an AWS Account:
If you don't have an AWS account, complete [these steps](https://docs.aws.amazon.com/iot/latest/developerguide/setting-up.html) to create one. This will provide you an account specific endpoint.

### Understand IoT:
See the [AWS IoT Developer Guide](https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html) to learn about AWS IoT.

### Required Arguments:
* <b>endpoint</b> - account specific endpoint
* <b>region</b> - signing region
* <b>cognito-endpoint</b> - cognito endpoint
* <b>cognito-identity</b> - cognito identity ID
### Optional Arguments:
* <b>client-id</b> - Mqtt5 client id to use. If not provided, "test-\<UUID\>" will be used.

### Build the sample
```
// The sample should be built from the sample's folder
cd aws-iot-device-sdk-swift/Samples/Mqtt5ConnectionSamples/CognitoWithWebsocketConnect

// build the sample
swift build
```
### Run the sample
```
swift run CognitoWithWebsocketConnect \
    --endpoint <endpoint> \
    --region <region> \
    --cognito-endpoint <cognito-endpoint> \
    --cognito-identity <cognito-identity>

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

### I'm getting Error code 5134: AWS_ERROR_MQTT_UNEXPECTED_HANGUP
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

  Replace with the following with the data from your AWS account:
  * `<region>`: The AWS Region where you created the AWS IoT Core thing you wish to use with this sample. For example, `us-east-1`. For more information, see [AWS IoT Core endpoints](https://docs.aws.amazon.com/general/latest/gr/iot-core.html).
  * `<account>`: Your AWS account ID. For more information, see [View AWS account identifiers](https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-identifiers.html)

  Note: In a real application, you might want to avoid the use of wildcards in your policy or use them selectively. Follow best practices when using the SDK to work with AWS on production applications.

</details>

### Retrieving Cognito Identity ID
Once you have a Cognito identity pool, you can run the following CLI command to get the Cognito identity pool ID:
```
aws cognito-identity get-id --identity-pool-id <cognito identity pool id>
# result from above command
{
    "IdentityId": "<cognito identity ID>"
}
```

### Error: unable to create symlink aws-common-runtime/config/s2n: Permission denied
s2n is a Unix-specific library, and if you encounter a "Permission Denied" error, it is most likely because you are attempting to use it on an unsupported platform. The AWS IoT Device SDK for Swift supports the following platforms: macOS, iOS, tvOS, and Linux.

### Other Resources
Please make sure to check out our resources too before opening an DISCUSSION:
* [FAQ](../../../Documentation/FAQ.md)
* [MQTT 5 User Guide](../../../Documentation/MQTT5_Userguide.md)
* [What is AWS IOT?](https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html)
* [Check for similar issues](https://github.com/aws/aws-iot-device-sdk-swift/issues)
* [AWS IoT Core Documentation](https://docs.aws.amazon.com/iot/)
* [Dev Blog](https://aws.amazon.com/blogs/?awsf.blog-master-iot=category-internet-of-things%23amazon-freertos%7Ccategory-internet-of-things%23aws-greengrass%7Ccategory-internet-of-things%23aws-iot-analytics%7Ccategory-internet-of-things%23aws-iot-button%7Ccategory-internet-of-things%23aws-iot-device-defender%7Ccategory-internet-of-things%23aws-iot-device-management%7Ccategory-internet-of-things%23aws-iot-platform)
