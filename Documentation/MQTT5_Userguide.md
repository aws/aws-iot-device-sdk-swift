# MQTT 5 User Guide
## Table of Contents

* [Introduction](#introduction)
* [Getting Started with MQTT 5](#getting-started-with-mqtt-5)
* [Connecting to AWS IoT Core](#connecting-to-aws-iot-core)
* [Creating an MQTT 5 Client](#creating-an-mqtt-5-client)
    * [Direct MQTT with X.509-based Mutual TLS](#direct-mqtt-with-x509-based-mutual-tls)
    * [Direct MQTT with PKCS #12 Method](#direct-mqtt-with-pkcs-12-method)
    * [Direct MQTT with Custom Authentication](#direct-mqtt-with-custom-authentication)
    * [MQTT over WebSockets with Amazon Cognito Authentication](#mqtt-over-websockets-with-amazon-cognito-authentication)
* [Assigning Callbacks and Optional Configurations](#assigning-callbacks-and-optional-configurations)
    * [Adding Callbacks](#adding-callbacks)
    * [Adding an HTTP Proxy](#adding-an-http-proxy)
* [Client Lifecycle Management](#client-lifecycle-management)
    * [Lifecycle Events](#lifecycle-events)
* [Client Operations](#client-operations)
    * [Subscribe](#subscribe)
    * [Unsubscribe](#unsubscribe)
    * [Publish](#publish)
* [MQTT 5 Best Practices](#mqtt-5-best-practices)

## **Introduction**

This user guide is a reference for how to use MQTT 5 with the AWS IoT Device SDK for Swift. It includes code snippets for how to make an MQTT 5 client with the proper configuration, how to connect to AWS IoT Core, how to perform operations and interact with AWS IoT Core through MQTT 5, and some best practices for MQTT 5.

If you're new to MQTT, we recommended the following resources to learn more about MQTT:

* [Getting started](https://mqtt.org/getting-started/) on the MQTT website.
* [FAQ](https://mqtt.org/faq/) on the MQTT website
* [MQTT](https://docs.aws.amazon.com/iot/latest/developerguide/mqtt.html) in the AWS IoT Core Developer Guide 
* [MQTT v5.0 specification](https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html)

This user guide expects some beginner level familiarity with MQTT and the terms used to describe MQTT.

## **Getting Started with MQTT 5**

This section covers how to use MQTT 5 in the AWS IoT Device SDK for Swift. This includes how to set up an MQTT 5 builder for making MQTT 5 clients, how to connect to AWS IoT Core, and how to perform the operations with the MQTT 5 client. Each section contains code snippets showing the functionality in Swift.

## **Connecting to AWS IoT Core**
We strongly recommend using the `Mqtt5ClientBuilder` class to configure MQTT 5 clients when connecting to AWS IoT Core. The builder simplifies configuration for all authentication methods supported by AWS IoT Core. This section shows samples for all of the authentication possibilities.

## **Creating an MQTT 5 Client**
#### **Direct MQTT with X.509-based Mutual TLS**
For X.509-based Mutual TLS (mTLS), you can create a client where the certificate and private key are configured by the following path:

```swift
    let endpoint: String = "<Host name of AWS IoT server>"
    // X.509 based certificate file
    let certPath: String = "<certificate file path>"
    // PKCS#8 PEM encoded private key file
    let keyPath: String = "<private key file path>"

    let clientBuilder = try Mqtt5ClientBuilder.mtlsFromPath(
        certPath: self.certPath, 
        keyPath: self.keyPath, 
        endpoint: self.endpoint)
    
    // Set MQTT 5 client callbacks and other options using Mqtt5ClientBuilder functions (see next section)

    // Create an MQTT 5 client using Mqtt5ClientBuilder
    let client = try clientBuilder.build()
```

#### **Direct MQTT with PKCS #12 Method**

An MQTT 5 direct connection can be made using a PKCS #12 file rather than using a PEM encoded private key. To create an MQTT 5 builder configured for this connection, see the following code:

```swift
    let endpoint: String = "<Host name of AWS IoT server>"
    let pkcs12Path: String = "<PKCS #12 file path>"
    let pkcs12Password: String = "<PKCS #12 password>"
    
    let clientBuilder = try Mqtt5ClientBuilder.mtlsFromPKCS12(
        pkcs12Path: self.pkcs12Path, 
        pkcs12Password: self.pkcs12Password,
        endpoint: self.endpoint)

    // Set MQTT 5 client callbacks and other options using Mqtt5ClientBuilder functions (see next section)

    // Create an MQTT 5 client using Mqtt5ClientBuilder
    let client = try clientBuilder.build()
```

**Note**: TLS integration with PKCS #12 is only available on Apple devices.
#### **Direct MQTT with Custom Authentication**
AWS IoT Core custom authentication allows you to use an AWS Lambda to gate access to AWS IoT Core resources. For this authentication method,
you must supply an additional configuration structure containing fields relevant to AWS IoT Core custom authentication.
If your custom authenticator doesn't use signing, you don't need to specify anything related to the token signature:

```swift
    let endpoint: String = "<account-specific endpoint>"
    let authAuthorizerName: String = "<Name of your custom authorizer>"
    let authPassword: Data = "<Password used with custom authorizer>"
    let authUsername: Sting = "<Username to use with custom authorizer>"

    let clientBuilder = try Mqtt5ClientBuilder.directWithUnsignedCustomAuthorizer(
        endpoint: self.endpoint,
        authAuthorizerName: self.authAuthorizerName,
        authPassword: self.authPassword,
        authUsername: self.authUsername)

    // Set MQTT 5 client callbacks and other options using Mqtt5ClientBuilder functions (see next section)

    // Create an MQTT 5 client using Mqtt5ClientBuilder
    let client = try clientBuilder.build()
```

If your custom authorizer uses signing, you must specify the three signed token properties as well. It's your responsibility to URI-encode the `auth_username`, `auth_authorizer_name`, and `auth_token_key_name` parameters.

```swift
    let clientBuilder = try Mqtt5ClientBuilder.directWithUnsignedCustomAuthorizer(
        endpoint: self.endpoint,
        authAuthorizerName: self.authAuthorizerName,
        authAuthorizerSignature: self.authAuthorizerSignature,
        authTokenKeyName: self.authTokenKeyName,
        authTokenValue: self.authTokenValue,
        authUsername: self.authUsername,
        authPassword: self.authPassword)
    
    // Set MQTT 5 client callbacks and other options using Mqtt5ClientBuilder functions (see next section)

    // Create an MQTT 5 client using Mqtt5ClientBuilder
    let client = try clientBuilder.build()
```

In both cases, the builder will construct a final `CONNECT` packet username field value for you based on the values configured. Don't add the token-signing fields to the value of the username that you assign within the custom authentication config structure. Similarly, don't add any custom authentication related values to the username in the `CONNECT` configuration optionally attached to the client configuration. The builder will do everything for you.

#### **MQTT over WebSockets with Amazon Cognito Authentication**

An MQTT 5 WebSocket connection can be made using Amazon Cognito to authenticate rather than the AWS credentials located on the device or by using the key and certificate. Instead, Amazon Cognito can authenticate the connection using a valid identity ID. This requires a valid identity ID, which can be retrieved from an Amazon Cognito identity pool. An Amazon Cognito identity pool can be created from the AWS Management Console.

To create an MQTT 5 builder configured for this connection, see the following code:

```swift
    // The signing region. e.x.: 'us-east-1'
    let signingRegion: String = "<signing region>"

    # See https://docs.aws.amazon.com/general/latest/gr/cognito_identity.html for Cognito endpoints
    let cognitoEndpoint: String = "cognito-identity." + signing_region + ".amazonaws.com"
    let cognitoIdentityId = "<Cognito identity ID>"

    // Create bootstrap and tlsContext for the cognito provider
    let elg = try EventLoopGroup()
    let resolver = try HostResolver(eventLoopGroup: elg, maxHosts: 16, maxTTL: 30)
    let clientBootstrap = try ClientBootstrap(
        eventLoopGroup: elg,
        hostResolver: resolver)        
    let options = TLSContextOptions.makeDefault()
    let tlsContext = try TLSContext(options: options, mode: .client)

    // Create the cognito provider
    let cognitoProvider = try CredentialsProvider(
        source: .cognito(
            bootstrap: self.clientBootstrap,
            tlsContext: self.tlsContext,
            endpoint: self.cognitoEndpoint, 
            identity: self.cognitoIdentity))

    // Create the Mqtt5ClientBuilder
    let clientBuilder = try Mqtt5ClientBuilder.websocketsWithDefaultAwsSigning(
        endpoint: self.endpoint, 
        region: self.region,
        credentialsProvider: cognitoProvider);
        
    // Set MQTT 5 client callbacks and other options using Mqtt5ClientBuilder functions (see next section)

    // Create an MQTT 5 client using Mqtt5ClientBuilder
    let client = try clientBuilder.build()
```

**Note**: An Amazon Cognito identity ID is different from an identity pool ID, and trying to connect with an identity pool ID won't work. If you're unable to connect, make sure you're passing an identity ID rather than an identity pool ID.

## **Assigning Callbacks and Optional Configurations**
All lifecycle events and the callback for publishes received by the MQTT 5 client should be added to the `Mqtt5ClientBuilder` prior to calling `build()`. A full list of configuration methods can be found in the [API guide](https://docs.aws.amazon.com/iot/latest/apireference/Welcome.html).

### **Adding Callbacks**
``` swift
    // After creating an instance of the `Mqtt5ClientBuilder`

    // All callbacks can be assigned using the `withCallbacks()` func
    clientBuilder.withCallbacks(onPublishReceived: self.onPublishReceived,
                                onLifecycleEventAttemptingConnect: self.onLifecycleEventAttemptingConnect,
                                onLifecycleEventConnectionSuccess: self.onLifecycleEventConnectionSuccess,
                                onLifecycleEventConnectionFailure: self.onLifecycleEventConnectionFailure,
                                onLifecycleEventDisconnection: self.onLifecycleEventDisconnection,
                                onLifecycleEventStopped: self.onLifecycleEventStopped)

    // Individual callbacks can also be assigned independently
    // e.g.
    clientBuilder.withOnPublishReceived(self.onPublishReceived)
```
### **Adding an HTTP Proxy**
No matter what your connection transport or authentication method is, you can connect through an HTTP proxy
by adding `HTTPProxyOptions` to the builder:

```swift
    // After creating the Mqtt5ClientBuilder

    // add HTTPProxyOptions to the builder
    builder.withHttyProxyOptions(HTTPProxyOptions(hostName: "<Http Proxy Host>", port: <Http Proxy Port>))

    // Create an MQTT5 Client using Mqtt5ClientBuilder
    let client = try clientBuilder.build()
```

SDK Proxy support also includes support for basic authentication and TLS-to-proxy. SDK proxy support doesn't include any additional
proxy authentication methods (Kerberos, NTLM, etc.) It also doesn't include non-HTTP proxies (like SOCKS5).

## **Client lifecycle management**
Once created, an MQTT 5 client's configuration is immutable.  Invoking `start()` on the client will put it into an active state where it
recurrently establishes a connection to the configured remote endpoint. Reconnecting continues until you invoke `stop()`.

```swift
    // Create an MQTT 5 client using a configured Mqtt5ClientBuilder    
    let client = try clientBuilder.build()

    # Use the client
    try client.start()
    ...
```

Invoking `stop()` breaks the current connection (if any) and moves the client into an idle state.

```swift
    // Shutdown
    try client.stop()
    ...
```
## **Lifecycle Events**
The MQTT 5 client emits a set of events related to state and network status changes. 

#### **AttemptingConnect**
Emitted when the client begins to make a connection attempt.

#### **ConnectionSuccess**
Emitted when a connection attempt succeeds based on receipt of an affirmative `CONNACK` packet from the MQTT broker. A ConnectionSuccess event includes the MQTT broker's `CONNACK` packet, as well as a `NegotiatedSettings` which contains the final values for all variable MQTT session settings (based on protocol defaults, client wishes, and server response) within the `LifecycleConnectionSuccessData`.

#### **ConnectionFailure**
Emitted when a connection attempt fails at any point between DNS resolution and `CONNACK` receipt. In addition to an error code, additional data may be present in the event based on the context. For example, if the remote endpoint sent a `CONNACK` with a failing reason code, the `CONNACK` packet will be included within the `LifecycleConnectionFailureData`.

#### **Disconnect**
Emitted when the client's network connection is shut down, either by a local action, event, or a remote close or reset. Only emitted after a ConnectionSuccess event, a network connection that's shut down during the connecting process manifests as a `ConnectionFailure` event. A disconnect event will always include an error code. If the disconnect event is due to the receipt of a server-sent `DISCONNECT` packet, the packet will be included within the `LifecycleDisconnectData`.

#### **Stopped**
Emitted once the client has shut down any associated network connection and entered an idle state where it will no longer attempt to reconnect. Only emitted after an invocation of `stop()` on the client. A stopped client can be started again.

## **Client Operations**
There are four basic MQTT operations you can perform with the MQTT 5 client.

### Subscribe
The `Subscribe` operation takes a description of the `SUBSCRIBE` packet you wish to send and asynchronously returns the corresponding `SUBACK` returned by the broker. The operation throws an exception if anything goes wrong before the `SUBACK` is received.

```swift
    let subscribePacket: SubscribePacket = SubscribePacket(topicFilter: "<topic>", qos: <QoS>, payload: <payload>)
    let subackPacket: SubackPacket = try await client.subscribe(subscribePacket: subscribePacket)
```

### Unsubscribe
The `Unsubscribe` operation takes a description of the `UNSUBSCRIBE` packet you wish to send and asynchronously returns the corresponding `UNSUBACK` returned by the broker. The operation throws an exception if anything goes wrong before the `UNSUBACK` is received.

```swift
    let unsubscribePacket: UnsubscribePacket = UnsubscribePacket(topicFilter: "<topic>")
    let unsubackPacket: UnsubackPacket = try await client.unsubscribe(unsubscribePacket: unsubscribePacket)
```

### Publish
The `Publish` operation takes a description of the PUBLISH packet you wish to send and asynchronously returns a `PublishResult`. If the PUBLISH was a QoS 0 publish, the `PublishResult` will be returned as soon as the PUBLISH packet is written to the socket and will contain a nil `PubackPacket`. If the PUBLISH was a QoS 1 publish, the `PublishResult` will be returned upon receipt of a PUBACK packet from the broker or when the operation times out. The `PubackPacket` contained within the `PublishResult` will contain a reasonCode and potentially a reasonString and userProperties if the broker has assigned them any values. If the operation fails for any reason before these respective completion events, the operation will throw an exception.

```swift
    let publishPacket: PublishPacket = PublishPacket(qos: .atLeastOnce, topic: "<topic>", payload: <Data>)
    let publishResult: PublishResult = try await client.publish(publishPacket: self.publishPacket)

    // on success of a QoS1 PUBLISH, the publishResult will contain a `PubackPacket`
    if pubackPacket: PubackPacket = publishResult.puback {
        print("PubackPacket received with result \(pubackPacket.reasonCode)")
    }

```

### Disconnect
The `stop()` API supports a DISCONNECT packet as an optional parameter.  If supplied, the DISCONNECT packet will be sent to the server prior to closing the socket.  Nothing is returned by a call to `stop()` but you may listen for the 'stopped' event on the client. The operation throws an exception if anything goes wrong.

```swift
    let disconnectPacket: DisconnectPacket = DisconnectPacket(reasonCode: DisconnectReasonCode.normalDisconnection)
    try client.stop(disconnectPacket: this.disconnectPacket)
```

## **MQTT 5 Best Practices**

The following are some best practices for the MQTT 5 client that help provide the best development experience:

* When creating MQTT 5 clients, make sure to use client IDs that are unique. If you connect two MQTT 5 clients with the same client ID, they will disconnect each other. If you don't configure a client ID, the MQTT 5 server will automatically assign one.
* Use the minimum Quality of service (QoS) you can get away with for the lowest latency and bandwidth costs. For example, if you're sending data consistently multiple times per second and don't have to have a guarantee the server got each and every publish, using QoS 0 may be ideal compared to QoS 1. Of course, this heavily depends on your use case but it's generally recommended to use the lowest QoS possible.
* If you are getting unexpected disconnects when trying to connect to AWS IoT Core, make sure to check your AWS IoT Core thing’s policy and permissions to make sure your device is has the permissions it needs to connect.
* For **Publish**, **Subscribe**, and **Unsubscribe**, you can check the reason codes in the returned Future to see if the operation actually succeeded.
* You must not perform blocking operations (like waiting for a publish result) within any callback, as this can cause a deadlock. Additionally, the client pauses socket I/O operations until the user callback returns, so blocking within the callback will prevent further progress.
