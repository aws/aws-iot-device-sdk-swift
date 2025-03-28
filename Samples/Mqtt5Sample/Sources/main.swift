// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

// ArgumentParser is used by the sample to parse arguments.
// This is not a required import for the MQTT5 Client.
import ArgumentParser
import AwsIotDeviceSdkSwift
import Foundation

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

    @Argument(
        help: "Client id to use (optional). Please make sure the client id matches the policy.")
    var clientId: String = "test-" + UUID().uuidString

    /// Displays available Commands
    func showMenu() {
        print(
            """

            Commands:
            start - Starts session, instructing the MQTT5 client to desire a connected state.
            stop - Stops session, putting the MQTT5 client in a disconnected state.
            subscribe <qos> <topic> - Subscribes to topic.
            unsubscribe <topic> - Unsubscribe from a topic.
            publish <qos> <topic> <payload text> - Sends a publish packet.
            help - Display available commands
            exit - Exit the program

            """)
    }

    mutating func run() async throws {
        // The IoT Device SDK must be initialized before it is used.
        IotDeviceSdk.initialize()

        do {
            // Create an Mqtt5ClientBuilder configured to connect using a certificate and private key.
            let clientBuilder = try Mqtt5ClientBuilder.mtlsFromPath(
                certPath: self.cert, keyPath: self.key, endpoint: self.endpoint)

            // Callbacks to be assigned to the builder
            // The full list of callbacks and their uses can be found in the MQTT5 User Guide
            func onLifecycleEventStopped(_: LifecycleStoppedData) async {
                print("Mqtt5Client: onLifecycleEventStopped callback invoked.")
            }
            func onLifecycleEventAttemptingConnect(_: LifecycleAttemptingConnectData) async {
                print("Mqtt5Client: onLifecycleEventAttemptingConnect callback invoked.")
            }
            func onLifecycleEventConnectionSuccess(_: LifecycleConnectionSuccessData) async {
                print("Mqtt5Client: onLifecycleEventConnectionSuccess callback invoked.")
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

            // The onPublishReceived callback handles all publish packets the Mqtt5 Client receives.
            func onPublishReceived(publishData: PublishReceivedData) async {
                let packet: PublishPacket = publishData.publishPacket
                let payload = packet.payloadAsString() ?? "[no payload]"
                print(
                    """
                    Publish Packet Received
                        QoS: \(packet.qos)
                        Topic: \(packet.topic)
                        Payload: \(payload)
                    """)
            }

            // Callbacks can be assigned all at once using `withCallbacks` on the Mqtt5ClientBuilder
            clientBuilder.withCallbacks(
                onLifecycleEventAttemptingConnect: onLifecycleEventAttemptingConnect,
                onLifecycleEventConnectionSuccess: onLifecycleEventConnectionSuccess,
                onLifecycleEventConnectionFailure: onLifecycleEventConnectionFailure,
                onLifecycleEventDisconnection: onLifecycleEventDisconnection,
                onLifecycleEventStopped: onLifecycleEventStopped)

            // They can also be assigned individually
            clientBuilder.withOnPublishReceived(onPublishReceived)

            // Various other configuration options can be set on the Mqtt5ClientBuilder.
            clientBuilder.withClientId(clientId)

            // The configured Mqtt5ClientBuilder is used to create an Mqtt5Client.
            let client = try clientBuilder.build()

            // Display commands.
            showMenu()

            // Enter the interactive loop.
            await interactiveLoop(client: client)

        } catch {
            print("Failed to setup client.")
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

    // Helper function that parses the requested QoS
    func getQoS(token: String) -> QoS? {
        switch token.lowercased() {
        case "qos0":
            return .atMostOnce
        case "0":
            return .atMostOnce
        case "qos1":
            return .atLeastOnce
        case "1":
            return .atLeastOnce
        default:
            print("Unsupported QoS level: \(token). Only qos0 and qos1 are supported.")
            return nil
        }
    }

    // Main loop that runs while the sample is active
    func interactiveLoop(client: Mqtt5Client) async {
        var shouldExit = false
        while !shouldExit {
            if let input = await asyncReadLine(prompt: "Enter command:\n") {
                let lowercasedInput = input.lowercased()
                switch lowercasedInput {
                case "help":
                    showMenu()

                case "start":
                    print("Starting session. Mqtt5 Client will try to connect.")
                    do {
                        try client.start()
                    } catch {
                        print("Failed to start client.")
                    }

                case "stop":
                    print("Stopping session. Mqtt5 Client will disconnect.")
                    do {
                        try client.stop()
                    } catch {
                        print("Failed to stop client.")
                    }

                case "exit":
                    print("Exiting MQTT5 Sample")
                    shouldExit = true
                case "quit":
                    print("Exiting MQTT5 Sample")
                    shouldExit = true

                default:
                    let tokens = input.split(separator: " ")

                    // Check if the command begins with "publish"
                    if lowercasedInput.hasPrefix("publish") {
                        // Expected format: publish <qos> <topic> <payload text>...
                        guard tokens.count >= 4 else {
                            print(
                                "Invalid publish command. Format: publish <qos> <topic> <payload text>"
                            )
                            break
                        }

                        // tokens[0] is "publish", tokens[1] is qos, tokens[2] is topic, the rest form the payload.
                        let qosToken = tokens[1]
                        let topic = String(tokens[2])
                        let payloadString = tokens.dropFirst(3).joined(separator: " ")

                        // Parse the qos level (supporting qos0 and qos1 for example)
                        if let qos = getQoS(token: qosToken.lowercased()) {
                            // Create a PublishPacket and use the Mqtt5 Client to publish.
                            Task {
                                do {
                                    let payloadData = Data(payloadString.utf8)
                                    let publishPacket: PublishPacket = PublishPacket(
                                        qos: qos, topic: topic, payload: payloadData)
                                    let publishResult: PublishResult = try await client.publish(
                                        publishPacket: publishPacket)
                                    if let puback: PubackPacket = publishResult.puback {
                                        print(
                                            "PubackPacket received with reasonCode: \(puback.reasonCode)"
                                        )
                                    }
                                } catch {
                                    print("Failed to publish message: \(error)")
                                }
                            }
                        }
                    }
                    // Check if the command begins with "subscribe"
                    else if lowercasedInput.hasPrefix("subscribe") {
                        // Expected format: subscribe <qos> <topic>
                        guard tokens.count == 3 else {
                            print("Invalid subscribe command. Format: subscribe <qos> <topic>")
                            break
                        }

                        // tokens[0] is "subscribe", tokens[1] is qos, tokens[2] is the topic.
                        let qosToken = tokens[1]
                        let topic = String(tokens[2])
                        // Parse the qos level (supporting qos0 and qos1 for example)
                        if let qos = getQoS(token: qosToken.lowercased()) {
                            // Create a SubscribePacket and use the Mqtt5 Client to subscribe.
                            Task {
                                do {
                                    let subscribePacket: SubscribePacket = SubscribePacket(
                                        topicFilter: topic, qos: qos)
                                    let subackPacket: SubackPacket = try await client.subscribe(
                                        subscribePacket: subscribePacket)
                                    print(
                                        "SubackPacket received with reasonCode: \(subackPacket.reasonCodes[0])"
                                    )
                                } catch {
                                    print("Failed to subscribe: \(error)")
                                }
                            }
                        }
                    }
                    // Check if the command begins with "unsubscribe"
                    else if lowercasedInput.hasPrefix("unsubscribe") {
                        // Expected format: unsubscribe <topic>
                        guard tokens.count == 2 else {
                            print("Invalid unsubscribe command. Formant: unsubscribe <topic>")
                            break
                        }

                        // tokens[0] is "unsubscribe", tokens[1] is the topic.
                        let topic = String(tokens[1])
                        // Create an UnsubscribePacket and use the Mqtt5 Client to unsubscribe.
                        Task {
                            do {
                                let unsubscribePacket: UnsubscribePacket = UnsubscribePacket(
                                    topicFilter: topic)
                                let unsubackPacket: UnsubackPacket = try await client.unsubscribe(
                                    unsubscribePacket: unsubscribePacket)
                                print(
                                    "UnsubackPacket received with reason code: \(unsubackPacket.reasonCodes[0])"
                                )
                            } catch {
                                print("Failed to unsubscribe: \(error)")
                            }
                        }

                    } else {
                        print("Unknown command: \(input)")
                        showMenu()
                    }
                }
            }
        }
    }
}
