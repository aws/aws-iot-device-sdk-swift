import AwsIotDeviceSdkSwift
import Foundation
import XCTest

@testable import ShadowClient

enum MqttTestError: Error {
    case timeout
    case connectionFail
    case disconnectFail
    case stopFail
}

class ShadowClientTests: XCTestCase {
    func getEnvironmentVarOrSkipTest(environmentVarName name: String) throws -> String {
        guard let result = ProcessInfo.processInfo.environment[name] else {
            throw XCTSkip("Skipping test because required environment variable \(name) is missing.")
        }
        return result
    }

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    let sampleState1: [String: Any] = [
        "power": true,
        "brightness": 80,
        "info": ["version": "1.2.3", "status": "active"],
    ]

    let sampleState2: [String: Any] = [
        "power": false,
        "brightness": 0,
        "info": ["version": "1.2.3", "status": "inactive"],
    ]

    override func setUp() {
        super.setUp()

        // // Optional: For readable output, enable pretty-printed formatting:
        // encoder.outputFormatting = .prettyPrinted
        // // Optional: Customize date encoding if needed (e.g., ISO8601)
        // encoder.dateEncodingStrategy = .iso8601
        // // Make sure to set the same date decoding strategy that was used when encoding.
        // decoder.dateDecodingStrategy = .iso8601

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

        case .service(let svc):
            switch svc {

            case let v2 as V2ErrorResponse:
                print(
                """
                ─── Service rejected request ────────────────────────────
                clientToken: \(v2.clientToken ?? "<nil>")
                code:        \(v2.code)
                message:     \(v2.message ?? "<nil>")
                timestamp:   \(v2.timestamp?.formatted(.iso8601) ?? "<nil>")
                ───────────────────────────────────────────────────────────
                """)

            default:
                print("Service‑layer error of unknown type: \(svc)")
            }

        case .underlying(let swiftErr):
            print(
            """
            ─── Underlying Swift error ─────────────────────────────────
            \(swiftErr)
            ────────────────────────────────────────────────────────────
            """)
        }
    }

    func testShadowClient() async throws {
        print("Starting testShadowClient")
        ////////////////////////////////////////////////////////////
        /// Initialize working mqtt client
        ////////////////////////////////////////////////////////////
        // Create an expectation for the connection.
        let connectionExpectation = expectation(description: "Connection Success")

        let onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess = { successData in
            print("Mqtt5Client: onLifecycleEventConnectionSuccess")
            connectionExpectation.fulfill()
        }
        // let onPublishReceived: OnPublishReceived = { publishData in
        //     let packet: PublishPacket = publishData.publishPacket
        //     let payload = packet.payloadAsString() ?? "[no payload]"
        //     print(
        //         """
        //         Publish Packet Received
        //             QoS: \(packet.qos)
        //             Topic: \(packet.topic)
        //             Payload: \(payload)
        //         """)
        // }
        let certPath = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
        let keyPath = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")
        let endpoint = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let builder = try Mqtt5ClientBuilder.mtlsFromPath(
            certPath: certPath, keyPath: keyPath, endpoint: endpoint)
        builder.withOnLifecycleEventConnectionSuccess(onLifecycleEventConnectionSuccess)
        // builder.withOnPublishReceived(onPublishReceived)
        let mqttClient = try builder.build()
        XCTAssertNotNil(mqttClient)
        print("Client built")

        ////////////////////////////////////////////////////////////
        /// Start the mqttClient
        ////////////////////////////////////////////////////////////
        try mqttClient.start()
        // Await the expectation being fulfilled with a timeout.
        await fulfillment(of: [connectionExpectation], timeout: 5, enforceOrder: false)

        ////////////////////////////////////////////////////////////
        // Create fake rrClient for use to establish shadowClient
        ////////////////////////////////////////////////////////////
        let options: MqttRequestResponseClientOptions = MqttRequestResponseClientOptions(operationTimeout: 5)
        let rrClient = try MqttRequestResponseClient.newFromMqtt5Client(mqtt5Client: mqttClient, options: options)
        // let rrClient = AwsIotDeviceSdkSwift.MqttRequestResponseClient(mqttClient: mqttClient)
        XCTAssertNotNil(rrClient)
        let shadowClient = try IotShadowClient(rrClient: rrClient)
        XCTAssertNotNil(shadowClient)

        // try await runGetShadow(shadowClient: shadowClient)
        try await runUpdateShadow(shadowClient: shadowClient, color: "Purple")
        try await runGetShadow(shadowClient: shadowClient)
        try await runUpdateShadow(shadowClient: shadowClient, color: "Green")
        try await runGetShadow(shadowClient: shadowClient)
        try await runDeleteShadow(shadowClient: shadowClient)
        try await runGetShadow(shadowClient: shadowClient)        
        try await runUpdateNamedShadow(shadowClient: shadowClient, color: "Pink")
        try await runGetNamedShadow(shadowClient: shadowClient)
        try await runDeleteNamedShadow(shadowClient: shadowClient)
        try await runDeleteNamedShadow(shadowClient: shadowClient)

        print("\nEnd Tests\n")
    }

    private func compareDocument(lhs: [String: Any]?, rhs: [String: Any]?) -> Bool {
        if let lhsDoc = lhs, let rhsDoc = rhs {
            // NSDictionary provides a deep equality test for property lists.
            return (lhsDoc as NSDictionary).isEqual(to: rhsDoc)
        } else {
            return (lhs == nil && rhs == nil)
        }
    }

    private func runDeleteShadow(shadowClient: IotShadowClient) async throws {
        print("\n=======")
        print("runDeleteShadow()")
        let request: DeleteShadowRequest = DeleteShadowRequest(thingName: "thingName")
        do {
            let response = try await shadowClient.deleteShadow(request: request)
            print(
            """
            deleteShadow response recieved:                
                timestamp: \(response.timestamp!)
                version: \(response.version!)
            """)
        print("=======\n")
        } catch {
            logShadowClientError(error)
        }
    }

    private func runDeleteNamedShadow(shadowClient: IotShadowClient) async throws {
        print("\n=======")
        print("runDeleteNamedShadow()")
        let request: DeleteNamedShadowRequest = DeleteNamedShadowRequest(thingName: "thingName", shadowName: "shadowName")
        do {
            let response = try await shadowClient.deleteNamedShadow(request: request)

            print(
                """
                deleteNamedShadow response recieved:                
                    clientToken: \(response.clientToken!)                    
                    timestamp: \(response.timestamp!)
                    version: \(response.version!)
                """)
            print("=======\n")
        } catch {
            logShadowClientError(error)
        }
    }

    private func runGetNamedShadow(shadowClient: IotShadowClient) async throws {
        print("\n=======")
        print("runGetNamedShadow()")
        let request: GetNamedShadowRequest = GetNamedShadowRequest(thingName: "thingName", shadowName: "shadowName")
        do {
            let response = try await shadowClient.getNamedShadow(request: request)
            let shadowStateResponse = response.state!
            let shadowMetaDataResponse = response.metadata!

            print(
                """
                getNamedShadow response recieved:                
                    state: \(shadowStateResponse.desired!)
                    metadata.desired: \(shadowMetaDataResponse.desired!)
                    timestamp: \(response.timestamp!)
                """)
            print("=======\n")
        } catch {
            logShadowClientError(error)
        }
    }

    private func runGetShadow(shadowClient: IotShadowClient) async throws {
        print("\n=======")
        print("runGetShadow()")
        let request: GetShadowRequest = GetShadowRequest(thingName: "thingName")
        do {
            let response = try await shadowClient.getShadow(request: request)
            let shadowStateResponse = response.state!
            let shadowMetaDataResponse = response.metadata!

            print(
                """
                getShadow response recieved:                
                    state: \(shadowStateResponse.desired!)
                    metadata.desired: \(shadowMetaDataResponse.desired!)
                    timestamp: \(response.timestamp!)
                """)
            print("=======\n")      
        } catch {
            logShadowClientError(error)
        }
    }

    private func runUpdateNamedShadow(shadowClient: IotShadowClient, color: String) async throws {
        print("\n=======")
        print("runUpdateNamedShadow(\(color))")
        let request: UpdateNamedShadowRequest = UpdateNamedShadowRequest(thingName: "thingName", shadowName: "shadowName")
        let shadowState: ShadowState = ShadowState()
        shadowState.withDesired(desired: ["Color":color])
        request.withState(state: shadowState)
        do {
            let response = try await shadowClient.updateNamedShadow(request: request)
            let shadowStateResponse = response.state!
            let shadowMetaDataResponse = response.metadata!

            print(
                """
                updateNamedShadow response recieved:                
                    state: \(shadowStateResponse.desired!)
                    metadata.desired: \(shadowMetaDataResponse.desired!)
                    timestamp: \(response.timestamp!)
                """)
            print("=======\n")
        } catch {
            logShadowClientError(error)
        }
    }

    private func runUpdateShadow(shadowClient: IotShadowClient, color: String) async throws {
        print("\n=======")
        print("runUpdateShadow(\(color))")
        let request: UpdateShadowRequest = UpdateShadowRequest(thingName: "thingName")
        let shadowState: ShadowState = ShadowState()
        shadowState.withDesired(desired: ["Color":color])
        request.withState(state: shadowState)
        do {
            let response = try await shadowClient.updateShadow(request: request)
            let shadowStateResponse = response.state!
            let shadowMetaDataResponse = response.metadata!

            print(
                """
                updateShadow response recieved:                
                    state: \(shadowStateResponse.desired!)
                    metadata.desired: \(shadowMetaDataResponse.desired!)
                    timestamp: \(response.timestamp!)
                """)
            print("=======\n")
        } catch {
            logShadowClientError(error)
        }
    }
}
