import AWSClientRuntime
import AWSIoT
import AWSSDKIdentity
import AwsIotDeviceSdkSwift
import Foundation
import XCTest

@testable import IotIdentityClient

func createClientId() -> String {
    return "test-iot-device-sdk-swift-" + UUID().uuidString
}

class IdentityClientTests: XCTestCase {
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

    // Helper function that creates an MqttClient, connects the client, uses the client to create an
    // IotIdentityClient, then returns the identity client in a ready for use state.
    private func getIdentityClient() async throws -> IotIdentityClient {
        // Obtain required endpoint and files from the environment or skip test.
        let endpoint = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")

        // only iOS and tvOS should use PKCS12. macOS and Linux should use X509 cert/key
        #if os(iOS) || os(tvOS)
            let pkcs12Path = try getEnvironmentVarOrSkipTest(
                environmentVarName: "AWS_TEST_MQTT5_PKCS12_FILE")
            let pkcs12Password = try getEnvironmentVarOrSkipTest(
                environmentVarName: "AWS_TEST_MQTT5_PKCS12_PASSWORD")
            let builder = try Mqtt5ClientBuilder.mtlsFromPKCS12(
                pkcs12Path: pkcs12Path, pkcs12Password: pkcs12Password, endpoint: endpoint)
        #else
            let certPath = try getEnvironmentVarOrSkipTest(
                environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
            let keyPath = try getEnvironmentVarOrSkipTest(
                environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")
            let builder = try Mqtt5ClientBuilder.mtlsFromPath(
                certPath: certPath, keyPath: keyPath, endpoint: endpoint)
        #endif

        // Used to track whether the Mqtt5 Client connection is successful.
        let connectionExpectation: XCTestExpectation = expectation(
            description: "Connection Success")
        let onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess = { successData in
            connectionExpectation.fulfill()
        }

        // Build the Mqtt5 Client
        builder.withClientId(createClientId())
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
        let identityClient: IotIdentityClient = try IotIdentityClient(
            mqttClient: mqttClient, options: options)
        XCTAssertNotNil(identityClient)
        return identityClient
    }

    // Helper function that creates an IoTClient from the AWSIoT SDK to clean up IoT Things created
    // in the identity tests.
    private func cleanUpThing(
        certificateId: String?, thingName: String?, accessKey: String, secretKey: String,
        sessionToken: String, region: String
    ) async throws {
        let awsCredentialIdentity = AWSCredentialIdentity(
            accessKey: accessKey, secret: secretKey, sessionToken: sessionToken)
        let staticAWSCredIdent = try StaticAWSCredentialIdentityResolver(awsCredentialIdentity)

        let iotClientConfig = try await IoTClient.IoTClientConfiguration(
            awsCredentialIdentityResolver: staticAWSCredIdent, region: region)

        let iotClient = AWSIoT.IoTClient(config: iotClientConfig)

        // feed certificate ID to get the certificate Arn
        let describeCertificateOutput = try await iotClient.describeCertificate(
            input: DescribeCertificateInput(
                certificateId: certificateId))

        if let certDescription = describeCertificateOutput.certificateDescription {
            if let certificateArn: String = certDescription.certificateArn {
                _ = try await iotClient.detachThingPrincipal(
                    input: DetachThingPrincipalInput(
                        principal: certificateArn, thingName: thingName))

                print("Deleting thingName: \(thingName ?? "no thingName")")
                _ = try await iotClient.deleteThing(
                    input: DeleteThingInput(thingName: thingName))
            } else {
                print("Certificate ARN not found")
            }
        } else {
            print("Certificate Description not found")
        }
    }

    func testIdentityClientCreateDestroy() async throws {
        let identityClient = try await getIdentityClient()
        XCTAssertNotNil(identityClient)
    }

    func testIdentityClientProvisionWithCertAndKey() async throws {
        let templateName: String = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_IOT_CORE_PROVISIONING_TEMPLATE_NAME")

        // Check that credential env variables have been set or skip test
        let accessKey = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_ROLE_CREDENTIAL_ACCESS_KEY")
        let secretKey = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_ROLE_CREDENTIAL_SECRET_ACCESS_KEY")
        let sessionToken = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_ROLE_CREDENTIAL_SESSION_TOKEN")
        let region = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_DEFAULT_REGION")

        let identityClient = try await getIdentityClient()

        let request = CreateKeysAndCertificateRequest()

        let createKeysAndCertificateResponse = try await identityClient.createKeysAndCertificate(
            request: request)

        // Make sure we have what we expect
        XCTAssertNotNil(createKeysAndCertificateResponse.certificateId)
        XCTAssertNotNil(createKeysAndCertificateResponse.certificatePem)
        XCTAssertNotNil(createKeysAndCertificateResponse.privateKey)
        XCTAssertNotNil(createKeysAndCertificateResponse.certificateOwnershipToken)

        var params: [String: String] = [:]
        params["SerialNumber"] = UUID().uuidString
        params["DeviceLocation"] = "Seattle"

        let registerThingRequest = RegisterThingRequest(
            templateName: templateName,
            certificateOwnershipToken: createKeysAndCertificateResponse.certificateOwnershipToken!,
            parameters: params
        )

        // Make the request to register a thing
        let registerThingResponse = try await identityClient.registerThing(
            request: registerThingRequest)
        // Make sure we've gotten a proper response
        XCTAssertNotNil(registerThingResponse.deviceConfiguration)
        XCTAssertNotNil(registerThingResponse.thingName)

        print("Created thingName: \(registerThingResponse.thingName ?? "nil")")
        try await cleanUpThing(
            certificateId: createKeysAndCertificateResponse.certificateId,
            thingName: registerThingResponse.thingName,
            accessKey: accessKey, secretKey: secretKey,
            sessionToken: sessionToken, region: region)
    }

    func testIdentityClientProvisionWithCSR() async throws {
        let templateName: String = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_IOT_CORE_PROVISIONING_TEMPLATE_NAME")
        let csrPath: String = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_IOT_CORE_PROVISIONING_CSR_PATH")

        // Check that credential env variables have been set or skip test
        let accessKey = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_ROLE_CREDENTIAL_ACCESS_KEY")
        let secretKey = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_ROLE_CREDENTIAL_SECRET_ACCESS_KEY")
        let sessionToken = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_TEST_MQTT5_ROLE_CREDENTIAL_SESSION_TOKEN")
        let region = try getEnvironmentVarOrSkipTest(
            environmentVarName: "AWS_DEFAULT_REGION")

        let csrString: String = try String(contentsOfFile: csrPath)
        let identityClient = try await getIdentityClient()

        let request = CreateCertificateFromCsrRequest(certificateSigningRequest: csrString)

        let createCertificateFromCsrResponse = try await identityClient.createCertificateFromCsr(
            request: request)

        // Make sure we have what we expect
        XCTAssertNotNil(createCertificateFromCsrResponse.certificateId)
        XCTAssertNotNil(createCertificateFromCsrResponse.certificatePem)
        XCTAssertNotNil(createCertificateFromCsrResponse.certificateOwnershipToken)

        var params: [String: String] = [:]
        params["SerialNumber"] = UUID().uuidString
        params["DeviceLocation"] = "Seattle"

        let registerThingRequest = RegisterThingRequest(
            templateName: templateName,
            certificateOwnershipToken: createCertificateFromCsrResponse.certificateOwnershipToken!,
            parameters: params
        )

        // Make the request to register a thing
        let registerThingResponse = try await identityClient.registerThing(
            request: registerThingRequest)
        // Make sure we've gotten a proper response
        XCTAssertNotNil(registerThingResponse.deviceConfiguration)
        XCTAssertNotNil(registerThingResponse.thingName)

        print("Created thingName: \(registerThingResponse.thingName ?? "nil")")
        try await cleanUpThing(
            certificateId: createCertificateFromCsrResponse.certificateId,
            thingName: registerThingResponse.thingName,
            accessKey: accessKey, secretKey: secretKey,
            sessionToken: sessionToken, region: region)
    }
}
