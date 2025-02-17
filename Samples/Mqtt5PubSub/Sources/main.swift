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
        // In this sample, we use boolean flags to wait for specific events.
        // In a production environment, you should use the MQTT5 Client's asynchronous APIs
        // instead of relying on blocking mechanisms.
        var isConnected = false
        var isStopped = false;
        let subscribedSemaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        let publishedSempahore: DispatchSemaphore = DispatchSemaphore(value: 0)

        /**************************************
         * 1. Initialize Device Sdk library
         **************************************/
        // The IoT Device SDK must be initialized before it is used.
        IotDeviceSdk.initialize();
        
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
                isStopped = true
            }
            func onLifecycleEventAttemptingConnect(_: LifecycleAttemptingConnectData) async -> Void {
                print("Mqtt5Client: onLifecycleEventAttemptingConnect callback invoked.")
            }
            func onLifecycleEventConnectionSuccess(_ : LifecycleConnectionSuccessData) async -> Void {
                print("Mqtt5Client: onLifecycleEventConnectionSuccess callback invoked.")
                isConnected = true
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
                publishedSempahore.signal()
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
            
            while (!isConnected) {
                // Awaiting onLifecycleEventConnectionSuccess callback.
            }


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
                subscribedSemaphore.signal()
            }
            
            subscribedSemaphore.wait()

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

            publishedSempahore.wait()
            
            /**************************************
             * 8. Stop the connection session
             **************************************/
            // `stop()` will put the Mqtt5 Client in a state that desires to be disconnected. If in a connected state, the client
            // will disconnect and not attempt to connect until it is instructed to `start()`.
            try client.stop()

            while (!isStopped) {
                // Awaiting onLifecycleEventStopped callback.
            }

            print("Sample complete.")
        } catch {
            print("Failed to setup client.")
        }
    }
}