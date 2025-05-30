// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

// ArgumentParser is used by the sample to parse arguments.
// This is not a required import for the MQTT5 Client.
import ArgumentParser
import AwsIotDeviceSdkSwift
import Foundation
import IotIdentityClient

@main
struct CsrProvisioningSample: AsyncParsableCommand {
    /**************************************
    * Arguments used by ArgumentParser
    **************************************/
    @Argument(help: "The endpoint to connect to.")
    var endpoint: String

    @Argument(help: "The path to the certificate file.")
    var cert: String

    @Argument(help: "The path to the private key file.")
    var key: String

    @Argument(help: "Provisioninig template name.")
    var template: String

    @Argument(help: "The path to the CSR file.")
    var csr: String

    @Argument(help: "JSON string of parameters to pass to RegisterThing.")
    var parametersJson: String

    @Argument(
        help: "Client id to use (optional). Please make sure the client id matches the policy.")
    var clientId: String = "test-" + UUID().uuidString

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

            // Setup options for the MqttRequestResponseClient
            let options = MqttRequestResponseClientOptions(
                maxRequestResponseSubscription: 3,
                maxStreamingSubscription: 2,
                operationTimeout: 5)

            // Create an IotIdentityClient using the Mqtt5Client and MqttRequestResponseClientOptions
            clientState.identityClient = try IotIdentityClient(mqttClient: client, options: options)
        } catch {
            print("Failed to setup client with error: \(error).")
            return
        }

        do {
            guard let identityClient = clientState.identityClient else {
                print("Failed to setup identityClient")
                return
            }

            let csrString: String
            do {
                csrString = try String(contentsOfFile: csr)
            } catch {
                print("CSR contents not retrievable.")
                return
            }

            // Creates a certificate from a certificate signing request (CSR).
            // AWS IoT provides client certificates that are signed by the Amazon Root certificate authority (CA).
            // The new certificate has a PENDING_ACTIVATION status.
            // When you call RegisterThing to provision a thing with this certificate, the certificate
            // status changes to ACTIVE or INACTIVE as described in the template.
            let createCertificateFromCsrRequest = CreateCertificateFromCsrRequest(
                certificateSigningRequest: csrString)
            let createCertificateFromCsrResponse =
                try await identityClient.createCertificateFromCsr(
                    request: createCertificateFromCsrRequest)

            guard let params = parseParameters(from: parametersJson) else {
                print("Invalid parameters JSON string.")
                return
            }

            let registerThingRequest = RegisterThingRequest(
                templateName: template,
                certificateOwnershipToken: createCertificateFromCsrResponse
                    .certificateOwnershipToken!,
                parameters: params)

            // Make the request to register a thing
            let registerThingResponse = try await identityClient.registerThing(
                request: registerThingRequest)

            print("Created thingName: \(registerThingResponse.thingName!)")
        } catch {
            logIdentityClientError(error)
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

            // Build the client.
            do {
                // Build the Mqtt5Client using the builder.
                let client = try builder.build()
                state.client = client
                try client.start()
            } catch {
                state.tryResumeOnce {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    // Helper function that parses the command line argument into [String: String]
    func parseParameters(from jsonString: String) -> [String: String]? {
        guard let data = jsonString.data(using: .utf8) else {
            print("Failed to convert parameters JSON string to Data.")
            return nil
        }
        do {
            let decoded = try JSONDecoder().decode([String: String].self, from: data)
            return decoded
        } catch {
            print("Failed to decode parameters JSON: \(error)")
            return nil
        }
    }

    // Handle errors thrown by the identity client
    public func logIdentityClientError(_ error: Error) {
        // Step 1 ─ try to cast into expected `IotIdentityClientError`
        guard let err = error as? IotIdentityClientError else {
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

            var output = "\n─── Service Request Rejected ────────────────────────────\n"
            if let errorCode = errorResponse.errorCode {
                output += "code:        \(errorCode)\n"
            }
            if let message = errorResponse.errorMessage {
                output += "message:     \(message)\n"
            }
            print(output + "\n\n")

        case .underlying(let swiftErr):
            print(
                """

                ─── Underlying Swift Error ────────────────────────────────────────────
                \(swiftErr)

                """)
        }
    }
}

// Contains members that need to be accessed from across the sample and to prevent multiple resume calls
final class ClientState {
    var client: Mqtt5Client?
    var identityClient: IotIdentityClient?
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
