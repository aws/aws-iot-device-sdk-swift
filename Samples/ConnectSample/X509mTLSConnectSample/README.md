# Basic Connect Sample

[**Return to main sample list**](./README.md)

This sample demonstrate how to establish a Mqtt Connection against AWS IoT service with X509 client certificates. 

This sample uses the
[Message Broker](https://docs.aws.amazon.com/iot/latest/developerguide/iot-message-broker.html)
for AWS IoT to send and receive messages through an MQTT connection.

On startup, the device connects to the server, subscribes to a topic, and begins publishing messages to that topic. The device should receive those same messages back from the message broker, since it is subscribed to that same topic. Status updates are continually printed to the console. This sample demonstrates how to send and receive messages on designated IoT Core topics, an essential task that is the backbone of many IoT applications that need to send data over the internet. This sample simply subscribes and publishes to a topic, printing the messages it just sent as it is received from AWS IoT Core, but this can be used as a reference point for more complex Pub-Sub applications.

## Before you run the sample

0. [What is AWS IOT?](https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html)

1. Setup AWS account and [create AWS IoT Resource](https://docs.aws.amazon.com/iot/latest/developerguide/create-iot-resources.html): Make sure you download and save the certificate files from the creation.
   
2. Check AWS IoT Policy

   Your IoT Core Thing's [Policy](https://docs.aws.amazon.com/iot/latest/developerguide/iot-policies.html) must provide privileges for this sample to connect, subscribe, publish, and receive. Below is a sample policy that can be used on your IoT Core Thing that will allow this sample to run as intended.

    For the purposes of this sample, please make sure your policy allows a client ID of `test-*` to connect or use `--client_id <client ID here>` to send the client ID your policy supports.

   <details>
    <summary>(see sample policy)</summary>
    <pre>
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "iot:Publish",
            "iot:Receive"
          ],
          "Resource": [
            "arn:aws:iot:<b>region</b>:<b>account</b>:topic/test/topic"
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "iot:Subscribe"
          ],
          "Resource": [
            "arn:aws:iot:<b>region</b>:<b>account</b>:topicfilter/test/topic"
          ]
        },
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
    </pre>

    Replace with the following with the data from your AWS account:
    * `<region>`: The AWS IoT Core region where you created your AWS IoT Core thing you wish to use with this sample. For example `us-east-1`.
    * `<account>`: Your AWS IoT Core account ID. This is the set of numbers in the top right next to your AWS account name when using the AWS IoT Core website.

    Note that in a real application, you may want to avoid the use of wildcards in your ClientID or use them selectively. Please follow best practices when working with AWS on production applications using the SDK.

    </details>

## Run the sample
0. Prepare your certificates: you should download the certificate file and private key file during IoT resource creation.
1. Switch to the sample folder, and build the sample
```
cd aws-iot-device-sdk-swift/Samples/ConnectSample/X509MTLSConnectSample
swift build
```
2. Run the sample
```
swift run X509MTLSConnectSample <endpoint> <path-to-certificate-file> <path-to-private-key-file>
```
We also provide several extra options
```
OPTIONS:
  --ca_file <ca_file>     The path to the override root CA file (optional).
  --client_id <client_id> Client id to use (optional) (default:
                          test-<UUID>).
``` 
Please make sure the client id you use matches the client id set in your policy. 

## Trouble Shoot
### Enable logging in samples

To enable logging in the samples, you need add the following line into the code. The logger level has the following options: `trace`, `debug`, `info`, `warn`, `error`, `fatal`, or `none`.
```swift
// Optional init debug log to help with debugging.
Logger.initialize(target: .standardOutput, level: .debug)
```

### Others
Please make sure to check out our resources too before opening an DISCUSSION:
* [FAQ][WIP]
* [IoT Guide](https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html)
* Check for similar [Issues](https://github.com/aws/aws-iot-device-sdk-swift/issues)
* [AWS IoT Core Documentation](https://docs.aws.amazon.com/iot/)
* [Dev Blog](https://aws.amazon.com/blogs/?awsf.blog-master-iot=category-internet-of-things%23amazon-freertos%7Ccategory-internet-of-things%23aws-greengrass%7Ccategory-internet-of-things%23aws-iot-analytics%7Ccategory-internet-of-things%23aws-iot-button%7Ccategory-internet-of-things%23aws-iot-device-defender%7Ccategory-internet-of-things%23aws-iot-device-management%7Ccategory-internet-of-things%23aws-iot-platform)
