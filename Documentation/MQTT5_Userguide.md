# MQTT 5
## Table of Contents

* [Introduction](#introduction)
* [Getting Started with MQTT5](#getting-started-with-mqtt5)
* [Connecting to AWS IoT Core](#connecting-to-aws-iot-core)
* [How to create an MQTT5 Client based on desired connection method](#how-to-create-a-mqtt5-client-based-on-desired-connection-method)
    * [Direct MQTT with X509-based mutual TLS](#direct-mqtt-with-x509-based-mutual-tls)
    * [Direct MQTT with PKCS12 Method](#direct-mqtt-with-pkcs12-method)
    * [Direct MQTT with Custom Authentication](#direct-mqtt-with-custom-authentication)
    * [MQTT over Websockets with Cognito authentication](#mqtt-over-websockets-with-cognito-authentication)
* [Adding an HTTP Proxy](#adding-an-http-proxy)
* [Client Lifecycle Management](#client-lifecycle-management)
    * [Lifecycle Events](#lifecycle-events)
* [Client Operations](#client-operations)
    * [Subscribe](#subscribe)
    * [Unsubscribe](#unsubscribe)
    * [Publish](#publish)
* [MQTT5 Best Practices](#mqtt5-best-practices)

## **Introduction**

This user guide is designed to act as a reference and guide for how to use MQTT5 with the IoT Device SDK for Swift. This guide includes code snippets for how to make an MQTT5 client with proper configuration, how to connect to AWS IoT Core, how to perform operations and interact with AWS IoT Core through MQTT5, and some best practices for MQTT5.

If you are completely new to MQTT, it is highly recommended to check out the following resources to learn more about MQTT:

* MQTT.org getting started: https://mqtt.org/getting-started/
* MQTT.org FAQ (includes list of commonly used terms): https://mqtt.org/faq/
* MQTT on AWS IoT Core documentation: https://docs.aws.amazon.com/iot/latest/developerguide/mqtt.html
* MQTT 5 standard: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html

This user guide expects some beginner level familiarity with MQTT and the terms used to describe MQTT.

## **Getting Started with MQTT5**

This section covers how to use MQTT5 in the Iot Device SDK for Swift. This includes how to setup an MQTT5 builder for making MQTT5 clients, how to connect to AWS IoT Core, and how to perform the operations with the MQTT5 client. Each section below contains code snippets showing the functionality in Swift.

## **Connecting To AWS IoT Core**
We strongly recommend using the `Mqtt5ClientBuilder` class to configure MQTT5 clients when connecting to AWS IoT Core.  The builder simplifies configuration for all authentication methods supported by AWS IoT Core.  This section shows samples for all of the authentication possibilities.

## **How to create an MQTT5 Client based on desired connection method**
### **Lifecycle Events and Optional Configurations**
All lifecycle events and the callback for publishes received by the MQTT5 Client should be added to the `Mqtt5ClientBuilder` prior to calling `build()`. A full list of configuration methods can be found in the API guide.
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
    clientBuilder.withOnPublishReceived(self.onPublishReceived)
```
#### **Direct MQTT with X509-based mutual TLS**
For X509 based mutual TLS, you can create a client where the certificate and private key are configured by path:

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
    
    // Set MQTT5 client callbacks and other options using Mqtt5ClientBuilder functions

    // Create an MQTT5 Client using Mqtt5ClientBuilder
    let client = try clientBuilder.build()
```

#### **Direct MQTT with PKCS12 Method**

An MQTT5 direct connection can be made using a PKCS12 file rather than using a PEM encoded private key. To create an MQTT5 builder configured for this connection, see the following code:

```swift
    let endpoint: String = "<Host name of AWS IoT server>"
    let pkcs12Path: String = "<PKCS12 file path>"
    let pkcs12Password: String = "<PKCS12 password>"
    
    let clientBuilder = try Mqtt5ClientBuilder.mtlsFromPKCS12(
        pkcs12Path: self.pkcs12Path, 
        pkcs12Password: self.pkcs12Password,
        endpoint: self.endpoint)

    // Set MQTT5 client callbacks and other options using Mqtt5ClientBuilder functions

    // Create an MQTT5 Client using Mqtt5ClientBuilder
    let client = try clientBuilder.build()
```

**Note**: TLS integration with PKCS#12 is only available on Apple devices.
#### **Direct MQTT with Custom Authentication**
AWS IoT Core Custom Authentication allows you to use a lambda to gate access to IoT Core resources.  For this authentication method,
you must supply an additional configuration structure containing fields relevant to AWS IoT Core Custom Authentication.
If your custom authenticator does not use signing, you don't specify anything related to the token signature:

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

    // Set MQTT5 client callbacks and other options using Mqtt5ClientBuilder functions

    // Create an MQTT5 Client using Mqtt5ClientBuilder
    let client = try clientBuilder.build()
```

If your custom authorizer uses signing, you must specify the three signed token properties as well. It is your responsibility to URI-encode the auth_username, auth_authorizer_name, and auth_token_key_name parameters.

```swift
    let clientBuilder = try Mqtt5ClientBuilder.directWithUnsignedCustomAuthorizer(
        endpoint: self.endpoint,
        authAuthorizerName: self.authAuthorizerName,
        authAuthorizerSignature: self.authAuthorizerSignature,
        authTokenKeyName: self.authTokenKeyName,
        authTokenValue: self.authTokenValue,
        authUsername: self.authUsername,
        authPassword: self.authPassword)
    
    // Set MQTT5 client callbacks and other options using Mqtt5ClientBuilder functions

    // Create an MQTT5 Client using Mqtt5ClientBuilder
    let client = try clientBuilder.build()
```

In both cases, the builder will construct a final CONNECT packet username field value for you based on the values configured.  Do not add the token-signing fields to the value of the username that you assign within the custom authentication config structure.  Similarly, do not add any custom authentication related values to the username in the CONNECT configuration optionally attached to the client configuration. The builder will do everything for you.

#### **MQTT over Websockets with Cognito authentication**

An MQTT5 websocket connection can be made using Cognito to authenticate rather than the AWS credentials located on the device or via key and certificate. Instead, Cognito can authenticate the connection using a valid Cognito identity ID. This requires a valid Cognito identity ID, which can be retrieved from a Cognito identity pool. A Cognito identity pool can be created from the AWS console.

To create an MQTT5 builder configured for this connection, see the following code:

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
        
    // Set MQTT5 client callbacks and other options using Mqtt5ClientBuilder functions

    // Create an MQTT5 Client using Mqtt5ClientBuilder
    let client = try clientBuilder.build()
```

**Note**: A Cognito identity ID is different from a Cognito identity pool ID and trying to connect with a Cognito identity pool ID will not work. If you are unable to connect, make sure you are passing a Cognito identity ID rather than a Cognito identity pool ID.

### **Adding an HTTP Proxy**
No matter what your connection transport or authentication method is, you may connect through an HTTP proxy
by adding the http_proxy_options keyword argument to the builder:

```python
    http_proxy_options = http.HttpProxyOptions(
        host_name = "<proxy host>",
        port = <proxy port>)

    # Create an MQTT5 Client using mqtt5_client_builder with proxy options as keyword argument
    client = mqtt5_client_builder.mtls_from_path(
        endpoint = "<account-specific endpoint>",
        cert_filepath = "<certificate file path>",
        pri_key_filepath = "<private key file path>",
        http_proxy_options = http_proxy_options))
```

SDK Proxy support also includes support for basic authentication and TLS-to-proxy.  SDK proxy support does not include any additional
proxy authentication methods (kerberos, NTLM, etc...) nor does it include non-HTTP proxies (SOCKS5, for example).

## **Client lifecycle management**
Once created, an MQTT5 client's configuration is immutable.  Invoking start() on the client will put it into an active state where it
recurrently establishes a connection to the configured remote endpoint.  Reconnecting continues until you invoke stop().

```python
    # Create an MQTT5 Client
    client_options = mqtt5.ClientOptions(
        host_name = "<endpoint to connect to>",
        port = <port to use>)

    # Other options in client options can be set but once Client is initialized configuration is immutable
    # e.g. setting the on_publish_callback_fn to be called
    # client_options.on_publish_callback_fn = on_publish_received

    client = mqtt5.Client(client_options)

    # Use the client
    client.start();
    ...
```

Invoking stop() breaks the current connection (if any) and moves the client into an idle state.

```python
    # Shutdown
    client.stop();

```
## **Lifecycle Events**
The MQTT5 client emits a set of events related to state and network status changes.

#### **AttemptingConnect**
Emitted when the client begins to make a connection attempt.

#### **ConnectionSuccess**
Emitted when a connection attempt succeeds based on receipt of an affirmative CONNACK packet from the MQTT broker.  A ConnectionSuccess event includes the MQTT broker's CONNACK packet, as well as a structure -- the NegotiatedSettings -- which contains the final values for all variable MQTT session settings (based on protocol defaults, client wishes, and server response).

#### **ConnectionFailure**
Emitted when a connection attempt fails at any point between DNS resolution and CONNACK receipt.  In addition to an error code, additional data may be present in the event based on the context.  For example, if the remote endpoint sent a CONNACK with a failing reason code, the CONNACK packet will be included in the event data.

#### **Disconnect**
Emitted when the client's network connection is shut down, either by a local action, event, or a remote close or reset.  Only emitted after a ConnectionSuccess event: a network connection that is shut down during the connecting process manifests as a ConnectionFailure event.  A Disconnect event will always include an error code.  If the Disconnect event is due to the receipt of a server-sent DISCONNECT packet, the packet will be included with the event data.

#### **Stopped**
Emitted once the client has shutdown any associated network connection and entered an idle state where it will no longer attempt to reconnect.  Only emitted after an invocation of `stop()` on the client.  A stopped client may always be started again.

## **Client Operations**
There are four basic MQTT operations you can perform with the MQTT5 client.

### Subscribe
The Subscribe operation takes a description of the SUBSCRIBE packet you wish to send and returns a future that resolves successfully with the corresponding SUBACK returned by the broker; the future result raises an exception if anything goes wrong before the SUBACK is received.

```python
    subscribe_future = client.subscribe(subscribe_packet = mqtt5.SubscribePacket(
        subscriptions = [mqtt5.Subscription(
            topic_filter = "hello/world/qos1",
            qos = mqtt5.QoS.AT_LEAST_ONCE)]))

    suback = subscribe_future.result()
```

### Unsubscribe
The Unsubscribe operation takes a description of the UNSUBSCRIBE packet you wish to send and returns a future that resolves successfully with the corresponding UNSUBACK returned by the broker; the future result raises an exception if anything goes wrong before the UNSUBACK is received.

```python
    unsubscribe_future = client.unsubscribe(unsubscribe_packet = mqtt5.UnsubscribePacket(
        topic_filters=["hello/world/qos1"]))

    unsuback = unsubscribe_future.result()
```

### Publish
The Publish operation takes a description of the PUBLISH packet you wish to send and returns a future of polymorphic value.  The future will result in a PublishCompletionData containing a PUBACK packet. If the PUBLISH was a QoS 0 publish, then the PUBACK packet will be empty with all members set to None and is completed as soon as the packet has been written to the socket.  If the PUBLISH was a QoS 1 publish, then the PUBACK packet will contain a reason_code and potentially a reason_string and user_properties if the broker has assigned them any values and is completed as soon as the PUBACK is received from the broker.  If the operation fails for any reason before these respective completion events, the future result raises an exception.

```python
    publish_future = client.publish(mqtt5.PublishPacket(
        topic = "hello/world/qos1",
        payload = "This is the payload of a QoS 1 publish",
        qos = mqtt5.QoS.AT_LEAST_ONCE))

    # on success, the result of publish_future will be a PublishCompletionData
    publish_completion_data = publish_future.result()
    puback = publish_completion_data.puback

```

### Disconnect
The `stop()` API supports a DISCONNECT packet as an optional parameter.  If supplied, the DISCONNECT packet will be sent to the server prior to closing the socket.  There is no future returned by a call to `stop()` but you may listen for the 'stopped' event on the client.

```python
    client.stop(mqtt5.DisconnectPacket(
        reason_code = mqtt5.DisconnectReasonCode.NORMAL_DISCONNECTION,
        session_expiry_interval_sec = 3600))
```

## **MQTT5 Best Practices**

Below are some best practices for the MQTT5 client that are recommended to follow for the best development experience:

* When creating MQTT5 clients, make sure to use ClientIDs that are unique! If you connect two MQTT5 clients with the same ClientID, they will Disconnect each other! If you do not configure a ClientID, the MQTT5 server will automatically assign one.
* Use the minimum QoS you can get away with for the lowest latency and bandwidth costs. For example, if you are sending data consistently multiple times per second and do not have to have a guarantee the server got each and every publish, using QoS 0 may be ideal compared to QoS 1. Of course, this heavily depends on your use case but generally it is recommended to use the lowest QoS possible.
* If you are getting unexpected disconnects when trying to connect to AWS IoT Core, make sure to check your IoT Core Thing’s policy and permissions to make sure your device is has the permissions it needs to connect!
* For **Publish**, **Subscribe**, and **Unsubscribe**, you can check the reason codes in the returned Future to see if the operation actually succeeded.
* You MUST NOT perform blocking operations on any callback, or you will cause a deadlock. For example: in the `on_publish_received` callback, do not send a publish, and then wait for the future to complete within the callback. The Client cannot do work until your callback returns, so the thread will be stuck.
