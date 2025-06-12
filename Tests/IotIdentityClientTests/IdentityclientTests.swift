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
      maxRequestResponseSubscription: 5,
      maxStreamingSubscription: 3,
      operationTimeout: 10)
    let identityClient: IotIdentityClient = try IotIdentityClient(
      mqttClient: mqttClient, options: options)
    XCTAssertNotNil(identityClient)
    return identityClient
  }

  // Helper function that creates an IoTClient from the AWSIoT SDK to clean up IoT Things and certificates
  // created in the identity tests.
  private func cleanUpThing(
    certificateId: String?, thingName: String?, deleteCert: Bool = false
  ) async {
    guard let certificateId, let thingName else {
      print("Missing certificateId or thingName")
      return
    }

    let iotClient: IoTClient
    do {
      iotClient = try await IoTClient(
        config: IoTClient.IoTClientConfiguration(region: "us-east-1"))
    } catch {
      print(
        "Skipping cleanup of created thing/certificate: failed to create IoTClient with error: \(error)"
      )
      return
    }

    do {
      // Get certificate ARN
      let describeResp = try await iotClient.describeCertificate(
        input: .init(certificateId: certificateId))

      guard let certificateArn = describeResp.certificateDescription?.certificateArn else {
        print("Certificate ARN not found")
        return
      }

      do {
        // Detach principal from thing
        _ = try await iotClient.detachThingPrincipal(
          input: .init(principal: certificateArn, thingName: thingName))

        print("Deleting thing: \(thingName)")
        _ = try await iotClient.deleteThing(input: .init(thingName: thingName))
        print("Cleanup of \(thingName) complete")
      } catch {
        print("failed to delete iot thing")
      }

      guard deleteCert else { return }
      print("Cleaning up certificate: \(certificateArn)")

      // Detach policies
      let policyResp = try await iotClient.listAttachedPolicies(
        input: .init(target: certificateArn))

      for policy in policyResp.policies ?? [] {
        if let policyName = policy.policyName {
          print("Detaching policy: \(policyName)")
          do {
            _ = try await iotClient.detachPolicy(
              input: .init(policyName: policyName, target: certificateArn))
          } catch {
            print("Failed to detach policy '\(policyName)': \(error)")
          }
        }
      }

      // Deactivate and delete certificate
      _ = try await iotClient.updateCertificate(
        input: .init(certificateId: certificateId, newStatus: .inactive))
      print("Certificate deactivated.")
      _ = try await iotClient.deleteCertificate(input: .init(certificateId: certificateId))
      print("Certificate deleted.")

    } catch {
      print("Cleanup failed: \(error)")
    }
  }

  func testIdentityClientCreateDestroy() async throws {
    let identityClient = try await getIdentityClient()
    XCTAssertNotNil(identityClient)
  }

  func testIdentityClientProvisionWithCertAndKey() async throws {
    let templateName: String = try getEnvironmentVarOrSkipTest(
      environmentVarName: "AWS_TEST_IOT_CORE_PROVISIONING_TEMPLATE_NAME")

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
    await cleanUpThing(
      certificateId: createKeysAndCertificateResponse.certificateId,
      thingName: registerThingResponse.thingName)
  }

  func testIdentityClientProvisionWithCSR() async throws {
    var thingName: String = ""
    let templateName: String = try getEnvironmentVarOrSkipTest(
      environmentVarName: "AWS_TEST_IOT_CORE_PROVISIONING_TEMPLATE_NAME")
    let csrPath: String = try getEnvironmentVarOrSkipTest(
      environmentVarName: "AWS_TEST_IOT_CORE_PROVISIONING_CSR_PATH")

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

    do {
      // Make the request to register a thing
      let registerThingResponse = try await identityClient.registerThing(
        request: registerThingRequest)
      // Make sure we've gotten a proper response
      XCTAssertNotNil(registerThingResponse.deviceConfiguration)
      XCTAssertNotNil(registerThingResponse.thingName)
      thingName = registerThingResponse.thingName!
    } catch {
      await cleanUpThing(
        certificateId: createCertificateFromCsrResponse.certificateId,
        thingName: thingName,
        deleteCert: true)
      throw error
    }

    print("Created thingName: \(thingName)")
    await cleanUpThing(
      certificateId: createCertificateFromCsrResponse.certificateId,
      thingName: thingName,
      deleteCert: true)
  }
}
