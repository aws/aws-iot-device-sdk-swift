// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

// ArgumentParser is used by the sample to parse arguments.
// This is not a required import for the MQTT5 Client.
import ArgumentParser

import Foundation
import AwsIotDeviceSdkSwift


// This sample creates an MQTT5 client and connects using a Cognito Provider and a websocket.
// Here are the steps to setup a client and connect.
// 0. Sample only: Parse command line arguments
// 1. Initialize Device Sdk library
// 2. Setup Credentials Provider
// 3. Create Mqtt5ClientBuilder 
// 4. Setup Callbacks and other options
// 5. Create an Mqtt5 Client with Mqtt5ClientBuilder
// 6. Start the connection session
// 7. Stop the connection session


@main
struct CognitoWithWebsocketSample: ParsableCommand {
    /**************************************
    * 0. Sample only: Parse command line arguments
    **************************************/
    @Argument(help: "The endpoint to connect to.")
    var endpoint: String

    @Argument(help: "The signing region used for the websocket signer.")
    var region: String

    @Argument(help: "The Cognito identity ID to use to connect via Cognito.")
    var cognitoIdentity: String
    
    @Argument(help: "Client id to use (optional). Please make sure the client id matches the policy.")
    var clientId: String = "test-" + UUID().uuidString
    
    // The main function to run
    mutating func run() throws {
        // We use DispatchSemaphore in the sample to wait for various lifecycle events before proceeding.
        // You would not typically use them in this manner in your own production code.
        let connectionSemaphore = DispatchSemaphore(value: 0)
        let stoppedSemaphore = DispatchSemaphore(value: 0)
        
        /**************************************
         * 1. Initialize Device Sdk library
         **************************************/
        // The IoT Device SDK must be initialized before it is used.
        IotDeviceSdk.initialize();
        
        do {
            /**************************************
             * 2. Setup Credentials Provider
             **************************************/
            // Create bootstrap and tlsContext for the cognito provider
            let elg = try EventLoopGroup()
            let resolver = try HostResolver(eventLoopGroup: elg, maxHosts: 16, maxTTL: 30)
            let clientBootstrap = try ClientBootstrap(eventLoopGroup: elg, hostResolver: resolver)

            let tlsOptions = TLSContextOptions.makeDefault()
            let tlsContext = try TLSContext(options: tlsOptions, mode: .client)

            let cognitoEndpoint = "cognito-identity." + self.region + ".amazonaws.com";
            // Create the cognito provider
            let cognitoProvider = try CredentialsProvider(source: .cognito(bootstrap: clientBootstrap, 
                                                                           tlsContext: tlsContext, 
                                                                           endpoint: cognitoEndpoint, 
                                                                           identity: cognitoIdentity))


            /**************************************
             * 3. Create Mqtt5ClientBuilder 
             **************************************/
             // Create an Mqtt5ClientBuilder configured to connect using a Cognito Provider over a Websocket.
            let clientBuilder = try Mqtt5ClientBuilder.websocketsWithDefaultAwsSigning(
                endpoint: endpoint, 
                region: region, 
                credentialsProvider: cognitoProvider)                        


            /**************************************
             * 4. Setup Callbacks and other options
             **************************************/
            // Callbacks to be assigned to builder
            // The full list of callbacks and their uses can be found in the MQTT5 User Guide
            func onLifecycleEventStopped(_: LifecycleStoppedData) async -> Void {
                print("Mqtt5Client: onLifecycleEventStopped callback invoked.")
                stoppedSemaphore.signal()
            }
            func onLifecycleEventAttemptingConnect(_: LifecycleAttemptingConnectData) async -> Void {
                print("Mqtt5Client: onLifecycleEventAttemptingConnect callback invoked.")
            }
            func onLifecycleEventConnectionSuccess(_ : LifecycleConnectionSuccessData) async -> Void {
                print("Mqtt5Client: onLifecycleEventConnectionSuccess callback invoked.")
                connectionSemaphore.signal()
            }
            func onLifecycleEventConnectionFailure(failureData: LifecycleConnectionFailureData) async -> Void {
                print("Mqtt5Client: onLifecycleEventConnectionFailure callback invoked with Error Code \(failureData.crtError.code): \(failureData.crtError.message)")
            }
            func onLifecycleEventDisconnection(disconnectionData: LifecycleDisconnectData) async -> Void {
                print("Mqtt5Client: onLifecycleEventDisconnection callback invoked with Error Code \(disconnectionData.crtError.code): \(disconnectionData.crtError.message)")
            }                                

            // Callbacks can be assigned all at once using `withCallbacks` on the Mqtt5ClientBuilder
            clientBuilder.withCallbacks(onLifecycleEventAttemptingConnect: onLifecycleEventAttemptingConnect,
                                        onLifecycleEventConnectionSuccess: onLifecycleEventConnectionSuccess,
                                        onLifecycleEventConnectionFailure: onLifecycleEventConnectionFailure,
                                        onLifecycleEventDisconnection: onLifecycleEventDisconnection,
                                        onLifecycleEventStopped: onLifecycleEventStopped)

            // They can also be assinged individually
            clientBuilder.withOnLifecycleEventConnectionSuccess(onLifecycleEventConnectionSuccess)            
            
            // Various other configuration options can be set on the Mqtt5ClientBuilder.
            clientBuilder.withClientId(clientId);

            /**********************************************
             * 5. Create an Mqtt5 Client with Mqtt5ClientBuilder
             ***********************************************/
            let client = try clientBuilder.build()
            
            
            /**************************************
             * 6. Start the connection session
             **************************************/
            // `start()` will put the Mqtt5 Client in a state that desires to be connected. A connection attempt will be made.
            // If an attempt fails, the client will continue to attempt connections until it is instructed to `stop()`.
            try client.start()

            // Wait for a successful connection before proceeding with the sample.
            connectionSemaphore.wait()
            
            
            /**************************************
             * 7. Stop the connection session
             **************************************/
            // `stop()` will put the Mqtt5 Client in a state that desires to be disconnected. If in a connected state, the client
            // will disconnect and not attempt to connect until it is instructed to `start()`.
            try client.stop()

            // Wait for the client to be stopped before exiting the sample.
            stoppedSemaphore.wait()

            print("Sample complete.")
        } catch {
            print("Failed to setup client.")
        }
    }
}
