// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

// ArgumentParser is used by the sample to parse arguments.
// This is not a required import for the MQTT5 Client.
import ArgumentParser
import AwsIotDeviceSdkSwift
import Foundation
import IotShadowClient

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
      get                                   -- gets the thing's current shadow document
      delete                                -- deletes the thing's shadow document
      update-desired <Desired state JSON>   -- updates the desired component of the thing's shadow document
      update-reported <Reported state JSON> -- updates the reported component of the thing's shadow document
      help                                  -- prints this message
      quit                                  -- exit the application

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
        endpoint: self.endpoint, certPath: self.cert, keyPath: self.key)

      // Various other configuration options can be set on the Mqtt5ClientBuilder.
      clientBuilder.withClientId(clientId)

      // Use the builder to create an Mqtt5 Client and connect it.
      let client = try await buildAndConnect(from: clientBuilder, state: clientState)

      // Setup options for the MqttRequestResponseClient
      let options = MqttRequestResponseClientOptions(
        maxRequestResponseSubscription: 3,
        maxStreamingSubscription: 2,
        operationTimeout: 5)

      // Create an IotShadowClient using the Mqtt5 Client and MqttRequestResponseClientOptions
      let shadowClient = try IotShadowClient(mqttClient: client, options: options)

      // Sets up updated and delta updated streams
      let (deltaUpdatedOperation, updatedOperation) = try startStreamingOperations(
        shadowClient: shadowClient, clientState: clientState)

      // open both streams to receive events
      try deltaUpdatedOperation.open()
      try updatedOperation.open()

      // Display commands.
      showMenu()

      // Enter the interactive loop.
      await interactiveLoop(
        client: client, shadowClient: shadowClient, clientState: clientState)

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

  func startStreamingOperations(shadowClient: IotShadowClient, clientState: ClientState) throws
    -> (StreamingOperation, StreamingOperation)
  {
    do {
      // Start a shadow delta updated stream
      let shadowDeltaUpdatedSubscriptionRequest = ShadowDeltaUpdatedSubscriptionRequest(
        thingName: thingName)
      let deltaUpdateStreamOptions = ClientStreamOptions<ShadowDeltaUpdatedEvent>(
        // Handles delta update events
        streamEventHandler: { event in
          print(
            "\n─── ShadowDeltaUpdatedEvent ───────────────────────────────────────────\n"
              + prettyPrint(event) + "\n\n")
        },
        // We are not tracking subscription events in this sample
        subscriptionEventHandler: { _ in
        },
        // We are not handling deserializatiion failures ini this sample
        deserializationFailureHandler: { _ in
        }
      )
      let deltaUpdatedOperation = try shadowClient.createShadowDeltaUpdatedStream(
        request: shadowDeltaUpdatedSubscriptionRequest,
        options: deltaUpdateStreamOptions)

      // Start a shadow updated stream
      let shadowUpdatedSubscriptionRequest = ShadowUpdatedSubscriptionRequest(
        thingName: thingName)
      let updateStreamOptions2 = ClientStreamOptions<ShadowUpdatedEvent>(
        // Handles update events
        streamEventHandler: { event in
          print(
            "\n─── ShadowUpdatedEvent ────────────────────────────────────────────────\n"
              + prettyPrint(event) + "\n\n")
        },
        // We are not tracking subscription events in this sample
        subscriptionEventHandler: { _ in
        },
        // We are not handling deserializatiion failures ini this sample
        deserializationFailureHandler: { _ in
        }
      )
      let updatedOperation = try shadowClient.createShadowUpdatedStream(
        request: shadowUpdatedSubscriptionRequest,
        options: updateStreamOptions2)

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

  // Handle errors thrown by the shadow client
  public func logShadowClientError(_ error: Error) {
    // Step 1 ─ try to cast into expected `IotShadowClientError`
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
    client: Mqtt5Client, shadowClient: IotShadowClient, clientState: ClientState
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
              "\n─── GetShadowResponse ─────────────────────────────────────────────────\n"
                + prettyPrint(response) + "\n\n")
          } catch {
            logShadowClientError(error)
          }

        case "delete":
          let request: DeleteShadowRequest = DeleteShadowRequest(
            thingName: thingName)
          do {
            let response = try await shadowClient.deleteShadow(request: request)
            print(
              "\n─── DeleteShadowResponse ──────────────────────────────────────────────\n"
                + prettyPrint(response) + "\n\n")
          } catch {
            logShadowClientError(error)
          }

        default:
          let tokens = input.split(separator: " ")
          guard tokens.count > 1 else {
            print("Invalid shadow command")
            showMenu()
            break
          }

          do {
            if lowercasedInput.hasPrefix("update-desired") {
              let inputJSON = tokens.dropFirst().joined(separator: " ")
              if let desiredDict = parseJSONStringToDictionary(inputJSON) {
                let desiredState = ShadowState(desired: desiredDict)
                let request = UpdateShadowRequest(
                  thingName: thingName, state: desiredState)
                let response = try await shadowClient.updateShadow(request: request)
                print(
                  "\n─── UpdateShadowResponse ────────────────────────────────────────────\n"
                    + prettyPrint(response) + "\n\n")
              }
            } else if lowercasedInput.hasPrefix("update-reported") {
              let inputJSON = tokens.dropFirst().joined(separator: " ")
              if let reportedDict = parseJSONStringToDictionary(inputJSON) {
                let reportedState = ShadowState(reported: reportedDict)
                let request: UpdateShadowRequest = UpdateShadowRequest(
                  thingName: thingName, state: reportedState)
                let response = try await shadowClient.updateShadow(request: request)
                print(
                  "\n─── UpdateShadowResponse ────────────────────────────────────────────\n"
                    + prettyPrint(response) + "\n\n")
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

// Contains members that need to be accessed from across the sample and to prevent multiple resume calls
final class ClientState {
  var mqttClient: Mqtt5Client?
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
