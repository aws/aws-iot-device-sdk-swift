import AwsIotDeviceSdkSwift
import Foundation
import XCTest

@testable import IotShadowClient

enum MqttTestError: Error {
    case timeout
    case connectionFail
    case disconnectFail
    case stopFail
}

class ShadowClientTests: XCTestCase {
    // Helper function that checks for an environment variable and skips test if it's missing.
    func getEnvironmentVarOrSkipTest(environmentVarName name: String) throws -> String {
        guard let result = ProcessInfo.processInfo.environment[name] else {
            throw XCTSkip("Skipping test because required environment variable \(name) is missing.")
        }
        return result
    }

    override func setUp() {
        super.setUp()
        IotDeviceSdk.initialize()
        try? Logger.initialize(target: .standardOutput, level: .error)
    }

    override func tearDown() {
        IotDeviceSdk.cleanUp()
        super.tearDown()
    }

    func awaitExpectation(_ expectations: [XCTestExpectation], _ timeout: TimeInterval = 5) async {
        // Remove the Ifdef once our minimum supported Swift version reaches 5.10
        #if swift(>=5.10)
            await fulfillment(of: expectations, timeout: timeout)
        #else
            wait(for: expectations, timeout: timeout)
        #endif
    }

    func jsonData(from dict: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])
    }

    // Helper function that creates an MqttClient, connects the client, uses the client to create an
    // IotShadowClient, then returns the shadow client in a ready for use state.
    private func getShadowClient() async throws -> IotShadowClient {
        // Obtain required endpoint and files from the envirotnment or skip test.
        let certPath = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
        let keyPath = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")
        let endpoint = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")

        // Used to track whether the Mqtt5 Client connection is successful.
        let connectionExpectation: XCTestExpectation = expectation(
            description: "Connection Success")
        let onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess = { successData in
            connectionExpectation.fulfill()
        }

        // Build the Mqtt5 Client
        let builder = try Mqtt5ClientBuilder.mtlsFromPath(
            certPath: certPath, keyPath: keyPath, endpoint: endpoint)
        builder.withOnLifecycleEventConnectionSuccess(onLifecycleEventConnectionSuccess)
        let mqttClient = try builder.build()
        XCTAssertNotNil(mqttClient)

        // Connect the Mqtt5 Client
        try mqttClient.start()
        // Await the expectation being fulfilled with a timeout.
        await fulfillment(of: [connectionExpectation], timeout: 5, enforceOrder: false)

        // Build and return the IotShadowClient
        let options: MqttRequestResponseClientOptions = MqttRequestResponseClientOptions(
            operationTimeout: 10)
        let shadowClient: IotShadowClient = try IotShadowClient(
            mqttClient: mqttClient, options: options)
        XCTAssertNotNil(shadowClient)
        return shadowClient
    }

    // Helper function to clean up
    func cleanupDeleteShadow(shadowClient: IotShadowClient, thingName: String, shadowName: String)
        async
    {
        let deleteRequest: DeleteNamedShadowRequest = DeleteNamedShadowRequest(
            thingName: thingName, shadowName: shadowName)
        do {
            let _ = try await shadowClient.deleteNamedShadow(request: deleteRequest)
        } catch {}
    }

    // Check the negative response on a non-existent named shadow
    private func checkNonExistentShadow(
        shadowClient: IotShadowClient,
        thingName: String,
        shadowName: String
    ) async throws {
        let request: GetNamedShadowRequest = GetNamedShadowRequest(
            thingName: thingName, shadowName: shadowName)
        do {
            let _ = try await shadowClient.getNamedShadow(request: request)
        } catch IotShadowClientError.errorResponse(let errorResponse) {
            XCTAssertEqual(
                errorResponse.code, 404,
                "Expected error code is 404, no shadow exists with provided name")
        }
    }

    // Successfully update a named shadow
    private func updateNamedShadow(
        shadowClient: IotShadowClient,
        thingName: String,
        shadowName: String,
        state: [String: Any]
    ) async throws {
        let shadowState: ShadowState = ShadowState()
        shadowState.withDesired(desired: state)

        let updateRequest: UpdateNamedShadowRequest = UpdateNamedShadowRequest(
            thingName: thingName, shadowName: shadowName)
        updateRequest.withState(state: shadowState)

        do {
            let _ = try await shadowClient.updateNamedShadow(
                request: updateRequest)
        } catch {
            XCTFail("updateNamedShadow failed")
        }
    }

    // Successfully get a named shadow
    private func getNamedShadow(
        shadowClient: IotShadowClient,
        thingName: String,
        shadowName: String
    ) async throws {
        let getRequest: GetNamedShadowRequest = GetNamedShadowRequest(
            thingName: thingName, shadowName: shadowName)
        do {
            let _ = try await shadowClient.getNamedShadow(request: getRequest)
        } catch {
            // Try to clean up
            await cleanupDeleteShadow(
                shadowClient: shadowClient, thingName: thingName, shadowName: shadowName)
            XCTFail("getNamedShadow failed")
        }
    }

    // Successfully delete a named shadow
    private func deleteNamedShadow(
        shadowClient: IotShadowClient,
        thingName: String,
        shadowName: String
    ) async throws {
        let deleteRequest: DeleteNamedShadowRequest = DeleteNamedShadowRequest(
            thingName: thingName, shadowName: shadowName)
        do {
            let _ = try await shadowClient.deleteNamedShadow(request: deleteRequest)
        } catch {
            XCTFail("deleteNamedShadow failed")
        }
    }

    // Test a get named shadow failure
    func testGetNonexistentShadow() async throws {
        let shadowClient: IotShadowClient = try await getShadowClient()
        let thingName = UUID().uuidString
        let shadowName = UUID().uuidString

        try await checkNonExistentShadow(
            shadowClient: shadowClient, thingName: thingName, shadowName: shadowName)
    }

    // Test creating/updating, getting, and deleting a named shadow request/response operations
    func testCreateGetDeleteShadow() async throws {
        let shadowClient: IotShadowClient = try await getShadowClient()
        let thingName = UUID().uuidString
        let shadowName = UUID().uuidString
        let color = UUID().uuidString

        let state = ["Color": color]
        try await updateNamedShadow(
            shadowClient: shadowClient, thingName: thingName, shadowName: shadowName, state: state)

        try await getNamedShadow(
            shadowClient: shadowClient, thingName: thingName, shadowName: shadowName)

        try await deleteNamedShadow(
            shadowClient: shadowClient, thingName: thingName, shadowName: shadowName)
    }

    // Test
    func testShadowStreams() async throws {
        let shadowClient: IotShadowClient = try await getShadowClient()
        let thingName = UUID().uuidString
        let shadowName = UUID().uuidString

        let colorInitial = "Color Init"
        let colorUpdated = "Color Update"
        // Set the shadow's initial state
        let stateInitial = ["Color": colorInitial]
        let updateResult: [String: Any] = ["Color": colorUpdated]
        let stateUpdate = ["Color": colorUpdated]

        // Expectations used to confirm update and subscription
        let updateExpectation: XCTestExpectation = XCTestExpectation(
            description: "Expect update")
        let subscribeSuccessExpectation: XCTestExpectation = XCTestExpectation(
            description: "Expect subscription success")
        let subscribeSuccessExpectation2: XCTestExpectation = XCTestExpectation(
            description: "Expect subscription success")

        // Insure test shadow doesn't exist
        try await checkNonExistentShadow(
            shadowClient: shadowClient, thingName: thingName, shadowName: shadowName)

        try await updateNamedShadow(
            shadowClient: shadowClient, thingName: thingName, shadowName: shadowName,
            state: stateInitial)

        // Check that we can get the shadow
        try await getNamedShadow(
            shadowClient: shadowClient, thingName: thingName, shadowName: shadowName)

        // Start a named shadow delta updated stream
        let namedShadowDeltaUpdatedSubscriptionRequest = NamedShadowDeltaUpdatedSubscriptionRequest(
            thingName: thingName, shadowName: shadowName)
        let clientStreamOptions = ClientStreamOptions<ShadowDeltaUpdatedEvent>(
            streamEventHandler: { event in
                // Check that the updated state is what we expect
                XCTAssertNoThrow {
                    let lhs = try self.jsonData(from: event.state!)
                    let rhs = try self.jsonData(from: updateResult)
                    XCTAssertEqual(lhs, rhs)
                }
                updateExpectation.fulfill()
            },
            subscriptionEventHandler: { event in
                if event.event == SubscriptionStatusEventType.established {
                    subscribeSuccessExpectation.fulfill()
                }
            },
            deserializationFailureHandler: { _ in
                XCTFail("Deserialization Failure")
            }
        )
        let deltaUpdatedOperation = try shadowClient.createNamedShadowDeltaUpdatedStream(
            request: namedShadowDeltaUpdatedSubscriptionRequest,
            options: clientStreamOptions)

        // Start a named shadow updated stream
        let namedShadowUpdatedSubscriptionRequest = NamedShadowUpdatedSubscriptionRequest(
            thingName: thingName, shadowName: shadowName)
        let clientStreamOptions2 = ClientStreamOptions<ShadowUpdatedEvent>(
            streamEventHandler: { event in
                let previousDesired = event.previous?.state?.desired ?? ["error": "error"]
                let currentDesired = event.current?.state?.desired ?? ["error": "error"]
                XCTAssertNoThrow {
                    let lhs = try self.jsonData(from: previousDesired)
                    let rhs = try self.jsonData(from: stateInitial)
                    XCTAssertEqual(lhs, rhs)
                }
                XCTAssertNoThrow {
                    let lhs = try self.jsonData(from: currentDesired)
                    let rhs = try self.jsonData(from: stateUpdate)
                    XCTAssertEqual(lhs, rhs)
                }
            },
            subscriptionEventHandler: { event in
                if event.event == SubscriptionStatusEventType.established {
                    subscribeSuccessExpectation2.fulfill()
                }
            },
            deserializationFailureHandler: { _ in }
        )
        let updatedOperation = try shadowClient.createNamedShadowUpdatedStream(
            request: namedShadowUpdatedSubscriptionRequest,
            options: clientStreamOptions2)

        // open the streams and await their subscriptions to be active
        try deltaUpdatedOperation.open()
        try updatedOperation.open()
        await awaitExpectation([subscribeSuccessExpectation2], 5)
        await awaitExpectation([subscribeSuccessExpectation], 5)

        // Update the shadow which should trigger both streams
        try await updateNamedShadow(
            shadowClient: shadowClient, thingName: thingName, shadowName: shadowName,
            state: stateUpdate)

        await awaitExpectation([updateExpectation], 5)

        // Clean up the test shadow
        try await deleteNamedShadow(
            shadowClient: shadowClient, thingName: thingName, shadowName: shadowName)
    }
}
