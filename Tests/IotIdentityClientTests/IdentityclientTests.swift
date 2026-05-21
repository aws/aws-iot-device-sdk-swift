import AwsIotDeviceSdkSwift
import Foundation
import XCTest

@testable import IotIdentityClient

// Free function that runs an AWS CLI command and returns trimmed stdout, or nil on failure.
// Defined at file scope so it can be called without capturing `self`, avoiding Swift 6
// concurrency issues when used inside closures.
// Process is only available on macOS and Linux.
#if os(macOS) || os(Linux)
  @discardableResult
  func awsCLI(_ arguments: [String]) -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["aws"] + arguments + ["--region", "us-east-1"]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()  // suppress stderr
    do {
      try process.run()
      process.waitUntilExit()
      guard process.terminationStatus == 0 else { return nil }
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
      print("AWS CLI error: \(error)")
      return nil
    }
  }
#endif

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
        endpoint: endpoint, pkcs12Path: pkcs12Path, pkcs12Password: pkcs12Password)
    #else
      let certPath = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
      let keyPath = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")
      let builder = try Mqtt5ClientBuilder.mtlsFromPath(
        endpoint: endpoint, certPath: certPath, keyPath: keyPath)
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

    // Build and return the IotIdentityClient
    let options: MqttRequestResponseClientOptions = MqttRequestResponseClientOptions(
      maxRequestResponseSubscription: 5,
      maxStreamingSubscription: 3,
      operationTimeout: 10)
    let identityClient: IotIdentityClient = try IotIdentityClient(
      mqttClient: mqttClient, options: options)
    XCTAssertNotNil(identityClient)
    return identityClient
  }

  // Helper function that uses the AWS CLI to clean up IoT Things and certificates
  // created in the identity tests.
  // Process is only available on macOS and Linux, so cleanup is a no-op on iOS/tvOS.
  private func cleanUpThing(
    certificateId: String?, thingName: String?, deleteCert: Bool = false
  ) async {
    #if os(macOS) || os(Linux)
      guard let certificateId, let thingName else {
        print("Missing certificateId or thingName, skipping cleanup")
        return
      }

      // Get certificate ARN
      let describeResult = awsCLI([
        "iot", "describe-certificate",
        "--certificate-id", certificateId,
        "--query", "certificateDescription.certificateArn",
        "--output", "text",
      ])
      guard let certificateArn = describeResult else {
        print("Failed to get certificate ARN, skipping cleanup")
        return
      }

      // Detach principal from thing
      awsCLI([
        "iot", "detach-thing-principal",
        "--principal", certificateArn,
        "--thing-name", thingName,
      ])

      print("Deleting thing: \(thingName)")
      awsCLI(["iot", "delete-thing", "--thing-name", thingName])
      print("Cleanup of \(thingName) complete")

      guard deleteCert else { return }
      print("Cleaning up certificate: \(certificateArn)")

      // List and detach policies
      let policiesResult = awsCLI([
        "iot", "list-attached-policies",
        "--target", certificateArn,
        "--query", "policies[].policyName",
        "--output", "text",
      ])
      if let policiesOutput = policiesResult {
        let policyNames = policiesOutput.split(separator: "\t").map(String.init)
        for policyName in policyNames where !policyName.isEmpty {
          print("Detaching policy: \(policyName)")
          awsCLI([
            "iot", "detach-policy",
            "--policy-name", policyName,
            "--target", certificateArn,
          ])
        }
      }

      // Deactivate and delete certificate
      awsCLI([
        "iot", "update-certificate",
        "--certificate-id", certificateId,
        "--new-status", "INACTIVE",
      ])
      print("Certificate deactivated.")
      awsCLI(["iot", "delete-certificate", "--certificate-id", certificateId])
      print("Certificate deleted.")
    #endif
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
