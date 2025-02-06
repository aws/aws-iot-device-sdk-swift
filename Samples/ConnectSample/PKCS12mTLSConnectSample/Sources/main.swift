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
        CommonRuntimeKit.initialize();
        // Uncomment the following line to init debug log to help with debugging.
        // try? Logger.initialize(target: .standardOutput, level: .debug)
        
        do {
            /**************************************
             * 2. Setup Connect Options & callbacks
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
            clientBuilder.withCallbacks(onLifecycleEventAttemptingConnect: mqtt5ClientCallbacks.onLifecycleEventAttemptingConnect,
                                        onLifecycleEventConnectionSuccess: mqtt5ClientCallbacks.onLifecycleEventConnectionSuccess,
                                        onLifecycleEventConnectionFailure: mqtt5ClientCallbacks.onLifecycleEventConnectionFailure,
                                        onLifecycleEventDisconnection: mqtt5ClientCallbacks.onLifecycleEventDisconnection,
                                        onLifecycleEventStopped: mqtt5ClientCallbacks.onLifecycleEventStopped)
            
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
            if sample_context.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
                print("Client start failed to connect after 5 seconds")
            }
            
            /**************************************
             * 5. Stop the connection session
             **************************************/
            try client.stop()
            if sample_context.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
                print("Client stop failed after 5 seconds")
            }
            
            
        } catch {
            print("Failed to setup client.")
        }
        
    }
}


    /**************************************
     * Setup client callbacks
     **************************************/
struct Mqtt5ClientCallbacks {    
    // We wait on semaphore to demonstrate the client features. However, you probably do not want to block the application in a real product.
    var semaphoreConnectionSuccess: DispatchSemaphore
    var semaphoreConnectionFailure: DispatchSemaphore
    var semaphoreDisconnection: DispatchSemaphore
    var semaphoreStopped: DispatchSemaphore
    
    // Prepare client callbacks
    func onLifecycleEventStopped(_: LifecycleStoppedData) async -> Void
    {
        print("Mqtt5Client: onLifecycleEventStopped callback invoked.")
        semaphoreStopped.signal()
    }
    
    func onLifecycleEventAttemptingConnect(_: LifecycleAttemptingConnectData) async -> Void {
        print("Mqtt5Client: onLifecycleEventAttemptingConnect callback invoked.")
    }
    func onLifecycleEventConnectionSuccess(_ : LifecycleConnectionSuccessData) async -> Void
    {
        print("Mqtt5Client: onLifecycleEventConnectionSuccess callback invoked.")
        semaphoreConnectionSuccess.signal()
    }
    func onLifecycleEventConnectionFailure(failureData: LifecycleConnectionFailureData) async -> Void
    {
        print("Mqtt5Client: onLifecycleEventConnectionFailure callback invoked with Error Code \(failureData.crtError.code): \(failureData.crtError.message)")
        semaphoreConnectionFailure.signal()
    }
    func onLifecycleEventDisconnection(disconnectionData: LifecycleDisconnectData) async -> Void
    {
        print("Mqtt5Client: onLifecycleEventDisconnection callback invoked with Error Code \(disconnectionData.crtError.code): \(disconnectionData.crtError.message)")
        semaphoreDisconnection.signal()
    }
    
    init() {
        semaphoreConnectionSuccess = DispatchSemaphore(value: 0)
        semaphoreConnectionFailure  = DispatchSemaphore(value: 0)
        semaphoreDisconnection = DispatchSemaphore(value: 0)
        semaphoreStopped = DispatchSemaphore(value: 0)
    }
}
