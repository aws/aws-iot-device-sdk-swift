import AwsCommonRuntimeKit
import Foundation
import XCTest

@testable import AwsIotDeviceSdkSwift

enum MqttTestError: Error {
  case timeout
  case connectionFail
  case disconnectFail
  case stopFail
}

class Mqtt5iOSTest: XCBaseTestCase {

  // DEBUG WIP this can be reduced to remove things we don't test at the SDK level
  final class MqttTestContext: @unchecked Sendable {
    public let contextName: String

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

    init(
      contextName: String? = nil,
      publishTarget: Int = 1,
      onPublishReceived: OnPublishReceived? = nil,
      onLifecycleEventStopped: OnLifecycleEventStopped? = nil,
      onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect? = nil,
      onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess? = nil,
      onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure? = nil,
      onLifecycleEventDisconnection: OnLifecycleEventDisconnection? = nil
    ) {

      if contextName != nil {
        self.contextName = contextName! + " "
      } else {
        self.contextName = ""
      }

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

      self.onPublishReceived =
        onPublishReceived ?? { publishData in
          if let payloadString = publishData.publishPacket.payloadAsString() {
            print(
              self.contextName
                + "Mqtt5Client: onPublishReceived. Topic:\'\(publishData.publishPacket.topic)\' QoS:\(publishData.publishPacket.qos) payload:\'\(payloadString)\'"
            )
          } else {
            print(
              self.contextName
                + "Mqtt5Client: onPublishReceived. Topic:\'\(publishData.publishPacket.topic)\' QoS:\(publishData.publishPacket.qos)"
            )
          }
          self.publishPacket = publishData.publishPacket
          self.semaphorePublishReceived.signal()
          self.publishCount += 1
          if self.publishCount == self.publishTarget {
            self.semaphorePublishTargetReached.signal()
          }
        }

      self.onLifecycleEventStopped =
        onLifecycleEventStopped ?? { _ in
          print(self.contextName + "Mqtt5Client: onLifecycleEventStopped")
          self.semaphoreStopped.signal()
        }
      self.onLifecycleEventAttemptingConnect =
        onLifecycleEventAttemptingConnect ?? { _ in
          print(self.contextName + "Mqtt5Client: onLifecycleEventAttemptingConnect")
        }
      self.onLifecycleEventConnectionSuccess =
        onLifecycleEventConnectionSuccess ?? { successData in
          print(self.contextName + "Mqtt5Client: onLifecycleEventConnectionSuccess")
          self.negotiatedSettings = successData.negotiatedSettings
          self.connackPacket = successData.connackPacket
          self.semaphoreConnectionSuccess.signal()
        }
      self.onLifecycleEventConnectionFailure =
        onLifecycleEventConnectionFailure ?? { failureData in
          print(self.contextName + "Mqtt5Client: onLifecycleEventConnectionFailure")
          self.lifecycleConnectionFailureData = failureData
          self.semaphoreConnectionFailure.signal()
        }
      self.onLifecycleEventDisconnection =
        onLifecycleEventDisconnection ?? { disconnectionData in
          print(self.contextName + "Mqtt5Client: onLifecycleEventDisconnection")
          self.lifecycleDisconnectionData = disconnectionData
          self.semaphoreDisconnection.signal()
        }
    }
  }

  func createClientId() -> String {
    return "test-iot-device-sdk-swift-" + UUID().uuidString
  }

  /// start client and check for connection success
  func connectClient(client: Mqtt5Client, testContext: MqttTestContext) throws {
    try client.start()
    if testContext.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
      print("Connection Success Timed out after 5 seconds")
      XCTFail("Connection Timed Out")
      throw MqttTestError.connectionFail
    }
  }

  /// stop client and check for discconnection and stopped lifecycle events
  func disconnectClientCleanup(
    client: Mqtt5Client, testContext: MqttTestContext, disconnectPacket: DisconnectPacket? = nil
  ) throws {
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
  func stopClient(client: Mqtt5Client, testContext: MqttTestContext) throws {
    try client.stop()
    if testContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
      print("Stop timed out after 5 seconds")
      XCTFail("Stop timed out")
      throw MqttTestError.stopFail
    }
  }

  func compareEnums<T: Equatable>(arrayOne: [T], arrayTwo: [T]) throws {
    XCTAssertEqual(
      arrayOne.count, arrayTwo.count, "The arrays do not have the same number of elements")
    for i in 0..<arrayOne.count {
      XCTAssertEqual(arrayOne[i], arrayTwo[i], "The elements at index \(i) are not equal")
    }
  }

  /*===============================================================
                   Builder Test Cases
  =================================================================*/

  func testMqttBuilderMTLSFromBundleFile() throws {
    guard let certURL = Bundle.main.url(forResource: "cert", withExtension: "pem"),
      let keyURL = Bundle.main.url(forResource: "privatekey", withExtension: "pem")
    else {
      fatalError("Missing cert or key resource.")
    }

    let certData = try Data(contentsOf: certURL)
    let keyData = try Data(contentsOf: keyURL)
    let endpoint = try getEnvironmentVarOrSkipTest(
      environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
    let context = MqttTestContext(contextName: "MTLSFromBundleFile")

    let builder = try Mqtt5ClientBuilder.mtlsFromData(
      certData: certData, keyData: keyData, endpoint: endpoint)

    builder.withCallbacks(
      onPublishReceived: context.onPublishReceived,
      onLifecycleEventConnectionSuccess: context.onLifecycleEventConnectionSuccess,
      onLifecycleEventConnectionFailure: context.onLifecycleEventConnectionFailure,
      onLifecycleEventDisconnection: context.onLifecycleEventDisconnection,
      onLifecycleEventStopped: context.onLifecycleEventStopped)

    let mqttClient = try builder.build()

    XCTAssertNotNil(mqttClient)
    try connectClient(client: mqttClient, testContext: context)
    try disconnectClientCleanup(client: mqttClient, testContext: context)
  }
}
