// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsIotDeviceSdkSwift
import ArgumentParser

// This sample shows how to create an MQTT5 client and connect using a PKCS12 file.
// Here are the steps to setup a client and connect.
// 0. Parsing command line arguments
// 1. Init library
// 2. Setup Connect Options & callbacks
// 3. Create Mqtt Client with MqttClientBuilder
// 4. Start the connection session
// 5. Stop the connection session

/**************************************
 * 0. Parsing command line arguments
 * Setup commandline arguments
 **************************************/
@main
struct PKCS12Sample: ParsableCommand {
    @Argument(help: "The endpoint to connect to.")
    var endpoint: String

    @Argument(help: "Path to the pkcs12 file.")
    var pkcs12Path: String

    @Argument(help: "Password for the pkcs12 file.")
    var pkcs12Password: String
    
    @Option(help: "Client id to use (optional). Please make sure the client id matches the policy.")
    var clientId: String? = "test-" + UUID().uuidString
    
    // The main function to run
    mutating func run() throws {
        /**************************************
         * 1. Init library
         **************************************/
        IoTDeviceSdk.initialize();
        // Uncomment the following line to init debug log to help with debugging.
        try? Logger.initialize(target: .standardOutput, level: .debug)
        
        do {
            /**************************************
             * 2. Setup Callbacks
             **************************************/
             // Prepare client callbacks
            func onLifecycleEventStopped(_: LifecycleStoppedData) async -> Void {
                print("Mqtt5Client: onLifecycleEventStopped callback invoked.")
            }
            func onLifecycleEventAttemptingConnect(_: LifecycleAttemptingConnectData) async -> Void {
                print("Mqtt5Client: onLifecycleEventAttemptingConnect callback invoked.")
            }
            func onLifecycleEventConnectionSuccess(_ : LifecycleConnectionSuccessData) async -> Void {
                print("Mqtt5Client: onLifecycleEventConnectionSuccess callback invoked.")
            }
            func onLifecycleEventConnectionFailure(failureData: LifecycleConnectionFailureData) async -> Void {
                print("Mqtt5Client: onLifecycleEventConnectionFailure callback invoked with Error Code \(failureData.crtError.code): \(failureData.crtError.message)")
            }
            func onLifecycleEventDisconnection(disconnectionData: LifecycleDisconnectData) async -> Void {
                print("Mqtt5Client: onLifecycleEventDisconnection callback invoked with Error Code \(disconnectionData.crtError.code): \(disconnectionData.crtError.message)")
            }
            // Setup the test context which handles the callbacks, the callback is using DispatchSemaphore for demo purpose.
            // You probably do not want to wait on DispatchSemaphore for a final product.
            let mqtt5ClientCallbacks: Mqtt5ClientCallbacks = Mqtt5ClientCallbacks()
                    
            // Create a client builder to help setup the mqtt client
            let clientBuilder = try Mqtt5ClientBuilder.MTLSFromPKCS12(pkcs12Path: pkcs12Path, pkcs12Password: pkcs12Password, endpoint: endpoint)

            // Setup callbacks
            clientBuilder.withCallbacks(onLifecycleEventAttemptingConnect: onLifecycleEventAttemptingConnect,
                                        onLifecycleEventConnectionSuccess: onLifecycleEventConnectionSuccess,
                                        onLifecycleEventConnectionFailure: onLifecycleEventConnectionFailure,
                                        onLifecycleEventDisconnection: onLifecycleEventDisconnection,
                                        onLifecycleEventStopped: onLifecycleEventStopped)
            
            // setup client id if client id is passed as argument
            if let _clientId = self.clientId {
                clientBuilder.withClientId(_clientId);
            }
            

            /**********************************************
             * 3. Create Mqtt Client with Mqtt5ClientBuilder
             ***********************************************/
            let client = try clientBuilder.build()
            
            
            /**************************************
             * 4. Start the connection session
             **************************************/
            try client.start()

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                print("This runs after a 2-second delay.")
            }
            
            /**************************************
             * 5. Stop the connection session
             **************************************/
            try client.stop()
            
            
        } catch {
            print("Failed to setup client.")
        }
        
    }
}
