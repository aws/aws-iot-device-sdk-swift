// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

// ArgumentParser is used by the sample to parse arguments.
// This is not a required import for the MQTT5 Client.
import ArgumentParser
import AwsIotDeviceSdkSwift
import Foundation

// This sample creates an MQTT5 client and connects using a PKCS12 file.
// Here are the steps to setup a client and connect.
// 0. Sample only: Parse command line arguments
// 1. Initialize Device Sdk library
// 2. Create Mqtt5ClientBuilder
// 3. Setup Callbacks and other options
// 4. Create an Mqtt5 Client with Mqtt5ClientBuilder
// 5. Start the connection session
// 6. Stop the connection session

@main
struct SignedCustomAuthSample: ParsableCommand {
    /**************************************
    * 0. Sample only: Parse command line arguments
    **************************************/
    enum SampleError: Error {
        case clientSetupFailed
    }

    @Option(help: "Required: The endpoint to connect to.")
    var endpoint: String

    @Option(help: "Required: Name of the Custom Authorizer.")
    var authorizerName: String

    @Option(help: "Required: Value of the username field that should be passed to the authorizer's lambda.")
    var authorizerUsername: String

    @Option(help: "Required: Value of the password field to be passed to the authorizer's lambda.")
    var authorizerPassword: String

    @Option(help: "Optional: Name of the username query param that will contain the token value.")
    var tokenKeyName: String?

    @Option(
        help:
            "Optional: Value of the username query param that holds the token value that has been signed."
    )
    var tokenValue: String?

    @Option(help: "Optional: URI-encoded base64-encoded digital signature of tokenValue.")
    var tokenSignature: String?

    @Argument(
        help: "Client id to use (optional). Please make sure the client id matches the policy.")
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
        IotDeviceSdk.initialize()

        // Uncomment the following line to initialize logging to standard output.
        // try? Logger.initialize(target: .standardOutput, level: .debug)

        do {
            /**************************************
             * 2. Create Mqtt5ClientBuilder
             **************************************/
            var clientBuilder: Mqtt5ClientBuilder?

            // If a tokenKeyName, tokenValue, and tokenSignature has been provided, initialize an Mqtt5ClientBuilder configured to
            // connect using a signed custom authorizer.
            if let _tokenKeyName = tokenKeyName, let _tokenValue = tokenValue,
                let _tokenSignature = tokenSignature {
                clientBuilder = try Mqtt5ClientBuilder.directWithSignedCustomAuthorizer(
                    endpoint: endpoint,
                    authAuthorizerName: authorizerName,
                    authAuthorizerSignature: _tokenSignature,
                    authTokenKeyName: _tokenKeyName,
                    authTokenValue: _tokenValue,
                    authUsername: authorizerUsername,
                    authPassword: authorizerPassword.data(using: .utf8)!)
            }
            // If optional token arguments are not provided, initialize an Mqtt5ClientBuilder configured to connect using
            // an unsigned custom authorizer.
            else {
                clientBuilder = try Mqtt5ClientBuilder.directWithUnsignedCustomAuthorizer(
                    endpoint: endpoint,
                    authAuthorizerName: authorizerName,
                    authPassword: authorizerPassword.data(using: .utf8),
                    authUsername: authorizerUsername)
            }

            /**************************************
             * 3. Setup Callbacks and other options
             **************************************/
            // Callbacks to be assigned to builder
            // The full list of callbacks and their uses can be found in the MQTT5 User Guide
            func onLifecycleEventStopped(_: LifecycleStoppedData) async {
                print("Mqtt5Client: onLifecycleEventStopped callback invoked.")
                stoppedSemaphore.signal()
            }
            func onLifecycleEventAttemptingConnect(_: LifecycleAttemptingConnectData) async {
                print("Mqtt5Client: onLifecycleEventAttemptingConnect callback invoked.")
            }
            func onLifecycleEventConnectionSuccess(_: LifecycleConnectionSuccessData) async {
                print("Mqtt5Client: onLifecycleEventConnectionSuccess callback invoked.")
                connectionSemaphore.signal()
            }
            func onLifecycleEventConnectionFailure(failureData: LifecycleConnectionFailureData)
                async {
                print(
                    "Mqtt5Client: onLifecycleEventConnectionFailure callback invoked with Error Code \(failureData.crtError.code): \(failureData.crtError.message)"
                )
            }
            func onLifecycleEventDisconnection(disconnectionData: LifecycleDisconnectData) async {
                print(
                    "Mqtt5Client: onLifecycleEventDisconnection callback invoked with Error Code \(disconnectionData.crtError.code): \(disconnectionData.crtError.message)"
                )
            }

            // Callbacks can be assigned all at once using `withCallbacks` on the Mqtt5ClientBuilder
            clientBuilder!.withCallbacks(
                onLifecycleEventAttemptingConnect: onLifecycleEventAttemptingConnect,
                onLifecycleEventConnectionSuccess: onLifecycleEventConnectionSuccess,
                onLifecycleEventConnectionFailure: onLifecycleEventConnectionFailure,
                onLifecycleEventDisconnection: onLifecycleEventDisconnection,
                onLifecycleEventStopped: onLifecycleEventStopped)

            // They can also be assigned individually
            clientBuilder!.withOnLifecycleEventConnectionSuccess(onLifecycleEventConnectionSuccess)

            // Various other configuration options can be set on the Mqtt5ClientBuilder.
            clientBuilder!.withClientId(clientId)

            /**********************************************
             * 4. Create an Mqtt5 Client with Mqtt5ClientBuilder
             ***********************************************/
            let client = try clientBuilder!.build()

            /**************************************
             * 5. Start the connection session
             **************************************/
            // `start()` will put the Mqtt5 Client in a state that desires to be connected. A connection attempt will be made.
            // If an attempt fails, the client will continue to attempt connections until it is instructed to `stop()`.
            try client.start()

            // Wait for a successful connection before proceeding with the sample.
            connectionSemaphore.wait()

            /**************************************
             * 6. Stop the connection session
             **************************************/
            // `stop()` will put the Mqtt5 Client in a state that desires to be disconnected. If in a connected state, the client
            // will disconnect and not attempt to connect until it is instructed to `start()`.
            try client.stop()

            // Wait for the client to be stopped before exiting the sample.
            stoppedSemaphore.wait()

            print("Sample complete.")
        } catch {
            print("Failed to setup client.")
            throw SampleError.clientSetupFailed
        }
    }
}
