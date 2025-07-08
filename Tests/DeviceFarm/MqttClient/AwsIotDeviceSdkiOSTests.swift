import AwsCommonRuntimeKit
import Foundation
import XCTest

@testable import AwsIotDeviceSdkSwift

enum MqttTestError: Error {
  case timeout
  case connectionFail
  case disconnectFail
  case stopFail
  case resourceMissing
}

class Mqtt5IOSTests: XCBaseTestCase {

  var isIOSDeviceFarm = true

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

  func testMqttBuilderMTLSFromPath() throws {

    let certPath, keyPath, endpoint: String

    if (!isIOSDeviceFarm) {
      try skipIfPlatformDoesntSupportTLS()
      certPath = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
      keyPath = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")
      endpoint = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
    } else {
      guard let certURL = Bundle.main.url(forResource: "cert", withExtension: "pem"),
        let keyURL = Bundle.main.url(forResource: "privatekey", withExtension: "pem")
      else {
        XCTFail("Missing cert or key resource.")
        throw MqttTestError.resourceMissing
      }

      certPath = certURL.relativePath
      keyPath = keyURL.relativePath
      endpoint = "<AWS_TEST_MQTT5_IOT_CORE_HOST>"

    }
    let context = MqttTestContext(contextName: "MTLSFromPath")
    let builder = try Mqtt5ClientBuilder.mtlsFromPath(
      certPath: certPath, keyPath: keyPath, endpoint: endpoint)

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

  func testMqttBuilderMTLSFromData() throws {

    let certFileURL, keyFileURL: URL
    let endpoint: String

    if (!isIOSDeviceFarm) {
      try skipIfPlatformDoesntSupportTLS()
      let certPath = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
      let keyPath = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")
      endpoint = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")

      certFileURL = URL(fileURLWithPath: certPath)
      keyFileURL = URL(fileURLWithPath: keyPath)
    } else {
      guard let _certFileURL = Bundle.main.url(forResource: "cert", withExtension: "pem"),
        let _keyFileURL = Bundle.main.url(forResource: "privatekey", withExtension: "pem")
      else {
        XCTFail("Missing cert or key resource.")
        throw MqttTestError.resourceMissing
      }
      certFileURL = _certFileURL
      keyFileURL = _keyFileURL
      endpoint = "<AWS_TEST_MQTT5_IOT_CORE_HOST>"
    }

    let context = MqttTestContext(contextName: "MTLSFromData")

    let certData = try Data(contentsOf: certFileURL)
    let keyData = try Data(contentsOf: keyFileURL)
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

  func testMqttBuilderMTLSFromPKCS12() throws {

    let pkcs12Path, pkcs12Password, endpoint: String

    if (!isIOSDeviceFarm) {
      try skipIfLinux()
      pkcs12Path = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_PKCS12_FILE")
      pkcs12Password = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_PKCS12_PASSWORD")
      endpoint = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
    } else {

      guard let pkcs12URL = Bundle.main.url(forResource: "pkcs12", withExtension: "p12")
      else {
        XCTFail("Missing pkcs12 resource.")
        throw MqttTestError.resourceMissing
      }

      pkcs12Path = pkcs12URL.relativePath
      pkcs12Password = "<AWS_TEST_MQTT5_PKCS12_PASSWORD>"
      endpoint = "<AWS_TEST_MQTT5_IOT_CORE_HOST>"
    }

    let context = MqttTestContext(contextName: "MTLSFromPKCS12")
    let builder = try Mqtt5ClientBuilder.mtlsFromPKCS12(
      pkcs12Path: pkcs12Path, pkcs12Password: pkcs12Password, endpoint: endpoint)

    builder.withCallbacks(
      onPublishReceived: context.onPublishReceived,
      onLifecycleEventConnectionSuccess: context.onLifecycleEventConnectionSuccess,
      onLifecycleEventConnectionFailure: context.onLifecycleEventConnectionFailure,
      onLifecycleEventDisconnection: context.onLifecycleEventDisconnection,
      onLifecycleEventStopped: context.onLifecycleEventStopped)

    builder.withClientId(createClientId())

    let mqttClient = try builder.build()

    XCTAssertNotNil(mqttClient)
    try connectClient(client: mqttClient, testContext: context)
    try disconnectClientCleanup(client: mqttClient, testContext: context)
  }

  func testMqttWebsocketWithDefaultAWSSigning() async throws {
    let region, endpoint, accessKey, secret, sessionToken: String

    if (!isIOSDeviceFarm) {
      region = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_WS_REGION")
      endpoint = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")

      // setup role credentials
      accessKey = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_ROLE_CREDENTIAL_ACCESS_KEY")
      secret = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_ROLE_CREDENTIAL_SECRET_ACCESS_KEY")
      sessionToken = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_ROLE_CREDENTIAL_SESSION_TOKEN")
    } else {
      region = "us-east-1"
      endpoint = "<AWS_TEST_MQTT5_IOT_CORE_HOST>"

      // setup role credentials
      accessKey = "<AWS_TEST_MQTT5_ROLE_CREDENTIAL_ACCESS_KEY>"
      secret = "<AWS_TEST_MQTT5_ROLE_CREDENTIAL_SECRET_ACCESS_KEY>"
      sessionToken = "<AWS_TEST_MQTT5_ROLE_CREDENTIAL_SESSION_TOKEN>"
    }

    let context = MqttTestContext(contextName: "WebsocketWithDefaultAWSSigning")
    let provider = try CredentialsProvider(
      source: .static(
        accessKey: accessKey,
        secret: secret,
        sessionToken: sessionToken))

    // if Env Variables AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_SESSION_TOKEN
    // are set, provider can be created without providing a static source like this below.
    /*
    let elg = try EventLoopGroup()
    let resolver = try HostResolver(eventLoopGroup: elg, maxHosts: 16, maxTTL: 30)
    let clientBootstrap = try ClientBootstrap(
        eventLoopGroup: elg,
        hostResolver: resolver)
    
    let provider = try CredentialsProvider(source: .defaultChain(
        bootstrap: clientBootstrap,
        fileBasedConfiguration: FileBasedConfiguration()))
    */

    let builder = try Mqtt5ClientBuilder.websocketsWithDefaultAwsSigning(
      endpoint: endpoint,
      region: region,
      credentialsProvider: provider)

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

  func testMqttWebsocketWithCustomAuth() async throws {
    let endpoint, customAuthName, customAuthPassword: String

    if (!isIOSDeviceFarm) {

      endpoint = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
      customAuthName = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_CUSTOM_AUTHORIZER_NAME")
      customAuthPassword = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_CUSTOM_AUTHORIZER_PASSWORD")

    } else {
      endpoint = "<AWS_TEST_MQTT5_IOT_CORE_HOST>"
      customAuthName = "<AWS_TEST_CUSTOM_AUTHORIZER_NAME>"
      customAuthPassword = "<AWS_TEST_CUSTOM_AUTHORIZER_PASSWORD>"
    }

    let context = MqttTestContext(contextName: "WebsocketWithCustomAuth")
    let builder = try Mqtt5ClientBuilder.websocketsWithCustomAuthorizer(
      endpoint: endpoint,
      authAuthorizerName: customAuthName,
      authPassword: customAuthPassword.data(using: .utf8)!,
      authUsername: "Derpo")

    builder.withCallbacks(
      onPublishReceived: context.onPublishReceived,
      onLifecycleEventConnectionSuccess: context.onLifecycleEventConnectionSuccess,
      onLifecycleEventConnectionFailure: context.onLifecycleEventConnectionFailure,
      onLifecycleEventDisconnection: context.onLifecycleEventDisconnection,
      onLifecycleEventStopped: context.onLifecycleEventStopped)

    builder.withClientId(createClientId())

    let mqttClient = try builder.build()

    XCTAssertNotNil(mqttClient)
    try connectClient(client: mqttClient, testContext: context)
    try disconnectClientCleanup(client: mqttClient, testContext: context)
  }

  func testMqttWebsocketWithUnignedCustomAuth() async throws {
    let endpoint, customAuthUsername, customAuthName, customAuthPassword, authTokenValue,
      authTokenKeyName: String

    if (!isIOSDeviceFarm) {

      endpoint = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
      customAuthUsername = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_NO_SIGNING_AUTHORIZER_USERNAME")
      customAuthName = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_NO_SIGNING_AUTHORIZER_NAME")
      customAuthPassword = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_NO_SIGNING_AUTHORIZER_PASSWORD")
      authTokenValue = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN")
      authTokenKeyName = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_KEY_NAME")
    } else {
      endpoint = "<AWS_TEST_MQTT5_IOT_CORE_HOST>"
      customAuthUsername = "<AWS_TEST_MQTT5_IOT_CORE_NO_SIGNING_AUTHORIZER_USERNAME>"
      customAuthName = "<AWS_TEST_MQTT5_IOT_CORE_NO_SIGNING_AUTHORIZER_NAME>"
      customAuthPassword = "<AWS_TEST_MQTT5_IOT_CORE_NO_SIGNING_AUTHORIZER_PASSWORD>"
      authTokenValue = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN>"
      authTokenKeyName = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_KEY_NAME>"
    }
    let context = MqttTestContext(contextName: "WebsocketWithUnignedCustomAuth")
    let builder = try Mqtt5ClientBuilder.websocketsWithUnsignedCustomAuthorizer(
      endpoint: endpoint,
      authAuthorizerName: customAuthName,
      authPassword: customAuthPassword.data(using: .utf8),
      authTokenKeyName: authTokenKeyName,
      authTokenValue: authTokenValue,
      authUsername: customAuthUsername)

    builder.withCallbacks(
      onPublishReceived: context.onPublishReceived,
      onLifecycleEventConnectionSuccess: context.onLifecycleEventConnectionSuccess,
      onLifecycleEventConnectionFailure: context.onLifecycleEventConnectionFailure,
      onLifecycleEventDisconnection: context.onLifecycleEventDisconnection,
      onLifecycleEventStopped: context.onLifecycleEventStopped)

    builder.withClientId(createClientId())

    let mqttClient = try builder.build()

    XCTAssertNotNil(mqttClient)
    try connectClient(client: mqttClient, testContext: context)
    try disconnectClientCleanup(client: mqttClient, testContext: context)
  }

  func testMqttWebsocketWithSignedCustomAuth() async throws {
    let endpoint, customAuthUsername, customAuthName, customAuthPassword, authTokenValue,
      authTokenKeyName, authAuthorizerSignature: String

    if !isIOSDeviceFarm {
      endpoint = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
      customAuthUsername = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_USERNAME")
      customAuthName = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_NAME")
      customAuthPassword = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_PASSWORD")
      authTokenValue = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN")
      authTokenKeyName = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_KEY_NAME")
      authAuthorizerSignature = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_SIGNATURE")
    } else {
      endpoint = "<AWS_TEST_MQTT5_IOT_CORE_HOST>"
      customAuthUsername = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_USERNAME>"
      customAuthName = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_NAME>"
      customAuthPassword = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_PASSWORD>"
      authTokenValue = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN>"
      authTokenKeyName = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_KEY_NAME>"
      authAuthorizerSignature = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_SIGNATURE>"
    }

    let context = MqttTestContext(contextName: "WebsocketWithSignedCustomAuth")
    let builder = try Mqtt5ClientBuilder.websocketsWithSignedCustomAuthorizer(
      endpoint: endpoint,
      authAuthorizerName: customAuthName,
      authPassword: customAuthPassword.data(using: .utf8),
      authAuthorizerSignature: authAuthorizerSignature,
      authTokenKeyName: authTokenKeyName,
      authTokenValue: authTokenValue,
      authUsername: customAuthUsername)

    builder.withCallbacks(
      onPublishReceived: context.onPublishReceived,
      onLifecycleEventConnectionSuccess: context.onLifecycleEventConnectionSuccess,
      onLifecycleEventConnectionFailure: context.onLifecycleEventConnectionFailure,
      onLifecycleEventDisconnection: context.onLifecycleEventDisconnection,
      onLifecycleEventStopped: context.onLifecycleEventStopped)

    builder.withClientId(createClientId())

    let mqttClient = try builder.build()

    XCTAssertNotNil(mqttClient)
    try connectClient(client: mqttClient, testContext: context)
    try disconnectClientCleanup(client: mqttClient, testContext: context)
  }

  func testMqttWebsocketWithUnencodedSignedCustomAuth() async throws {
    let endpoint, customAuthUsername, customAuthName, customAuthPassword, authTokenValue,
      authTokenKeyName, authAuthorizerSignature: String

    if !isIOSDeviceFarm {
      endpoint = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
      customAuthUsername = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_USERNAME")
      customAuthName = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_NAME")
      customAuthPassword = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_PASSWORD")
      authTokenValue = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN")
      authTokenKeyName = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_KEY_NAME")
      authAuthorizerSignature = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_SIGNATURE_UNENCODED")
    } else {
      endpoint = "<AWS_TEST_MQTT5_IOT_CORE_HOST>"
      customAuthUsername = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_USERNAME>"
      customAuthName = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_NAME>"
      customAuthPassword = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_PASSWORD>"
      authTokenValue = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN>"
      authTokenKeyName = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_KEY_NAME>"
      authAuthorizerSignature =
        "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_SIGNATURE_UNENCODED>"
    }

    let context = MqttTestContext(contextName: "WebsocketWithUnencodedSignedCustomAuth")
    let builder = try Mqtt5ClientBuilder.websocketsWithSignedCustomAuthorizer(
      endpoint: endpoint,
      authAuthorizerName: customAuthName,
      authPassword: customAuthPassword.data(using: .utf8),
      authAuthorizerSignature: authAuthorizerSignature,
      authTokenKeyName: authTokenKeyName,
      authTokenValue: authTokenValue,
      authUsername: customAuthUsername)

    builder.withCallbacks(
      onPublishReceived: context.onPublishReceived,
      onLifecycleEventConnectionSuccess: context.onLifecycleEventConnectionSuccess,
      onLifecycleEventConnectionFailure: context.onLifecycleEventConnectionFailure,
      onLifecycleEventDisconnection: context.onLifecycleEventDisconnection,
      onLifecycleEventStopped: context.onLifecycleEventStopped)

    builder.withClientId(createClientId())

    let mqttClient = try builder.build()

    XCTAssertNotNil(mqttClient)
    try connectClient(client: mqttClient, testContext: context)
    try disconnectClientCleanup(client: mqttClient, testContext: context)
  }

  func testMqttWebsocketWithCognitoCredentialProvider() async throws {
    let iotEndpoint, region, cognitoEndpoint, cognitoIdentity: String

    if !isIOSDeviceFarm {
      iotEndpoint = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
      region = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_REGION")
      cognitoEndpoint = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_COGNITO_ENDPOINT")
      cognitoIdentity = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_COGNITO_IDENTITY")
    } else {
      iotEndpoint = "<AWS_TEST_MQTT5_IOT_CORE_HOST>"
      region = "us-east-1"
      cognitoEndpoint = "cognito-identity.us-east-1.amazonaws.com"
      cognitoIdentity = "<AWS_TEST_MQTT5_COGNITO_IDENTITY>"
    }

    let context = MqttTestContext(contextName: "WebsocketWithCognitoCredentialProvider")
    let elg = try EventLoopGroup()
    let resolver = try HostResolver(eventLoopGroup: elg, maxHosts: 16, maxTTL: 30)
    let clientBootstrap = try ClientBootstrap(
      eventLoopGroup: elg,
      hostResolver: resolver)

    let options = TLSContextOptions.makeDefault()
    let tlscontext = try TLSContext(options: options, mode: .client)

    let cognitoProvider = try CredentialsProvider(
      source: .cognito(
        bootstrap: clientBootstrap, tlsContext: tlscontext, endpoint: cognitoEndpoint,
        identity: cognitoIdentity))

    let builder = try Mqtt5ClientBuilder.websocketsWithDefaultAwsSigning(
      endpoint: iotEndpoint, region: region, credentialsProvider: cognitoProvider)

    builder.withCallbacks(
      onPublishReceived: context.onPublishReceived,
      onLifecycleEventConnectionSuccess: context.onLifecycleEventConnectionSuccess,
      onLifecycleEventConnectionFailure: context.onLifecycleEventConnectionFailure,
      onLifecycleEventDisconnection: context.onLifecycleEventDisconnection,
      onLifecycleEventStopped: context.onLifecycleEventStopped)

    builder.withClientId(createClientId())

    let mqttClient = try builder.build()

    XCTAssertNotNil(mqttClient)
    try connectClient(client: mqttClient, testContext: context)
    try disconnectClientCleanup(client: mqttClient, testContext: context)
  }

  func testMqttDirectWithUnsignedCustomAuth() async throws {
    let endpoint, customAuthUsername, customAuthName, customAuthPassword: String

    if !isIOSDeviceFarm {
      endpoint = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
      customAuthUsername = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_NO_SIGNING_AUTHORIZER_USERNAME")
      customAuthName = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_NO_SIGNING_AUTHORIZER_NAME")
      customAuthPassword = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_NO_SIGNING_AUTHORIZER_PASSWORD")
    } else {
      endpoint = "<AWS_TEST_MQTT5_IOT_CORE_HOST>"
      customAuthUsername = "<AWS_TEST_MQTT5_IOT_CORE_NO_SIGNING_AUTHORIZER_USERNAME>"
      customAuthName = "<AWS_TEST_MQTT5_IOT_CORE_NO_SIGNING_AUTHORIZER_NAME>"
      customAuthPassword = "<AWS_TEST_MQTT5_IOT_CORE_NO_SIGNING_AUTHORIZER_PASSWORD>"
    }

    let context = MqttTestContext(contextName: "DirectWithUnsignedCustomAuth")
    let builder = try Mqtt5ClientBuilder.directWithUnsignedCustomAuthorizer(
      endpoint: endpoint,
      authAuthorizerName: customAuthName,
      authPassword: customAuthPassword.data(using: .utf8),
      authUsername: customAuthUsername)

    builder.withCallbacks(
      onPublishReceived: context.onPublishReceived,
      onLifecycleEventConnectionSuccess: context.onLifecycleEventConnectionSuccess,
      onLifecycleEventConnectionFailure: context.onLifecycleEventConnectionFailure,
      onLifecycleEventDisconnection: context.onLifecycleEventDisconnection,
      onLifecycleEventStopped: context.onLifecycleEventStopped)

    builder.withClientId(createClientId())

    let mqttClient = try builder.build()

    XCTAssertNotNil(mqttClient)
    try connectClient(client: mqttClient, testContext: context)
    try disconnectClientCleanup(client: mqttClient, testContext: context)
  }

  func testMqttDirectWithSignedCustomAuth() async throws {
    let endpoint, customAuthUsername, customAuthName, customAuthPassword, authTokenValue,
      authTokenKeyName, authAuthorizerSignature: String

    if !isIOSDeviceFarm {
      endpoint = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
      customAuthUsername = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_USERNAME")
      customAuthName = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_NAME")
      customAuthPassword = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_PASSWORD")
      authTokenValue = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN")
      authTokenKeyName = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_KEY_NAME")
      authAuthorizerSignature = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_SIGNATURE")
    } else {
      endpoint = "<AWS_TEST_MQTT5_IOT_CORE_HOST>"
      customAuthUsername = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_USERNAME>"
      customAuthName = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_NAME>"
      customAuthPassword = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_PASSWORD>"
      authTokenValue = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN>"
      authTokenKeyName = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_KEY_NAME>"
      authAuthorizerSignature = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_SIGNATURE>"
    }

    let context = MqttTestContext(contextName: "DirectWithSignedCustomAuth")
    let builder = try Mqtt5ClientBuilder.directWithSignedCustomAuthorizer(
      endpoint: endpoint,
      authAuthorizerName: customAuthName,
      authAuthorizerSignature: authAuthorizerSignature,
      authTokenKeyName: authTokenKeyName,
      authTokenValue: authTokenValue,
      authUsername: customAuthUsername,
      authPassword: customAuthPassword.data(using: .utf8)!)

    builder.withCallbacks(
      onPublishReceived: context.onPublishReceived,
      onLifecycleEventConnectionSuccess: context.onLifecycleEventConnectionSuccess,
      onLifecycleEventConnectionFailure: context.onLifecycleEventConnectionFailure,
      onLifecycleEventDisconnection: context.onLifecycleEventDisconnection,
      onLifecycleEventStopped: context.onLifecycleEventStopped)

    builder.withClientId("createClientId()")

    let mqttClient = try builder.build()

    XCTAssertNotNil(mqttClient)
    try connectClient(client: mqttClient, testContext: context)
    try disconnectClientCleanup(client: mqttClient, testContext: context)
  }

  func testMqttDirectWithUnencodedSignedCustomAuth() async throws {
    let endpoint, customAuthUsername, customAuthName, customAuthPassword, authTokenValue,
      authTokenKeyName, authAuthorizerSignature: String

    if !isIOSDeviceFarm {
      endpoint = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
      customAuthUsername = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_USERNAME")
      customAuthName = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_NAME")
      customAuthPassword = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_PASSWORD")
      authTokenValue = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN")
      authTokenKeyName = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_KEY_NAME")
      authAuthorizerSignature = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_SIGNATURE_UNENCODED")
    } else {
      endpoint = "<AWS_TEST_MQTT5_IOT_CORE_HOST>"
      customAuthUsername = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_USERNAME>"
      customAuthName = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_NAME>"
      customAuthPassword = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_PASSWORD>"
      authTokenValue = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN>"
      authTokenKeyName = "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_KEY_NAME>"
      authAuthorizerSignature =
        "<AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_SIGNATURE_UNENCODED>"
    }

    let context = MqttTestContext(contextName: "DirectWithSignedCustomAuth")
    let builder = try Mqtt5ClientBuilder.directWithSignedCustomAuthorizer(
      endpoint: endpoint,
      authAuthorizerName: customAuthName,
      authAuthorizerSignature: authAuthorizerSignature,
      authTokenKeyName: authTokenKeyName,
      authTokenValue: authTokenValue,
      authUsername: customAuthUsername,
      authPassword: customAuthPassword.data(using: .utf8)!)

    builder.withCallbacks(
      onPublishReceived: context.onPublishReceived,
      onLifecycleEventConnectionSuccess: context.onLifecycleEventConnectionSuccess,
      onLifecycleEventConnectionFailure: context.onLifecycleEventConnectionFailure,
      onLifecycleEventDisconnection: context.onLifecycleEventDisconnection,
      onLifecycleEventStopped: context.onLifecycleEventStopped)

    builder.withClientId("createClientId()")

    let mqttClient = try builder.build()

    XCTAssertNotNil(mqttClient)
    try connectClient(client: mqttClient, testContext: context)
    try disconnectClientCleanup(client: mqttClient, testContext: context)
  }
}
