///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCommonRuntimeKit

fileprivate func getMetricsStr(currentUsername: String = "") -> String {
    // Check if the username being used already has a query
    var usernameHasQuery = false
    if currentUsername.contains("?") {
        usernameHasQuery = true
    }

    let metricsStr = "SDK=SwiftV1&Version=\(packageVersion)"

    // Based on whether username already had a query, we are adding to the query
    // or beginning one.
    if usernameHasQuery {
        return "&" + metricsStr
    } else {
        return "?" + metricsStr
    }
}

fileprivate func createMqttClient(
    endpoint: String,
    port: UInt32 = 8883,
    clientId: String? = nil,
    username: String? = nil,
    password: Data? = nil,
    tlsCtx: TLSContext? = nil,
    keepAliveInterval: TimeInterval = 1200,
    sessionExpiryInterval: TimeInterval? = nil,
    onPublishReceived: OnPublishReceived? = nil,
    onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess? = nil,
    onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure? = nil,
    onLifecycleEventDisconnection: OnLifecycleEventDisconnection? = nil,
    onLifecycleEventStopped: OnLifecycleEventStopped? = nil,
    enableMetricsCollection: Bool = true
) -> Mqtt5Client {

    var metricsUsername: String? = username ?? nil
    if enableMetricsCollection {
        metricsUsername = ""
        let baseUsername = username ?? ""
        metricsUsername = baseUsername + getMetricsStr(currentUsername: baseUsername)
    }

    print("metrics username: " + (metricsUsername ?? "username is nil")) // DEBUG WIP
    
    // Configure connection options
    let connectOptions = MqttConnectOptions(
        keepAliveInterval: keepAliveInterval,
        clientId: clientId,
        username: metricsUsername,
        password: password,
        sessionExpiryInterval: sessionExpiryInterval
    )
    
    // Configure client options
    let clientOptions = MqttClientOptions(
        hostName: endpoint,
        port: port,
        tlsCtx: tlsCtx,
        connectOptions: connectOptions,
        onPublishReceivedFn: onPublishReceived,
        onLifecycleEventStoppedFn: onLifecycleEventStopped,
        onLifecycleEventConnectionSuccessFn: onLifecycleEventConnectionSuccess,
        onLifecycleEventConnectionFailureFn: onLifecycleEventConnectionFailure,
        onLifecycleEventDisconnectionFn: onLifecycleEventDisconnection)

    // Return the configured Mqtt5Client
    do {
        return try Mqtt5Client(clientOptions: clientOptions)
    } catch {
        fatalError("Failed to create Mqtt5Client: \(error)")
    }
}

public class Mqtt5ClientBuilder {

    public func mtlsFromPath(
        certPath: String, 
        keyPath: String,
        endpoint: String,
        port: UInt32 = 8883,
        clientId: String? = nil,
        username: String? = nil,
        password: Data? = nil,
        keepAliveInterval: TimeInterval = 1200,
        sessionExpiryInterval: TimeInterval? = nil,
        onPublishReceived: OnPublishReceived? = nil,
        onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess? = nil,
        onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure? = nil,
        onLifecycleEventDisconnection: OnLifecycleEventDisconnection? = nil,
        onLifecycleEventStopped: OnLifecycleEventStopped? = nil,
        enableMetricsCollection: Bool = true) -> Mqtt5Client {
        
        var tlsOptions: TLSContextOptions
        do { 
            tlsOptions = try TLSContextOptions.makeMTLS(certificatePath: certPath, privateKeyPath: keyPath)
        } catch {
            fatalError("Failed to create TLSContextOptions: \(error)")
        }
        var tlsContext: TLSContext
        do {
            tlsContext = try TLSContext(options:tlsOptions, mode: .client)
        } catch {
            fatalError("Failed to create TLSContext: \(error)")
        }

        return createMqttClient(
            endpoint: endpoint,
            port: port,
            clientId: clientId,
            username: username,
            tlsCtx: tlsContext,
            keepAliveInterval: keepAliveInterval,
            sessionExpiryInterval: sessionExpiryInterval,
            onPublishReceived: onPublishReceived,
            onLifecycleEventConnectionSuccess: onLifecycleEventConnectionSuccess,
            onLifecycleEventConnectionFailure: onLifecycleEventConnectionFailure,
            onLifecycleEventDisconnection: onLifecycleEventDisconnection,
            onLifecycleEventStopped: onLifecycleEventStopped,
            enableMetricsCollection: enableMetricsCollection)
    }

    public func mtlsFromData(
        certData: Data, 
        keyData: Data,
        endpoint: String,
        port: UInt32 = 8883,
        clientId: String? = nil,
        username: String? = nil,
        password: Data? = nil,
        keepAliveInterval: TimeInterval = 1200,
        sessionExpiryInterval: TimeInterval? = nil,
        onPublishReceived: OnPublishReceived? = nil,
        onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess? = nil,
        onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure? = nil,
        onLifecycleEventDisconnection: OnLifecycleEventDisconnection? = nil,
        onLifecycleEventStopped: OnLifecycleEventStopped? = nil,
        enableMetricsCollection: Bool = true) -> Mqtt5Client {
        
        var tlsOptions: TLSContextOptions
        do { 
            tlsOptions = try TLSContextOptions.makeMTLS(certificateData: certData, privateKeyData: keyData)
        } catch {
            fatalError("Failed to create TLSContextOptions: \(error)")
        }
        var tlsContext: TLSContext
        do {
            tlsContext = try TLSContext(options:tlsOptions, mode: .client)
        } catch {
            fatalError("Failed to create TLSContext: \(error)")
        }

        return createMqttClient(
            endpoint: endpoint,
            port: port,
            clientId: clientId,
            username: username,
            tlsCtx: tlsContext,
            keepAliveInterval: keepAliveInterval,
            sessionExpiryInterval: sessionExpiryInterval,
            onPublishReceived: onPublishReceived,
            onLifecycleEventConnectionSuccess: onLifecycleEventConnectionSuccess,
            onLifecycleEventConnectionFailure: onLifecycleEventConnectionFailure,
            onLifecycleEventDisconnection: onLifecycleEventDisconnection,
            onLifecycleEventStopped: onLifecycleEventStopped,
            enableMetricsCollection: enableMetricsCollection)
    }

    public func mtlsFromPKCS12(
        pkcs12Path: String, 
        pkcs12Password: String,
        endpoint: String,
        port: UInt32 = 8883,
        clientId: String? = nil,
        username: String? = nil,
        password: Data? = nil,
        keepAliveInterval: TimeInterval = 1200,
        sessionExpiryInterval: TimeInterval? = nil,
        onPublishReceived: OnPublishReceived? = nil,
        onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess? = nil,
        onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure? = nil,
        onLifecycleEventDisconnection: OnLifecycleEventDisconnection? = nil,
        onLifecycleEventStopped: OnLifecycleEventStopped? = nil,
        enableMetricsCollection: Bool = true)  -> Mqtt5Client {
        
        var tlsOptions: TLSContextOptions
        do { 
            tlsOptions = try TLSContextOptions.makeMTLS(pkcs12Path: pkcs12Path, password: pkcs12Password)
        } catch {
            fatalError("Failed to create TLSContextOptions: \(error)")
        }
        var tlsContext: TLSContext
        do {
            tlsContext = try TLSContext(options:tlsOptions, mode: .client)
        } catch {
            fatalError("Failed to create TLSContext: \(error)")
        }

        return createMqttClient(
            endpoint: endpoint,
            port: port,
            clientId: clientId,
            username: username,
            tlsCtx: tlsContext,
            keepAliveInterval: keepAliveInterval,
            sessionExpiryInterval: sessionExpiryInterval,
            onPublishReceived: onPublishReceived,
            onLifecycleEventConnectionSuccess: onLifecycleEventConnectionSuccess,
            onLifecycleEventConnectionFailure: onLifecycleEventConnectionFailure,
            onLifecycleEventDisconnection: onLifecycleEventDisconnection,
            onLifecycleEventStopped: onLifecycleEventStopped,
            enableMetricsCollection: enableMetricsCollection)
        }

    public func websocketsWithDefaultAwsSigning(
        region: String, 
        credentialsProvider: CredentialsProvider,
        endpoint: String,
        port: UInt32 = 8883,
        clientId: String? = nil,
        username: String? = nil,
        password: Data? = nil,
        keepAliveInterval: TimeInterval = 1200,
        sessionExpiryInterval: TimeInterval? = nil,
        onPublishReceived: OnPublishReceived? = nil,
        onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess? = nil,
        onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure? = nil,
        onLifecycleEventDisconnection: OnLifecycleEventDisconnection? = nil,
        onLifecycleEventStopped: OnLifecycleEventStopped? = nil,
        enableMetricsCollection: Bool = true)  -> Mqtt5Client {

        let tlsOptions = TLSContextOptions.makeDefault()
         
        var tlsContext: TLSContext
        do {
            tlsContext = try TLSContext(options: tlsOptions, mode: .client)
        } catch {
            fatalError("Failed to create TLSContext: \(error)")
        }
            
        // let signingConfig = SigningConfig(
        //     algorithm: SigningAlgorithmType.signingV4,
        //     signatureType: SignatureType.requestQueryParams,
        //     service: "iotdevicegateway",
        //     region: region,
        //     credentialsProvider: credentialsProvider,
        //     omitSessionToken: true
        // )

        return createMqttClient(
            endpoint: endpoint,
            port: port,
            clientId: clientId,
            tlsCtx: tlsContext,
            keepAliveInterval: keepAliveInterval,
            sessionExpiryInterval: sessionExpiryInterval,
            onPublishReceived: onPublishReceived,
            onLifecycleEventConnectionSuccess: onLifecycleEventConnectionSuccess,
            onLifecycleEventConnectionFailure: onLifecycleEventConnectionFailure,
            onLifecycleEventDisconnection: onLifecycleEventDisconnection,
            onLifecycleEventStopped: onLifecycleEventStopped,
            enableMetricsCollection: enableMetricsCollection)
        }
    }
