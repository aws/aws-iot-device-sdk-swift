// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import AWSIoT
// ArgumentParser is used by the sample to parse arguments.
// This is not a required import for the MQTT5 Client.
import ArgumentParser
import AwsIotDeviceSdkSwift
import Foundation
import IotJobsClient

@main
struct ShadowClientSample: AsyncParsableCommand {

    /**************************************
    * Arguments used by ArgumentParser
    **************************************/
    @Argument(help: "The endpoint to connect to.")
    var endpoint: String

    @Argument(help: "The path to the certificate file.")
    var cert: String

    @Argument(help: "The path to the private key file.")
    var key: String

    @Argument(help: "AWS Region the AWS IoT endpoint is using.")
    var region: String

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
            IoT control plane commands:
                create-job <jobId> <job-document-as-json> -- create a new job with the specified job id and (JSON) document
                delete-job <jobId>                        -- deletes a job with the specified job id

            MQTT Jobs service commands:
                describe-job-execution <jobId>                                             -- gets the service status of a job execution with the specified job id
                get-pending-job-executions                                                 -- gets all incomplete job executions
                start-next-pending-job-execution                                           -- moves the next pending job execution into the IN_PROGRESS state
                update-job-execution <jobId> <SUCCEEDED | IN_PROGRESS | FAILED | CANCELED> -- updates a job execution with a new status
                
            Miscellaneous commands:
            help -- prints this message
            quit -- exit the application

            """)
    }

    // Takes an object and encodes it to JSON in a prettyPrinted format and returns a String
    func prettyPrint<T: Encodable>(_ object: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(object)
            if let json = String(data: data, encoding: .utf8) {
                return json
            }
        } catch {
            return "Failed to encode object: \(error)"
        }
        return "Failed to encode object"
    }

    mutating func run() async throws {
        // The IoT Device SDK must be initialized before it is used.
        IotDeviceSdk.initialize()

        // Tracks sample-wide states that need to be shared
        let clientState = ClientState()

        do {
            // Create an Mqtt5ClientBuilder configured to connect using a certificate and private key.
            let clientBuilder = try Mqtt5ClientBuilder.mtlsFromPath(
                certPath: self.cert, keyPath: self.key, endpoint: self.endpoint)

            // Various other configuration options can be set on the Mqtt5ClientBuilder.
            clientBuilder.withClientId(clientId)

            // Use the builder to create an Mqtt5 Client and connect it.
            let client = try await buildAndConnect(from: clientBuilder, state: clientState)
            clientState.mqttClient = client
        } catch {
            print("Failed to setup Mqtt client with error: \(error).")
            return
        }

        do {
            // Setup options for the MqttRequestResponseClient
            let options = MqttRequestResponseClientOptions(
                maxRequestResponseSubscription: 3,
                maxStreamingSubscription: 2,
                operationTimeout: 5)

            // Create an IotJobsClient using the Mqtt5 Client and MqttRequestResponseClientOptions
            let jobsClient = try IotJobsClient(
                mqttClient: clientState.mqttClient!, options: options)

            // Sets up the create job executions changed and create next job execution changed streams
            let (createJobExecutionsChangedStream, nextJobExecutionChangedStream) =
                try startStreamingOperations(
                    jobsClient: jobsClient, clientState: clientState)

            // open both streams to receive events
            try createJobExecutionsChangedStream.open()
            try nextJobExecutionChangedStream.open()

            clientState.jobsClient = jobsClient
            clientState.stream1 = createJobExecutionsChangedStream
            clientState.stream2 = nextJobExecutionChangedStream
        } catch {
            print("Failed to setup Jobs Client with error: \(error)")
            return
        }

        do {
            // IoTClient is used for control plane operations
            let iotClient = try await AWSIoT.IoTClient(
                config: IoTClient.IoTClientConfiguration(region: region))

            clientState.iotClient = iotClient
        } catch {
            print("Failed to setup IoTClient with error: \(error)")
            return
        }

        do {
            let describeThingInput = DescribeThingInput(thingName: thingName)
            let describeThingOutput = try await clientState.iotClient!.describeThing(
                input: describeThingInput)
            guard let thingArn: String = describeThingOutput.thingArn else {
                print("Failed to retrieve Arn for thingName: \(thingName)")
                return
            }
            clientState.thingArn = thingArn
        } catch {
            print(
                "Failed to retreive Arn for provided thingName: \(thingName) with error: \(error)"
            )
            return
        }

        // Display commands.
        showMenu()

        // Enter the interactive loop.
        await interactiveLoop(
            jobsClient: clientState.jobsClient!, iotClient: clientState.iotClient!,
            clientState: clientState)

    }

    /// Builds an `Mqtt5Client`, starts it, and suspends until the connection
    /// either succeeds or fails.
    ///
    /// - Returns: The connected `Mqtt5Client` instance.
    /// - Throws:  `CRTError` from a connection failure or any synchronous error thrown by `build()` / `start()`.
    func buildAndConnect(
        from builder: Mqtt5ClientBuilder, state: ClientState
    ) async throws -> Mqtt5Client {

        try await withCheckedThrowingContinuation { cont in

            // Setup callbacks that resume the continuation.
            builder.withCallbacks(
                onLifecycleEventAttemptingConnect: { @Sendable _ in
                    print("Mqtt5Client: Attempting Connection.")
                },
                onLifecycleEventConnectionSuccess: { @Sendable _ in
                    print("Mqtt5Client: Connection Successful.")
                    guard let client = state.mqttClient else { return }
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
                state.mqttClient = client
                try client.start()
            } catch {
                state.tryResumeOnce {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    func startStreamingOperations(jobsClient: IotJobsClient, clientState: ClientState) throws
        -> (StreamingOperation, StreamingOperation)
    {
        do {
            // Start a job executions changed stream
            let jobExecutionsChangedSubscriptionRequest = JobExecutionsChangedSubscriptionRequest(
                thingName: thingName)
            let jobExecutionsChangedSubscriptionRequestOptions = ClientStreamOptions<
                JobExecutionsChangedEvent
            >(
                // Handles delta update events
                streamEventHandler: { event in
                    print(
                        "\n─── JobExecutionsChangedEvent ───────────────────────────────────────────\n"
                            + prettyPrint(event) + "\n\n")
                },
                // We are not tracking subscription events in this sample
                subscriptionEventHandler: { _ in
                },
                // We are not handling deserializatiion failures ini this sample
                deserializationFailureHandler: { _ in
                }
            )
            let jobExecutionsChangedOperation = try jobsClient.createJobExecutionsChangedStream(
                request: jobExecutionsChangedSubscriptionRequest,
                options: jobExecutionsChangedSubscriptionRequestOptions)

            // Start a next job execution changed stream
            let nextJobExecutionChangedSubscriptionRequest =
                NextJobExecutionChangedSubscriptionRequest(thingName: thingName)
            let nextJobExecutionChangedEventOptions = ClientStreamOptions<
                NextJobExecutionChangedEvent
            >(
                // Handles delta update events
                streamEventHandler: { event in
                    print(
                        "\n─── NextJobExecutionChangedEvent ───────────────────────────────────────────\n"
                            + prettyPrint(event) + "\n\n")
                },
                // We are not tracking subscription events in this sample
                subscriptionEventHandler: { _ in
                },
                // We are not handling deserializatiion failures ini this sample
                deserializationFailureHandler: { _ in
                })
            let nextJobExecutionChangedOperation =
                try jobsClient.createNextJobExecutionChangedStream(
                    request: nextJobExecutionChangedSubscriptionRequest,
                    options: nextJobExecutionChangedEventOptions)

            return (jobExecutionsChangedOperation, nextJobExecutionChangedOperation)
        } catch {
            print("Error while attempting to setup Jobs Client streams \(error)")
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

    // Handle errors thrown by the shadow client
    public func logJobsClientError(_ error: Error) {
        // Step 1 ─ try to cast into expected `IotJobsClientError`
        guard let err = error as? IotJobsClientError else {
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

    // Helper function that takes user input JSON and converts it to the [String: Any] type expected for `ShadowState`
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
    func interactiveLoop(
        jobsClient: IotJobsClient, iotClient: AWSIoT.IoTClient, clientState: ClientState
    ) async {
        var shouldExit = false
        while !shouldExit {
            try? await Task.sleep(nanoseconds: 500_000_000)

            if let input = await asyncReadLine(prompt: "Enter command:\n") {
                let lowercasedInput = input.lowercased()
                switch lowercasedInput {
                case "help":
                    showMenu()

                case "exit":
                    print("Exiting Jobs Sample")
                    shouldExit = true

                case "quit":
                    print("Exiting Jobs Sample")
                    shouldExit = true

                case "get-pending-job-executions":
                    print("Getting all incomplete job executions")

                    let request = GetPendingJobExecutionsRequest(thingName: thingName)
                    do {
                        let response = try await jobsClient.getPendingJobExecutions(
                            request: request)
                        print(
                            "\n─── GetPendingJobExecutionsResponse ─────────────────────────────────────────────────\n"
                                + prettyPrint(response) + "\n\n")
                    } catch {
                        logJobsClientError(error)
                    }

                case "start-next-pending-job-execution":
                    print("Moving next pending job execution into the IN_PROGRESS state")
                    let request = StartNextPendingJobExecutionRequest(thingName: thingName)
                    do {
                        let response = try await jobsClient.startNextPendingJobExecution(
                            request: request)
                        print(
                            "\n─── StartNextJobExecutionResponse ─────────────────────────────────────────────────\n"
                                + prettyPrint(response) + "\n\n")
                    } catch {
                        logJobsClientError(error)
                    }

                default:
                    let tokens = input.split(separator: " ")
                    guard tokens.count > 1 else {
                        print("Invalid jobs command")
                        showMenu()
                        break
                    }

                    if lowercasedInput.hasPrefix("describe-job-execution") {
                        let request = DescribeJobExecutionRequest(
                            thingName: thingName, jobId: String(tokens[1]))
                        do {
                            let response = try await jobsClient.describeJobExecution(
                                request: request)
                            print(
                                "\n─── DescribeJobExecutionResponse ─────────────────────────────────────────────────\n"
                                    + prettyPrint(response) + "\n\n")
                        } catch {
                            logJobsClientError(error)
                        }

                    } else if lowercasedInput.hasPrefix("update-job-execution") {
                        guard let jobStatus = JobStatus(rawValue: String(tokens[2])) else {
                            print(
                                "\n─── Invalid Input ─────────────────────────────────────────────────\n"
                                    + "\"" + String(tokens[2]) + "\""
                                    + " is not a valid Job Status\n"
                                    + "<SUCCEEDED | IN_PROGRESS | FAILED | CANCELED>")
                            break
                        }
                        let request = UpdateJobExecutionRequest(
                            thingName: thingName, jobId: String(tokens[1]),
                            status: jobStatus)
                        //  (
                        //     thingName: thingName, jobId: String(tokens[1]))
                        do {
                            let response = try await jobsClient.updateJobExecution(request: request)
                            print(
                                "\n─── UpdateJobExecutionResponse ─────────────────────────────────────────────────\n"
                                    + prettyPrint(response) + "\n\n")
                        } catch {
                            logJobsClientError(error)
                        }
                    } else if lowercasedInput.hasPrefix("create-job") {
                        let inputJSON = tokens.dropFirst(2).joined(separator: " ")
                        let createJobInput = CreateJobInput(
                            document: inputJSON,
                            jobId: String(tokens[1]),
                            targetSelection: IoTClientTypes.TargetSelection.snapshot,
                            targets: [clientState.thingArn!])
                        do {
                            let result = try await iotClient.createJob(input: createJobInput)
                            print(
                                """

                                ─── CreateJobOutput ─────────────────────────────────────────────────
                                description: \(result.description ?? "<nil>")
                                jobArn: \(result.jobArn ?? "<nil>")
                                jobId: \(result.jobId ?? "<nil>")

                                """)
                        } catch {
                            print("Error encountered while attempting to create job \(error)")
                        }

                    } else if lowercasedInput.hasPrefix("delete-job") {
                        print("Deleting Job with jobId: " + String(tokens[1]))
                        let deleteJobInput = DeleteJobInput(jobId: String(tokens[1]))
                        do {
                            let _ = try await iotClient.deleteJob(input: deleteJobInput)
                        } catch {
                            print("Error encountered while attempting to delete job \(error)")
                        }
                    }
                }
            }
        }
    }
}

// Contains members that need to be accessed from across the sample and to prevent multiple resume calls
final class ClientState {
    var mqttClient: Mqtt5Client?
    var iotClient: IoTClient?
    var jobsClient: IotJobsClient?
    var thingArn: String?
    var stream1: StreamingOperation?
    var stream2: StreamingOperation?
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
