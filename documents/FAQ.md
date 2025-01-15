# Frequently Asked Questions

*__Jump To:__*
* [Where should I start](#where-should-i-start)
* [How do I enable logging](#how-do-i-enable-logging)
* [I keep getting AWS_ERROR_MQTT_UNEXPECTED_HANGUP](#i-keep-getting-aws_error_mqtt_unexpected_hangup)
* [What certificates do I need?](#what-certificates-do-i-need)
* [I still have more questions about this sdk?](#i-still-have-more-questions-about-this-sdk)

### Where should I start?

If you are just getting started make sure you [install this sdk](https://github.com/aws/aws-iot-device-sdk-swift#installation) and then build and run the [basic PubSub](https://github.com/aws/aws-iot-device-sdk-swift/tree/main/samples#pubsub)

### How do I enable logging?

```
try? Logger.initialize(target: .standardOutput, level: .debug)
```
You can also enable [CloudWatch logging](https://docs.aws.amazon.com/iot/latest/developerguide/cloud-watch-logs.html) for IoT which will provide you with additional information that is not available on the client side sdk.

### I keep getting AWS_ERROR_MQTT_UNEXPECTED_HANGUP

This could be many different things but it most likely is a policy issue. Start with using a super permissive IAM policy called AWSIOTFullAccess which looks like this:

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

After getting it working make sure to only allow the actions and resources that you need. More info about IoT IAM policies can be found [here](https://docs.aws.amazon.com/iot/latest/developerguide/security_iam_service-with-iam.html).

### What certificates do I need?

* You can download pre-generated certificates from the AWS console (this is the simplest and is recommended for testing)
* You can also generate your own certificates to fit your specific use case. You can find documentation for that [here](https://docs.aws.amazon.com/iot/latest/developerguide/x509-client-certs.html) and [here](https://iot-device-management.workshop.aws/en/provisioning-options.html)
* Certificates that you will need to run the samples
    * Root CA Certificates
        * Download the root CA certificate file that corresponds to the type of data endpoint and cipher suite you're using (You most likely want Amazon Root CA 1)
        * Generated and provided by Amazon. You can download it [here](https://www.amazontrust.com/repository/) or download it when getting the other certificates from the AWS console
        * When using samples it can look like this: `--ca_file root-CA.crt`
    * Device certificate
        * Intermediate device certificate that is used to generate the key below
        * When using samples it can look like this: `--cert abcde12345-certificate.pem.crt`
    * Key files
        * You should have generated/downloaded private and public keys that will be used to verify that communications are coming from you
        * When using samples you only need the private key and it will look like this: `--key abcde12345-private.pem.key`

### I still have more questions about this sdk?

* [Here](https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html) are the AWS IoT Core docs for more details about IoT Core
* [Discussion](https://github.com/aws/aws-iot-device-sdk-swift/discussions) questions are also a great way to ask other questions about this sdk.
* [Open an issue](https://github.com/aws/aws-iot-device-sdk-swift/issues) if you find a bug or have a feature request
