// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

// ArgumentParser is used by the sample to parse arguments.
// This is not a required import for the MQTT5 Client.
import ArgumentParser
import AwsIotDeviceSdkSwift
import Foundation
import IotShadowClient

@main
struct Mqtt5Sample: AsyncParsableCommand {

    /**************************************
    * Arguments used by ArgumentParser
    **************************************/
    @Argument(help: "The endpoint to connect to.")
    var endpoint: String

    @Argument(help: "The path to the certificate file.")
    var cert: String

    @Argument(help: "The path to the private key file.")
    var key: String

    @Argument(help: "AWS IoT thing name.")
    var thingName: String

    @Argument(
        help: "Client id to use (optional). Please make sure the client id matches the policy.")
    var clientId: String = "test-" + UUID().uuidString

    /// Displays available Commands
    func showMenu() {
        print(
            """

            Commands:
            get - Gets the current full state of the classic (unamed) shadow.
            delete - Deletes the classic (unnamed) shadow completely.
            update-desired <desired-state-json-document> - Applies an update to the classic shadow's desired state component.
                Properties in the JSON document set to non-null will be set to new values. Properties in the JSON document set
                to null will be removed.
            update-reported <reported-state-json-document> - Applies an update to the classic shadow's reporeted state component.
                Properties in the JSON docuemnt set to non-null will be set to new values. Properties in the JSON document set
                to null will be removed.
            help - Prints the set of supported commands.
            quit - Quits the sample application.

            """)
    }

    mutating func run() async throws {
        // The IoT Device SDK must be initialized before it is used.
        IotDeviceSdk.initialize()

        do {
            // Create an Mqtt5ClientBuilder configured to connect using a certificate and private key.
            let clientBuilder = try Mqtt5ClientBuilder.mtlsFromPath(
                certPath: self.cert, keyPath: self.key, endpoint: self.endpoint)

            // Various other configuration options can be set on the Mqtt5ClientBuilder.
            clientBuilder.withClientId(clientId)

            // Use the builder to create an Mqtt5 Client and connect it.
            let client = try await buildAndConnect(from: clientBuilder)

            // Setup options for the MqttRequestResponseClient
            let options: MqttRequestResponseClientOptions = MqttRequestResponseClientOptions(
                operationTimeout: 5)

            // Create an IotShadowClient using the Mqtt5 Client and MqttRequestResponseClientOptions
            let shadowClient = try IotShadowClient(mqttClient: client, options: options)

            startStreamingOperations(shadowClient: shadowClient)

            // Display commands.
            showMenu()

            // Enter the interactive loop.
            await interactiveLoop(client: client, shadowClient: shadowClient)

        } catch {
            print("Failed to setup client with error: \(error).")
        }
    }

    /// Builds an `Mqtt5Client`, starts it, and suspends until the connection
    /// either succeeds or fails.
    ///
    /// - Returns: The connected `Mqtt5Client` instance.
    /// - Throws:  `CRTError` from a connection failure or any synchronous error thrown by `build()` / `start()`.
    func buildAndConnect(
        from builder: Mqtt5ClientBuilder
    ) async throws -> Mqtt5Client {

        try await withCheckedThrowingContinuation { cont in
            // We'll need this variable inside the callbacks to hand the client back
            var client: Mqtt5Client?

            // Setup callbacks that resume the continuation.
            builder.withCallbacks(
                onLifecycleEventAttemptingConnect: { @Sendable _ in
                    print("Mqtt5Client: Attempting Connection.")
                },
                onLifecycleEventConnectionSuccess: { @Sendable _ in
                    print("Mqtt5Client: Connection Successful.")
                    guard let client = client else { return }  // should always be set
                    cont.resume(returning: client)
                },
                onLifecycleEventConnectionFailure: { @Sendable data in
                    print(
                        "Mqtt5Client: Connection Failed with error \(data.crtError.code): \(data.crtError.message)"
                    )
                    cont.resume(throwing: CommonRunTimeError.crtError(data.crtError))
                })

            // Build the client *after* the callbacks are attached.
            do {
                // Build the Mqtt5Client using the builder.
                client = try builder.build()

                guard let client = client else { return }
                // Attempt to connect the Mqtt5 Client
                try client.start()
            } catch {
                // build() or start() failed.
                cont.resume(throwing: error)
            }
        }
    }

    func startStreamingOperations(shadowClient: IotShadowClient) {
        do {
            // Start a shadow delta updated stream
            let shadowDeltaUpdatedSubscriptionRequest = ShadowDeltaUpdatedSubscriptionRequest(
                thingName: thingName)
            let clientStreamOptions = ClientStreamOptions<ShadowDeltaUpdatedEvent>(
                streamEventHandler: { event in
                    print("streamEvent: \(event)")
                },
                subscriptionEventHandler: { event in
                    print("ShadowDeltaUpdatedSubscriptionRequest Subscription event")
                },
                deserializationFailureHandler: { _ in
                    print("Deserialization Failure")
                }
            )
            let deltaUpdatedOperation = try shadowClient.createShadowDeltaUpdatedStream(
                request: shadowDeltaUpdatedSubscriptionRequest,
                options: clientStreamOptions)

            // Start a named shadow updated stream
            let shadowUpdatedSubscriptionRequest = ShadowUpdatedSubscriptionRequest(
                thingName: thingName)
            let clientStreamOptions2 = ClientStreamOptions<ShadowUpdatedEvent>(
                streamEventHandler: { event in
                    print("streamEvent \(event)")
                },
                subscriptionEventHandler: { event in
                    print("ShadowUpdatedSubscriptionRequest Subscription event")
                },
                deserializationFailureHandler: { _ in
                    print("Deserialization Failure")
                }
            )
            let updatedOperation = try shadowClient.createShadowUpdatedStream(
                request: shadowUpdatedSubscriptionRequest,
                options: clientStreamOptions2)

            // open the streams
            print("Opening Streams")
            try deltaUpdatedOperation.open()
            try updatedOperation.open()
        } catch {
            print("Error while attempting to setup Shadow Client streams \(error)")
        }
    }

    // Helper function that parses command line input
    func asyncReadLine(prompt: String? = nil) async -> String? {
        if let prompt = prompt {
            print(prompt, terminator: "")
        }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let input = readLine()
                continuation.resume(returning: input)
            }
        }
    }

    public func logShadowClientError(_ error: Error) {
        // Step 1 ─ try to down‑cast to your umbrella error
        guard let err = error as? IotShadowClientError else {
            print("Unrecognised error: \(error)")
            return
        }

        // Step 2 ─ switch on the typed error
        switch err {

        case .crt(let crt):
            print(
                """
                ─── CRT error ─────────────────────────────────────────────────────────
                code:    \(crt.code)
                name:    \(crt.name)
                message: \(crt.message)
                ───────────────────────────────────────────────────────────────────────
                """)

        case .errorResponse(let errorResponse):
            print(
                """
                ─── Service rejected request ────────────────────────────
                clientToken: \(errorResponse.clientToken ?? "<nil>")
                code:        \(errorResponse.code)
                message:     \(errorResponse.message ?? "<nil>")
                timestamp:   \(errorResponse.timestamp?.formatted(.iso8601) ?? "<nil>")
                ───────────────────────────────────────────────────────────
                """)

        case .underlying(let swiftErr):
            print(
                """
                ─── Underlying Swift Error ────────────────────────────────────────────
                \(swiftErr)
                ───────────────────────────────────────────────────────────────────────
                """)
        }
    }

    // Main loop that runs while the sample is active
    func interactiveLoop(client: Mqtt5Client, shadowClient: IotShadowClient) async {
        var shouldExit = false
        while !shouldExit {
            if let input = await asyncReadLine(prompt: "Enter command:\n") {
                let lowercasedInput = input.lowercased()
                switch lowercasedInput {
                case "help":
                    showMenu()

                case "exit":
                    print("Exiting MQTT5 Sample")
                    shouldExit = true
                case "quit":
                    print("Exiting MQTT5 Sample")
                    shouldExit = true

                case "get":
                    let request: GetShadowRequest = GetShadowRequest(thingName: thingName)
                    do {
                        let response = try await shadowClient.getShadow(request: request)
                        print(
                            """
                            ─── Get Shadow Response ───────────────────────────────────────────────
                            state: \(response.state?.desired ?? ["<nil>":"<nil>"])
                            metadata.desired: \(response.metadata?.desired ?? ["<nil>":"<nil>"])
                            timestamp: \(response.timestamp?.formatted(.iso8601) ?? "<nil>")
                            ───────────────────────────────────────────────────────────────────────
                            """)
                    } catch {
                        logShadowClientError(error)
                    }
                case "delete":
                    print("setup delete")

                default:
                    do {
                        let tokens = input.split(separator: " ")
                        guard tokens.count > 1 else {
                            print("Invalid shadow command")
                            break
                        }
                        let secondWord = String(tokens[1])

                        if lowercasedInput.hasPrefix("update-desired") {
                        } else if lowercasedInput.hasPrefix("update-reported") {
                        } else if lowercasedInput.hasPrefix("get") {
                            switch secondWord {
                            case "shadow":
                                print(
                                    """
                                    \n
                                    ==== Getting \(thingName) state ====
                                    \n
                                    """)
                                let request: GetShadowRequest = GetShadowRequest(
                                    thingName: thingName)
                                let response = try await shadowClient.getShadow(request: request)
                                print(
                                    """
                                    ─── Get Shadow Response ───────────────────────────────────────────────
                                    state: \(response.state?.desired ?? ["<nil>":"<nil>"])
                                    metadata.desired: \(response.metadata?.desired ?? ["<nil>":"<nil>"])
                                    timestamp: \(response.timestamp?.formatted(.iso8601) ?? "<nil>")
                                    ───────────────────────────────────────────────────────────────────────
                                    """)
                            case "named":
                                guard tokens.count > 3 else {
                                    print("Invalid shadow command")
                                    break
                                }
                                print(
                                    """
                                    \n
                                    ==== Getting \(thingName):\(tokens[3]) state ====
                                    \n
                                    """)
                                let request: GetNamedShadowRequest = GetNamedShadowRequest(
                                    thingName: thingName,
                                    shadowName: String(tokens[3]))
                                let response = try await shadowClient.getNamedShadow(
                                    request: request)
                                print(
                                    """
                                    ─── Get Named Shadow Response ─────────────────────────────────────────
                                    state: \(response.state?.desired ?? ["<nil>":"<nil>"])
                                    metadata.desired: \(response.metadata?.desired ?? ["<nil>":"<nil>"])
                                    timestamp: \(response.timestamp?.formatted(.iso8601) ?? "<nil>")
                                    ───────────────────────────────────────────────────────────────────────
                                    """)
                            default:
                                print("Unknown Command")
                            }
                        } else if lowercasedInput.hasPrefix("update") {
                            switch secondWord {
                            case "shadow":
                                guard tokens.count > 2 else {
                                    print("Invalid shadow command")
                                    break
                                }
                                print(
                                    """
                                    \n
                                    ==== Updating \(thingName) state to \(tokens[2]) ====
                                    \n
                                    """)
                                let request: UpdateShadowRequest = UpdateShadowRequest(
                                    thingName: thingName,
                                    state: ShadowState(desired: [
                                        "Color": String(tokens[2])
                                    ]))
                                let response = try await shadowClient.updateShadow(request: request)
                                print(
                                    """
                                    ─── Update Shadow Response ────────────────────────────────────────────
                                    state: \(response.state?.desired ?? ["<nil>":"<nil>"])
                                    metadata.desired: \(response.metadata?.desired ?? ["<nil>":"<nil>"])
                                    timestamp: \(response.timestamp?.formatted(.iso8601) ?? "<nil>")
                                    ───────────────────────────────────────────────────────────────────────
                                    """)
                            case "named":
                                guard tokens.count > 4 else {
                                    print("Invalid shadow command")
                                    break
                                }
                                print(
                                    """
                                    \n
                                    ==== Updating \(thingName):\(tokens[3]) state to \(tokens[4]) ====
                                    \n
                                    """)
                                let request: UpdateNamedShadowRequest = UpdateNamedShadowRequest(
                                    thingName: thingName,
                                    shadowName: String(tokens[3]),
                                    state: ShadowState(desired: ["Color": String(tokens[4])]))
                                let response = try await shadowClient.updateNamedShadow(
                                    request: request)
                                print(
                                    """
                                    ─── Update Named Shadow Response ──────────────────────────────────────
                                    state: \(response.state?.desired ?? ["<nil>":"<nil>"])
                                    metadata.desired: \(response.metadata?.desired ?? ["<nil>":"<nil>"])
                                    timestamp: \(response.timestamp?.formatted(.iso8601) ?? "<nil>")
                                    ───────────────────────────────────────────────────────────────────────
                                    """)
                            default:
                                print("Unknown Command")
                            }
                        } else if lowercasedInput.hasPrefix("delete") {
                            switch secondWord {
                            case "shadow":
                                print(
                                    """
                                    \n
                                    ==== Deleting \(thingName)) ====
                                    \n
                                    """)
                                let request: DeleteShadowRequest = DeleteShadowRequest(
                                    thingName: thingName)
                                let response = try await shadowClient.deleteShadow(request: request)
                                print(
                                    """
                                    ─── Delete Shadow Response ────────────────────────────────────────────
                                    timestamp: \(response.timestamp?.formatted(.iso8601) ?? "<nil>")
                                    version: \(response.version ?? 0)
                                    ───────────────────────────────────────────────────────────────────────
                                    """)
                            case "named":
                                guard tokens.count > 3 else {
                                    print("Invalid shadow command")
                                    break
                                }
                                print(
                                    """
                                    \n
                                    ==== Deleting \(thingName):\(tokens[3]) ====
                                    \n
                                    """)
                                let request: DeleteNamedShadowRequest = DeleteNamedShadowRequest(
                                    thingName: thingName,
                                    shadowName: String(tokens[3]))
                                let response = try await shadowClient.deleteNamedShadow(
                                    request: request)

                                print(
                                    """
                                    ─── Delete Named Shadow Response ──────────────────────────────────────
                                        clientToken: \(response.clientToken ?? "<nil>")                    
                                        timestamp: \(response.timestamp?.formatted(.iso8601) ?? "<nil>")
                                        version: \(response.version ?? 0)
                                    ───────────────────────────────────────────────────────────────────────
                                    """)
                            default:
                                print("Unknown Command")
                            }
                        } else {
                            print("Unknown command: \(input)")
                            showMenu()
                        }
                    } catch {
                        logShadowClientError(error)
                    }
                }
            }
        }
    }
}
