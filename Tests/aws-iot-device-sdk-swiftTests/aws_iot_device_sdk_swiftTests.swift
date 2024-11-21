import Testing
@testable import aws_iot_device_sdk_swift

import XCTest
import Foundation
import AwsCommonRuntimeKit

enum MqttTestError: Error {
    case timeout
    case connectionFail
    case disconnectFail
    case stopFail
}

class Mqtt5ClientTests: XCBaseTestCase {

    // DEBUG WIP this can be reduced to remove things we don't test at the SDK level
    class MqttTestContext {
        public var contextName: String

        public var onPublishReceived: OnPublishReceived?
        public var onLifecycleEventStopped: OnLifecycleEventStopped?
        public var onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect?
        public var onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess?
        public var onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure?
        public var onLifecycleEventDisconnection: OnLifecycleEventDisconnection?
        public var onWebSocketHandshake: OnWebSocketHandshakeIntercept?

        public let semaphorePublishReceived: DispatchSemaphore
        public let semaphorePublishTargetReached: DispatchSemaphore
        public let semaphoreConnectionSuccess: DispatchSemaphore
        public let semaphoreConnectionFailure: DispatchSemaphore
        public let semaphoreDisconnection: DispatchSemaphore
        public let semaphoreStopped: DispatchSemaphore

        public var negotiatedSettings: NegotiatedSettings?
        public var connackPacket: ConnackPacket?
        public var publishPacket: PublishPacket?
        public var lifecycleConnectionFailureData: LifecycleConnectionFailureData?
        public var lifecycleDisconnectionData: LifecycleDisconnectData?
        public var publishCount = 0
        public var publishTarget = 1

        init(contextName: String = "",
             publishTarget: Int = 1,
             onPublishReceived: OnPublishReceived? = nil,
             onLifecycleEventStopped: OnLifecycleEventStopped? = nil,
             onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect? = nil,
             onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess? = nil,
             onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure? = nil,
             onLifecycleEventDisconnection: OnLifecycleEventDisconnection? = nil) {

            self.contextName = contextName

            self.publishTarget = publishTarget
            self.publishCount = 0

            self.semaphorePublishReceived = DispatchSemaphore(value: 0)
            self.semaphorePublishTargetReached = DispatchSemaphore(value: 0)
            self.semaphoreConnectionSuccess = DispatchSemaphore(value: 0)
            self.semaphoreConnectionFailure = DispatchSemaphore(value: 0)
            self.semaphoreDisconnection = DispatchSemaphore(value: 0)
            self.semaphoreStopped = DispatchSemaphore(value: 0)

            self.onPublishReceived = onPublishReceived
            self.onLifecycleEventStopped = onLifecycleEventStopped
            self.onLifecycleEventAttemptingConnect = onLifecycleEventAttemptingConnect
            self.onLifecycleEventConnectionSuccess = onLifecycleEventConnectionSuccess
            self.onLifecycleEventConnectionFailure = onLifecycleEventConnectionFailure
            self.onLifecycleEventDisconnection = onLifecycleEventDisconnection

            self.onPublishReceived = onPublishReceived ?? { publishData in
                if let payloadString = publishData.publishPacket.payloadAsString() {
                    print(contextName + " Mqtt5ClientTests: onPublishReceived. Topic:\'\(publishData.publishPacket.topic)\' QoS:\(publishData.publishPacket.qos) payload:\'\(payloadString)\'")
                } else {
                    print(contextName + " Mqtt5ClientTests: onPublishReceived. Topic:\'\(publishData.publishPacket.topic)\' QoS:\(publishData.publishPacket.qos)")
                }
                self.publishPacket = publishData.publishPacket
                self.semaphorePublishReceived.signal()
                self.publishCount += 1
                if self.publishCount == self.publishTarget {
                    self.semaphorePublishTargetReached.signal()
                }
            }

            self.onLifecycleEventStopped = onLifecycleEventStopped ?? { _ in
                print(contextName + " Mqtt5ClientTests: onLifecycleEventStopped")
                self.semaphoreStopped.signal()
            }
            self.onLifecycleEventAttemptingConnect = onLifecycleEventAttemptingConnect ?? { _ in
                print(contextName + " Mqtt5ClientTests: onLifecycleEventAttemptingConnect")
            }
            self.onLifecycleEventConnectionSuccess = onLifecycleEventConnectionSuccess ?? { successData in
                print(contextName + " Mqtt5ClientTests: onLifecycleEventConnectionSuccess")
                self.negotiatedSettings = successData.negotiatedSettings
                self.connackPacket = successData.connackPacket
                self.semaphoreConnectionSuccess.signal()
            }
            self.onLifecycleEventConnectionFailure = onLifecycleEventConnectionFailure ?? { failureData in
                print(contextName + " Mqtt5ClientTests: onLifecycleEventConnectionFailure")
                self.lifecycleConnectionFailureData = failureData
                self.semaphoreConnectionFailure.signal()
            }
            self.onLifecycleEventDisconnection = onLifecycleEventDisconnection ?? { disconnectionData in
                print(contextName + " Mqtt5ClientTests: onLifecycleEventDisconnection")
                self.lifecycleDisconnectionData = disconnectionData
                self.semaphoreDisconnection.signal()
            }
         }
    }

    func createClientId() -> String {
        return "aws-iot-device-sdk-swift-unit-test-" + UUID().uuidString
    }

    /// start client and check for connection success
    func connectClient(client: Mqtt5Client, testContext: MqttTestContext) throws -> Void {
        try client.start()
        if testContext.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Success Timed out after 5 seconds")
            XCTFail("Connection Timed Out")
            throw MqttTestError.connectionFail
        }
    }

    /// stop client and check for discconnection and stopped lifecycle events
    func disconnectClientCleanup(client: Mqtt5Client, testContext: MqttTestContext, disconnectPacket: DisconnectPacket? = nil) throws -> Void {
        try client.stop(disconnectPacket: disconnectPacket)

        if testContext.semaphoreDisconnection.wait(timeout: .now() + 5) == .timedOut {
            print("Disconnection timed out after 5 seconds")
            XCTFail("Disconnection timed out")
            throw MqttTestError.disconnectFail
        }

        if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
            print("Stop timed out after 5 seconds")
            XCTFail("Stop timed out")
            throw MqttTestError.stopFail
        }
    }

    /// stop client and check for stopped lifecycle event
    func stopClient(client: Mqtt5Client, testContext: MqttTestContext) throws -> Void {
        try client.stop()
        if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
            print("Stop timed out after 5 seconds")
            XCTFail("Stop timed out")
            throw MqttTestError.stopFail
        }
    }

    func compareEnums<T: Equatable>(arrayOne: [T], arrayTwo: [T]) throws {
        XCTAssertEqual(arrayOne.count, arrayTwo.count, "The arrays do not have the same number of elements")
        for i in 0..<arrayOne.count {
            XCTAssertEqual(arrayOne[i], arrayTwo[i], "The elements at index \(i) are not equal")
        }
    }

    /*===============================================================
                     Builder Test Cases
    =================================================================*/
/*
    func testMqttBuilderMTLSFromFile() throws {
        let certPath = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
        let keyPath = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")
        let endpoint = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")

        let context = MqttTestContext()
        let builder = Mqtt5ClientBuilder()
        let mqttClient = builder.mtlsFromPath(
            certPath: certPath, 
            keyPath: keyPath,
            endpoint: endpoint,
            onPublishReceived: context.onPublishReceived,
            onLifecycleEventConnectionSuccess: context.onLifecycleEventConnectionSuccess,
            onLifecycleEventConnectionFailure: context.onLifecycleEventConnectionFailure,
            onLifecycleEventDisconnection: context.onLifecycleEventDisconnection,
            onLifecycleEventStopped: context.onLifecycleEventStopped)
        
        XCTAssertNotNil(mqttClient)
        try connectClient(client: mqttClient, testContext: context)
        try disconnectClientCleanup(client: mqttClient, testContext: context)
    }

    func testMqttBuilderMTLSFromData() throws {
        let certPath = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
        let keyPath = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")
        let endpoint = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")

        let context = MqttTestContext()
        let builder = Mqtt5ClientBuilder()

        let certFileURL = URL(fileURLWithPath: certPath)
        let certData = try Data(contentsOf: certFileURL)
        
        let keyFileURL = URL(fileURLWithPath: keyPath)
        let keyData = try Data(contentsOf: keyFileURL)

        let mqttClient = builder.mtlsFromData(
            certData: certData, 
            keyData: keyData,
            endpoint: endpoint,
            onPublishReceived: context.onPublishReceived,
            onLifecycleEventConnectionSuccess: context.onLifecycleEventConnectionSuccess,
            onLifecycleEventConnectionFailure: context.onLifecycleEventConnectionFailure,
            onLifecycleEventDisconnection: context.onLifecycleEventDisconnection,
            onLifecycleEventStopped: context.onLifecycleEventStopped)
        
        XCTAssertNotNil(mqttClient)
        try connectClient(client: mqttClient, testContext: context)
        try disconnectClientCleanup(client: mqttClient, testContext: context)
    }

    func testMqttBuilderMTLSFromPKCS12() throws {
        let pkcs12Path = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_PKCS12_FILE")
        let pkcs12Password = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_PKCS12_PASSWORD")
        let endpoint = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")

        let context = MqttTestContext()
        let builder = Mqtt5ClientBuilder()

        let mqttClient = builder.mtlsFromPKCS12(
            pkcs12Path: pkcs12Path, 
            pkcs12Password: pkcs12Password,
            endpoint: endpoint,
            onPublishReceived: context.onPublishReceived,
            onLifecycleEventConnectionSuccess: context.onLifecycleEventConnectionSuccess,
            onLifecycleEventConnectionFailure: context.onLifecycleEventConnectionFailure,
            onLifecycleEventDisconnection: context.onLifecycleEventDisconnection,
            onLifecycleEventStopped: context.onLifecycleEventStopped)
        
        XCTAssertNotNil(mqttClient)
        try connectClient(client: mqttClient, testContext: context)
        try disconnectClientCleanup(client: mqttClient, testContext: context)
    }

    func testMqttDirectConnect() async throws {
        let context = MqttTestContext()
        let ConnectPacket = MqttConnectOptions(keepAliveInterval: 60, clientId: createClientId())
        let clientOptions = MqttClientOptions(
                hostName: "localhost",
                port: 1883,
                connectOptions: ConnectPacket,
                connackTimeout: TimeInterval(10),
        onPublishReceivedFn: context.onPublishReceived,
        onLifecycleEventStoppedFn: context.onLifecycleEventStopped,
        onLifecycleEventAttemptingConnectFn: context.onLifecycleEventAttemptingConnect,
        onLifecycleEventConnectionSuccessFn: context.onLifecycleEventConnectionSuccess,
        onLifecycleEventConnectionFailureFn: context.onLifecycleEventConnectionFailure,
        onLifecycleEventDisconnectionFn: context.onLifecycleEventDisconnection)

        let mqttClient = try Mqtt5Client(clientOptions: clientOptions)
        try connectClient(client: mqttClient, testContext: context)

        let topic = "test/MQTT5_Binding_Swift_" + UUID().uuidString
        let subscribePacket = SubscribePacket(topicFilter: topic, qos: QoS.atLeastOnce, noLocal: false)
        let subackPacket: SubackPacket = try await mqttClient.subscribe(subscribePacket: subscribePacket)
        print("SubackPacket received with result \(subackPacket.reasonCodes[0])")

        let publishPacket = PublishPacket(qos: QoS.atLeastOnce, topic: topic, payload: "Hello World".data(using: .utf8))
        let publishResult: PublishResult =
                try await mqttClient.publish(publishPacket: publishPacket)
        if let puback = publishResult.puback {
            print("PubackPacket received with result \(puback.reasonCode)")
        } else {
            XCTFail("PublishResult missing.")
            return
        }

        try disconnectClientCleanup(client: mqttClient, testContext: context)
    }
    */
}
