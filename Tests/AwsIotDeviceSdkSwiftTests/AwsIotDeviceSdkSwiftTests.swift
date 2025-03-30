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
        let certPath = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
        let keyPath = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")
        let endpoint = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")

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
        let certPath = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
        let keyPath = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")
        let endpoint = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")

        let context = MqttTestContext(contextName: "MTLSFromData")

        let certFileURL = URL(fileURLWithPath: certPath)
        let certData = try Data(contentsOf: certFileURL)

        let keyFileURL = URL(fileURLWithPath: keyPath)
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
        let pkcs12Path = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_PKCS12_FILE")
        let pkcs12Password = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_PKCS12_PASSWORD")
        let endpoint = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")

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
        let region = try getEnvironmentVarOrSkipTest(environmentVarName: "AWS_TEST_MQTT5_WS_REGION")
        let endpoint = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")

        // setup role credentials
        let accessKey = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_ROLE_CREDENTIAL_ACCESS_KEY")
        let secret = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_ROLE_CREDENTIAL_SECRET_ACCESS_KEY")
        let sessionToken = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_ROLE_CREDENTIAL_SESSION_TOKEN")

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
        let endpoint = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let customAuthName = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_CUSTOM_AUTHORIZER_NAME")
        let customAuthPassword = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_CUSTOM_AUTHORIZER_PASSWORD")
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
        let endpoint = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let customAuthUsername = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_NO_SIGNING_AUTHORIZER_USERNAME")
        let customAuthName = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_NO_SIGNING_AUTHORIZER_NAME")
        let customAuthPassword = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_NO_SIGNING_AUTHORIZER_PASSWORD")
        let authTokenValue = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN")
        let authTokenKeyName = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_KEY_NAME")
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
        let endpoint = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let customAuthUsername = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_USERNAME")
        let customAuthName = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_NAME")
        let customAuthPassword = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_PASSWORD")
        let authTokenValue = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN")
        let authTokenKeyName = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_KEY_NAME")
        let authAuthorizerSignature = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_SIGNATURE")
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
        let endpoint = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let customAuthUsername = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_USERNAME")
        let customAuthName = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_NAME")
        let customAuthPassword = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_PASSWORD")
        let authTokenValue = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN")
        let authTokenKeyName = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_KEY_NAME")
        let authAuthorizerSignature = try getEnvironmentVarOrSkipTest(
            environmentVarName:
                "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_SIGNATURE_UNENCODED")
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
        let iotEndpoint = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let region = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_REGION")
        let cognitoEndpoint = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_COGNITO_ENDPOINT")
        let cognitoIdentity = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_COGNITO_IDENTITY")
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
        let endpoint = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let customAuthUsername = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_NO_SIGNING_AUTHORIZER_USERNAME")
        let customAuthName = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_NO_SIGNING_AUTHORIZER_NAME")
        let customAuthPassword = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_NO_SIGNING_AUTHORIZER_PASSWORD")
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
        let endpoint = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let customAuthUsername = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_USERNAME")
        let customAuthName = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_NAME")
        let customAuthPassword = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_PASSWORD")
        let authTokenValue = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN")
        let authTokenKeyName = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_KEY_NAME")
        let authAuthorizerSignature = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_SIGNATURE")
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
        let endpoint = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")
        let customAuthUsername = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_USERNAME")
        let customAuthName = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_NAME")
        let customAuthPassword = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_PASSWORD")
        let authTokenValue = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN")
        let authTokenKeyName = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_KEY_NAME")
        let authAuthorizerSignature = try getEnvironmentVarOrSkipTest(
            environmentVarName:
                "AWS_TEST_MQTT5_IOT_CORE_SIGNING_AUTHORIZER_TOKEN_SIGNATURE_UNENCODED")
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
