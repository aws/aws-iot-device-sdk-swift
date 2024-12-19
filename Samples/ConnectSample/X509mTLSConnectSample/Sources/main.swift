// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsIotDeviceSdkSwift
import ArgumentParser

// This sample shows how to create a mTLS MQTT connection session using the X509 certificate file and key file.
// Here is the steps to setup a client and connection
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
struct X509MTLSConnectSample: ParsableCommand {
    @Argument(help: "The endpoint to connect to.")
    var endpoint: String
    
    @Argument(help: "The path to the certificate file.")
    var cert: String
    
    @Argument(help: "The path to the private key file.")
    var key: String
    
    @Option(help: "The path to the override root CA file (optional).")
    var ca_file: String? = nil
    
    @Option(help: "Client id to use (optional)")
    var client_id: String? = "test-" + UUID().uuidString
    
    // The main function to run
    mutating func run() throws {
        /**************************************
         * 1. Init library
         **************************************/
        CommonRuntimeKit.initialize();
        // Uncomment the following line to init debug log to help with debugging.
        try? Logger.initialize(target: .standardOutput, level: .debug)
        
        do {
            /**************************************
             * 2. Setup Connect Options & callbacks
             **************************************/
            // Create and config a client builder to access credentials from file path parsed from command line
            let sample_context = X509MTLSConnectContext()
            let clientBuilder = try Mqtt5ClientBuilder.mtlsFromPath(certPath: self.cert, keyPath: self.key, endpoint: self.endpoint)
            
            // Setup callbacks and other client options
            clientBuilder.withCallbacks(onLifecycleEventAttemptingConnect: sample_context.onLifecycleEventAttemptingConnect,
                                        onLifecycleEventConnectionSuccess: sample_context.onLifecycleEventConnectionSuccess,
                                        onLifecycleEventConnectionFailure: sample_context.onLifecycleEventConnectionFailure,
                                        onLifecycleEventDisconnection: sample_context.onLifecycleEventDisconnection,
                                        onLifecycleEventStopped: sample_context.onLifecycleEventStopped)
            
            // setup client id if client id is passed as argument
            if let _client_id = self.client_id {
                clientBuilder.withClientId(_client_id);
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
struct X509MTLSConnectContext{    
    // We wait on semaphore to demonstrate the client features. However, you probably do not want to block the application in a real product.
    var semaphoreConnectionSuccess: DispatchSemaphore
    var semaphoreConnectionFailure: DispatchSemaphore
    var semaphoreDisconnection: DispatchSemaphore
    var semaphoreStopped: DispatchSemaphore
    
    // Prepare client callbacks
    func onLifecycleEventStopped(_: LifecycleStoppedData) async -> Void
    {
        print("Mqtt5ClientTests: onLifecycleEventStopped")
        semaphoreStopped.signal()
    }
    
    func onLifecycleEventAttemptingConnect(_: LifecycleAttemptingConnectData) async -> Void {
        print("Mqtt5ClientTests: onLifecycleEventAttemptingConnect")
    }
    func onLifecycleEventConnectionSuccess(_ : LifecycleConnectionSuccessData) async -> Void
    {
        print("Mqtt5ClientTests: onLifecycleEventConnectionSuccess")
        semaphoreConnectionSuccess.signal()
    }
    func onLifecycleEventConnectionFailure(failureData: LifecycleConnectionFailureData) async -> Void
    {
        print("Mqtt5ClientTests: onLifecycleEventConnectionFailure: Error Code \(failureData.crtError.code): \(failureData.crtError.message)")
        semaphoreConnectionFailure.signal()
    }
    func onLifecycleEventDisconnection(disconnectionData: LifecycleDisconnectData) async -> Void
    {
        print("Mqtt5ClientTests: onLifecycleEventDisconnection:  Error Code \(disconnectionData.crtError.code): \(disconnectionData.crtError.message)")
        semaphoreDisconnection.signal()
    }
    
    init() {
        semaphoreConnectionSuccess = DispatchSemaphore(value: 0)
        semaphoreConnectionFailure  = DispatchSemaphore(value: 0)
        semaphoreDisconnection = DispatchSemaphore(value: 0)
        semaphoreStopped = DispatchSemaphore(value: 0)
    }
}
