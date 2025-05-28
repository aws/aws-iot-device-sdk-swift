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

            Usage:
            get -- gets the thing's current shadow document
            delete -- deletes the thing's shadow document
            update-desired <Desired state JSON> -- updates the desired component of the thing's shadow document
            update-reported <Reported state JSON> -- updates the reported component of the thing's shadow document
            quit -- exit the application

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

            let (deltaUpdatedOperation, updatedOperation) = try startStreamingOperations(
                shadowClient: shadowClient)

            try deltaUpdatedOperation.open()
            try updatedOperation.open()

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
            let state = ClientState()

            // Setup callbacks that resume the continuation.
            builder.withCallbacks(
                onLifecycleEventAttemptingConnect: { @Sendable _ in
                    print("Mqtt5Client: Attempting Connection.")
                },
                onLifecycleEventConnectionSuccess: { @Sendable _ in
                    print("Mqtt5Client: Connection Successful.")
                    guard let client = state.client else { return }
                    state.tryResumeOnce {
                        cont.resume(returning: client)
                    }
                },
                onLifecycleEventConnectionFailure: { @Sendable data in
                    print(
                        "Mqtt5Client: Connection Failed with error \(data.crtError.code): \(data.crtError.message)"
                    )
                })

            // Build the client *after* the callbacks are attached.
            do {
                // Build the Mqtt5Client using the builder.
                let client = try builder.build()
                state.client = client
                try client.start()
            } catch {
                state.tryResumeOnce {
                    // build() or start() failed.
                    cont.resume(throwing: error)
                }
            }
        }
    }

    func startStreamingOperations(shadowClient: IotShadowClient) throws -> (
        StreamingOperation, StreamingOperation
    ) {
        do {
            // Start a shadow delta updated stream
            let shadowDeltaUpdatedSubscriptionRequest = ShadowDeltaUpdatedSubscriptionRequest(
                thingName: thingName)
            let clientStreamOptions = ClientStreamOptions<ShadowDeltaUpdatedEvent>(
                streamEventHandler: { event in
                    print(
                        """

                        ─── ShadowDeltaUpdatedEvent ───────────────────────────────────────────
                        Updated State
                        state:     \(event.state ?? ["<nil>":"<nil>"])                        

                        """)
                },
                subscriptionEventHandler: { _ in
                },
                deserializationFailureHandler: { _ in
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
                    var output =
                        "\n─── ShadowUpdatedEvent ────────────────────────────────────────────────\n"

                    if let currentReported = event.current?.state?.reported {
                        output += "current reported state:  \(currentReported)\n"
                    }

                    if let prevReported = event.previous?.state?.reported {
                        output += "previous reported state: \(prevReported)\n"
                    }

                    if let currentDesired = event.current?.state?.desired {
                        output += "current desired state:   \(currentDesired)\n"
                    }

                    if let prevDesired = event.previous?.state?.desired {
                        output += "previous desired state:  \(prevDesired)\n"
                    }
                    print(output)
                },
                subscriptionEventHandler: { _ in
                },
                deserializationFailureHandler: { _ in
                }
            )
            let updatedOperation = try shadowClient.createShadowUpdatedStream(
                request: shadowUpdatedSubscriptionRequest,
                options: clientStreamOptions2)

            return (deltaUpdatedOperation, updatedOperation)
        } catch {
            print("Error while attempting to setup Shadow Client streams \(error)")
            throw error
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

                """)

        case .errorResponse(let errorResponse):
            print(
                """

                ─── Service Request Rejected ────────────────────────────
                code:        \(errorResponse.code)
                message:     \(errorResponse.message ?? "<nil>")

                """)

        case .underlying(let swiftErr):
            print(
                """

                ─── Underlying Swift Error ────────────────────────────────────────────
                \(swiftErr)

                """)
        }
    }

    func parseJSONStringToDictionary(_ json: String) -> [String: Any]? {
        guard let data = json.data(using: .utf8) else {
            print("Failed to encode string to Data")
            return nil
        }

        do {
            let dictionary =
                try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            return dictionary
        } catch {
            print(
                """
                Failed to parse provided JSON string into Shadow State
                Example of properly formatted JSON Shadow State: {"Status":"Great"}

                """)
            return nil
        }
    }

    // Main loop that runs while the sample is active
    func interactiveLoop(client: Mqtt5Client, shadowClient: IotShadowClient) async {
        var shouldExit = false
        while !shouldExit {
            try? await Task.sleep(nanoseconds: 500_000_000)

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
                            "\n─── GetShadowResponse ─────────────────────────────────────────────────"
                        )
                        if let state = response.state {
                            if let reported = state.reported {
                                print("reported state: \(reported)")
                            }
                            if let desired = state.desired {
                                print("desired state:  \(desired)")
                            }
                        }
                        print(" ")
                    } catch {
                        logShadowClientError(error)
                    }

                case "delete":
                    let request: DeleteShadowRequest = DeleteShadowRequest(
                        thingName: thingName)
                    do {
                        let response = try await shadowClient.deleteShadow(request: request)
                        print(
                            """

                            ─── DeleteShadowResponse ──────────────────────────────────────────────
                            timestamp: \(response.timestamp?.formatted(.iso8601) ?? "<nil>")
                            version:   \(response.version ?? 0)

                            """)
                    } catch {
                        logShadowClientError(error)
                    }

                default:
                    do {
                        let tokens = input.split(separator: " ")
                        guard tokens.count > 1 else {
                            print("Invalid shadow command")
                            showMenu()
                            break
                        }

                        if lowercasedInput.hasPrefix("update-desired") {
                            let inputJSON = tokens.dropFirst().joined(separator: " ")
                            if let desiredDict = parseJSONStringToDictionary(inputJSON) {
                                let desiredState = ShadowState(desired: desiredDict)
                                let request = UpdateShadowRequest(
                                    thingName: thingName, state: desiredState)
                                let response = try await shadowClient.updateShadow(request: request)
                                print(
                                    """

                                    ─── UpdateShadowResponse ────────────────────────────────────────────
                                    desired state:  \(response.state?.desired ?? ["<nil>":"<nil>"])

                                    """)
                            }
                        } else if lowercasedInput.hasPrefix("update-reported") {
                            let inputJSON = tokens.dropFirst().joined(separator: " ")
                            if let reportedDict = parseJSONStringToDictionary(inputJSON) {
                                let reportedState = ShadowState(reported: reportedDict)
                                let request: UpdateShadowRequest = UpdateShadowRequest(
                                    thingName: thingName, state: reportedState)
                                let response = try await shadowClient.updateShadow(request: request)
                                print(
                                    """

                                    ─── UpdateShadowResponse ────────────────────────────────────────────
                                    reported state: \(response.state?.reported ?? ["<nil>":"<nil>"])

                                    """)
                            }
                        }
                    } catch {
                        logShadowClientError(error)
                    }
                }
            }
        }
    }
}

final class ClientState {
    var client: Mqtt5Client?
    private var isResumed = false
    private let lock = NSLock()

    func tryResumeOnce(_ action: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        guard !isResumed else { return }
        isResumed = true
        action()
    }
}
