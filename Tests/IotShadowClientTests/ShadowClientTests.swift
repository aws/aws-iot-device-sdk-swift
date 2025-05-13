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
                ─── CRT error ───────────────────────────────────────────────
                code:    \(crt.code)
                name:    \(crt.name)
                message: \(crt.message)
                ─────────────────────────────────────────────────────────────
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
                ─── Underlying Swift error ─────────────────────────────────
                \(swiftErr)
                ────────────────────────────────────────────────────────────
                """)
        }
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

    // Helper function that creates an MqttClient, connects, and returns an IotShadowClient using the mqtt client
    private func getShadowClient() async throws -> IotShadowClient {
        // Obtain required files or skip test.
        let certPath = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
        let keyPath = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")
        let endpoint = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let builder = try Mqtt5ClientBuilder.mtlsFromPath(
            certPath: certPath, keyPath: keyPath, endpoint: endpoint)

        // Track that Mqtt5 Client connection is successful
        let connectionExpectation: XCTestExpectation = expectation(
            description: "Connection Success")

        let onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess = { successData in
            print("Mqtt5Client: onLifecycleEventConnectionSuccess")
            connectionExpectation.fulfill()
        }
        builder.withOnLifecycleEventConnectionSuccess(onLifecycleEventConnectionSuccess)

        let mqttClient = try builder.build()
        XCTAssertNotNil(mqttClient)
        try mqttClient.start()
        // Await the expectation being fulfilled with a timeout.
        await fulfillment(of: [connectionExpectation], timeout: 5, enforceOrder: false)

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
        } catch {
            print("cleanup deleteNamedShadow failed")
        }
    }

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
            print(error)
            XCTFail("updateNamedShadow failed")
        }
        print("updateNamedShadow succeeded")
    }

    private func getNamedShadow(
        shadowClient: IotShadowClient,
        thingName: String,
        shadowName: String
    ) async throws {
        let getRequest: GetNamedShadowRequest = GetNamedShadowRequest(
            thingName: thingName, shadowName: shadowName)
        do {
            let result = try await shadowClient.getNamedShadow(request: getRequest)
            print(
                """
                Get Named Shadow Result:
                state: \(result.state?.desired ?? ["null": "null"])
                """)
        } catch {
            // Try to clean up
            await cleanupDeleteShadow(
                shadowClient: shadowClient, thingName: thingName, shadowName: shadowName)
            XCTFail("getNamedShadow failed")
        }
        print("getNamedShadow succeeded")
    }

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
        print("deleteNamedShadow succeeded")
    }

    func testGetNonexistentShadow() async throws {
        let shadowClient: IotShadowClient = try await getShadowClient()
        let thingName = UUID().uuidString
        let shadowName = UUID().uuidString

        try await checkNonExistentShadow(
            shadowClient: shadowClient, thingName: thingName, shadowName: shadowName)
    }

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

    func testUpdateShadow() async throws {
        let shadowClient: IotShadowClient = try await getShadowClient()
        let thingName = UUID().uuidString
        let shadowName = UUID().uuidString
        let color = "Color Init"
        let color2 = "Color Update"
        let updateResult: [String: Any] = ["Color": color2]
        let stateUpdate = ["Color": color2]

        try await checkNonExistentShadow(
            shadowClient: shadowClient, thingName: thingName, shadowName: shadowName)

        let state = ["Color": color]
        try await updateNamedShadow(
            shadowClient: shadowClient, thingName: thingName, shadowName: shadowName, state: state)

        try await getNamedShadow(
            shadowClient: shadowClient, thingName: thingName, shadowName: shadowName)

        let updateExpectation: XCTestExpectation = XCTestExpectation(
            description: "Expect update")
        let subscribeSuccessExpectation: XCTestExpectation = XCTestExpectation(
            description: "Expect subscription success")
        let namedShadowDeltaUpdatedSubscriptionRequest = NamedShadowDeltaUpdatedSubscriptionRequest(
            thingName: thingName, shadowName: shadowName)
        let clientStreamOptions = ClientStreamOptions<ShadowDeltaUpdatedEvent>(
            streamEventHandler: { event in
                print(
                    """
                    ─── streamEventHandler Shadow Delta Updated Event ───────────
                    code:    \(event.state ?? ["nil":"nil"])
                    name:    \(event.timestamp?.formatted(.iso8601) ?? "<nil>")
                    ─────────────────────────────────────────────────────────────
                    streamEventHandler received \(String(describing: event))
                    """)

                XCTAssertNoThrow {
                    let lhs = try self.jsonData(from: event.state!)
                    let rhs = try self.jsonData(from: updateResult)
                    XCTAssertEqual(lhs, rhs)
                }
                updateExpectation.fulfill()
            },
            subscriptionEventHandler: { event in
                if event.event == SubscriptionStatusEventType.established {
                    print("NamedShadowDeltaUpdatedSubscriptionRequest Subscription established")
                    subscribeSuccessExpectation.fulfill()
                }
            },
            deserializationFailureHandler: { _ in }
        )
        let deltaUpdatedOperation = try shadowClient.createNamedShadowDeltaUpdatedStream(
            request: namedShadowDeltaUpdatedSubscriptionRequest,
            options: clientStreamOptions)
        try deltaUpdatedOperation.open()
        await awaitExpectation([subscribeSuccessExpectation], 5)

        let subscribeSuccessExpectation2: XCTestExpectation = XCTestExpectation(
            description: "Expect subscription success")
        let namedShadowUpdatedSubscriptionRequest = NamedShadowUpdatedSubscriptionRequest(
            thingName: thingName, shadowName: shadowName)
        let clientStreamOptions2 = ClientStreamOptions<ShadowUpdatedEvent>(
            streamEventHandler: { event in
                let previousDesired = event.previous?.state?.desired ?? ["nil": "nil"]
                let currentDesired = event.current?.state?.desired ?? ["nil": "nil"]
                print(
                    """
                    ─── streamEventHandler Shadow Updated Event ─────────────────
                    previous desired: \(previousDesired)
                    current desired:  \(currentDesired)
                    ─────────────────────────────────────────────────────────────
                    """)
                XCTAssertNoThrow {
                    let lhs = try self.jsonData(from: previousDesired)
                    let rhs = try self.jsonData(from: state)
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
                    print("NamedShadowUpdatedSubscriptionRequest Subscription established")
                    subscribeSuccessExpectation2.fulfill()
                }
            },
            deserializationFailureHandler: { _ in }
        )
        let updatedOperation = try shadowClient.createNamedShadowUpdatedStream(
            request: namedShadowUpdatedSubscriptionRequest,
            options: clientStreamOptions2)
        try updatedOperation.open()
        await awaitExpectation([subscribeSuccessExpectation2], 5)

        try await updateNamedShadow(
            shadowClient: shadowClient, thingName: thingName, shadowName: shadowName,
            state: stateUpdate)

        await awaitExpectation([updateExpectation], 5)

        try await deleteNamedShadow(
            shadowClient: shadowClient, thingName: thingName, shadowName: shadowName)

        print("All good")
    }
}
