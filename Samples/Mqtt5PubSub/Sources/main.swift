// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

// ArgumentParser is used by the sample to parse arguments.
// This is not a required import for the MQTT5 Client.
import ArgumentParser

import Foundation
import AwsIotDeviceSdkSwift


// This sample creates an MQTT5 client and connects using X509 certificate and private key files, 
// subscribes to a topic, and publishes to the topic.
// Here is the steps to setup a client and connection
// 0. Sample only: Parse command line arguments
// 1. Initialize Device Sdk library
// 2. Create Mqtt5ClientBuilder 
// 3. Setup Callbacks and other options
// 4. Start the connection session
// 5. Subscribe to topic
// 6. Publish to topic
// 7. Stop the connection session

@main
struct Mqtt5PubSubSample: ParsableCommand {
    /**************************************
    * 0. Sample only: Parse command line arguments
    **************************************/    
    @Argument(help: "The endpoint to connect to.")
    var endpoint: String
    
    @Argument(help: "The path to the certificate file.")
    var cert: String
    
    @Argument(help: "The path to the private key file.")
    var key: String
    
    @Argument(help: "Client id to use (optional). Please make sure the client id matches the policy.")
    var clientId: String = "test-" + UUID().uuidString

    @Argument(help: "The topic to subscribe to.")
    var topic: String = "test/topic"

    @Argument(help: "The payload message to use in the publish packet.")
    var payloadMessage: String = "Sample payload message."
    
    // The main function to run
    mutating func run() throws {
        print("Starting Mqtt5PubSub Sample.")
        // We use DispatchSemaphore in the sample to wait for various lifecycle events before proceeding.
        // You would not typically use them in this manner in your own production code.
        let connectionSemaphore = DispatchSemaphore(value: 0)
        let stoppedSemaphore = DispatchSemaphore(value: 0)
        let subscribeSemaphore = DispatchSemaphore(value: 0)
        let publishSemaphore = DispatchSemaphore(value: 0)

        /**************************************
         * 1. Initialize Device Sdk library
         **************************************/
        // The IoT Device SDK must be initialized before it is used.
        IotDeviceSdk.initialize();
        try Logger.initialize(target: .standardOutput, level: .debug)
        
        do {
            /**************************************
             * 2. Create Mqtt5ClientBuilder 
             **************************************/
            // Create an Mqtt5ClientBuilder configured to connect using a certificate and private key.
            let clientBuilder = try Mqtt5ClientBuilder.mtlsFromPath(certPath: self.cert, keyPath: self.key, endpoint: self.endpoint)

            /**************************************
             * 3. Setup Callbacks and other options
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

            // The onPublishReceived callback will handle all publish packets the Mqtt5 Client receives.
            func onPublishReceived(publishData: PublishReceivedData) async -> Void {
                if let payloadString = publishData.publishPacket.payloadAsString() {
                    print("Publish packet received with payload: \(payloadString)")
                }
                publishSemaphore.signal()
            }

            // Callbacks can be assigned all at once using `withCallbacks` on the Mqtt5ClientBuilder
            clientBuilder.withCallbacks(onLifecycleEventAttemptingConnect: onLifecycleEventAttemptingConnect,
                                        onLifecycleEventConnectionSuccess: onLifecycleEventConnectionSuccess,
                                        onLifecycleEventConnectionFailure: onLifecycleEventConnectionFailure,
                                        onLifecycleEventDisconnection: onLifecycleEventDisconnection,
                                        onLifecycleEventStopped: onLifecycleEventStopped)

            // They can also be assigned individually
            clientBuilder.withOnPublishReceived(onPublishReceived)     
            
            // Various other configuration options can be set on the Mqtt5ClientBuilder.
            clientBuilder.withClientId(clientId);
            

            /**********************************************
             * 3. Create Mqtt5 Client with Mqtt5ClientBuilder
             ***********************************************/
            let client = try clientBuilder.build()
            
            
            /**************************************
             * 4. Start the connection session
             **************************************/
            // `start()` will put the Mqtt5 Client in a state that desires to be connected. A connection attempt will be made.
            // If an attempt fails, the client will continue to attempt connections until it is instructed to `stop()`.
            try client.start()

            // Wait for a successful connection before proceeding with the sample.
            // connectionSemaphore.wait()


            /**************************************
             * 6. Subscribe to topic
             **************************************/

            let subscribePacket: SubscribePacket = SubscribePacket(topicFilter: topic, qos: QoS.atLeastOnce)
            // `subscribe()` is an async function that returns a `SubackPacket``. We use a Task block here for the purpose of
            // blocking while awaiting the `SubackPacket`` and triggering the DispatchSemaphore. In production you would use
            // the `subscribe()` func asyncronously.
            Task { 
                do {
                    let subackPacket: SubackPacket = try await client.subscribe(subscribePacket: subscribePacket)
                    print("SubackPacket received with result \(subackPacket.reasonCodes[0])")
                } catch {
                    print("Error while subscribing")
                }
                subscribeSemaphore.signal()
            }
            
            subscribeSemaphore.wait()

            /**************************************
            * 7. Publish to topic
            **************************************/

            let publishPacket: PublishPacket = PublishPacket(
                qos: QoS.atLeastOnce, 
                topic: topic, payload: 
                payloadMessage.data(using: .utf8))
            
            // `publish()` is an async function that returns a `PublishResult``. We use a Task block here for the purpose of
            // blocking while awaiting the `PublishResult`. The related DispatchSemaphore is signalled in the `onPublishReceived`
            // callback function. In production you would use the `publish()` func asyncronously.
            Task {
                do {
                    let publishResult: PublishResult = try await client.publish(publishPacket: publishPacket)
                    if let puback = publishResult.puback {
                        print("PubackPacket received with result \(puback.reasonCode)")
                    } else {
                        print("PublishResult missing.")
                    }
                } catch {
                    print ("Error while publishing")
                }
            }

            // This DispatchSemaphore is waiting for the Mqtt5 client to receive the publish on the topic it has subscribed
            // and then pushlished to.
            publishSemaphore.wait()
            
            /**************************************
             * 8. Stop the connection session
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