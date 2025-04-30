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

    func testShadowClient() async throws {
        ////////////////////////////////////////////////////////////
        /// Initialize working mqtt client
        ////////////////////////////////////////////////////////////
        // Create an expectation for the connection.
        let connectionExpectation = expectation(description: "Connection Success")

        let onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess = { successData in
            print("Mqtt5Client: onLifecycleEventConnectionSuccess")
            connectionExpectation.fulfill()
        }
        let certPath = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
        let keyPath = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")
        let endpoint = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let builder = try Mqtt5ClientBuilder.mtlsFromPath(
            certPath: certPath, keyPath: keyPath, endpoint: endpoint)
        builder.withOnLifecycleEventConnectionSuccess(onLifecycleEventConnectionSuccess)
        let mqttClient = try builder.build()
        XCTAssertNotNil(mqttClient)

        ////////////////////////////////////////////////////////////
        /// Start the mqttClient
        ////////////////////////////////////////////////////////////
        try mqttClient.start()
        // Await the expectation being fulfilled with a timeout.
        await fulfillment(of: [connectionExpectation], timeout: 5, enforceOrder: false)

        ////////////////////////////////////////////////////////////
        // Create fake rrClient for use to establish shadowClient
        ////////////////////////////////////////////////////////////
        let rrClient = AwsIotDeviceSdkSwift.MqttRequestResponseClient(mqttClient: mqttClient)
        XCTAssertNotNil(rrClient)
        let shadowClient = try IotShadowClient(rrClient: rrClient)
        XCTAssertNotNil(shadowClient)

        try await runTestStructureOperations(shadowClient: shadowClient)

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

    private func runTestStructureOperations(shadowClient: IotShadowClient) async throws {
        print("\n=======\n")
        print("runTestStructureOperations()")

        let testData: Data = Data(repeating: 8, count: 20)
        let testTimestamp = Date(timeIntervalSinceNow: TimeInterval(21321))

        let testStructureData: TestStructureData = TestStructureData(
            thingName: "Thing Name", shadowName: "ShadowName")
        testStructureData.withTestBigDecimal(testBigDecimal: 999)
        testStructureData.withTestBigInteger(testBigInteger: 9999)
        testStructureData.withTestBlob(testBlob: testData)
        testStructureData.withTestBoolean(testBoolean: true)
        testStructureData.withTestByte(testByte: 1)
        testStructureData.withTestDocument(testDocument: ["Title": "Document contents"])
        testStructureData.withTestDouble(testDouble: 1212)
        testStructureData.withTestFloat(testFloat: 123.456)
        testStructureData.withTestInteger(testInteger: 42)
        testStructureData.withTestLong(testLong: 44_442_222)
        testStructureData.withTestShort(testShort: 2)
        testStructureData.withTestString(testString: "TEST STRING")
        testStructureData.withTestTimestamp(testTimestamp: testTimestamp)
        testStructureData.withTestEnum(testEnum: .FIRST)

        print("\n======= TEST Request Response =======")
        let response: MqttRequestResponseResponse =
            try await shadowClient.testRequestResponseOperation(
                request: testStructureData)

        // Try decoding the encoded JSON Data
        let decoder: JSONDecoder = JSONDecoder()
        let _: TestStructureData = try decoder.decode(
            TestStructureData.self, from: response.payload)

        print("\n======= TEST Streaming =======")
        let _ = try await shadowClient.testStreamingOperation(request: testStructureData)
    }
}
