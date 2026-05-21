import AwsIotDeviceSdkSwift
import Foundation
import IotShadowClient
import XCTest

@testable import IotJobsClient

enum MqttTestError: Error {
  case timeout
  case connectionFail
  case disconnectFail
  case stopFail
}

class TestContext: @unchecked Sendable {
  var jobExecutionChangedEvents: [JobExecutionsChangedEvent] = []
  var nextJobChangedEvents: [NextJobExecutionChangedEvent] = []
  var serializedFailed = false
  var jobId: String?
  var thingGroupName: String?
  var thingName: String?
  var iotJobsClient: IotJobsClient?
}

class JobsClientTests: XCTestCase {
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

  static func jsonData(from dict: [String: Any]) throws -> Data {
    try JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])
  }

  // Helper function that creates an MqttClient, connects the client, uses the client to create an
  // IotJobsClient, then returns the jobs client in a ready for use state.
  private func getJobsClient() async throws -> IotJobsClient {

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
    let onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess = { _ in
      connectionExpectation.fulfill()
    }

    builder.withOnLifecycleEventConnectionSuccess(onLifecycleEventConnectionSuccess)
    let mqttClient = try builder.build()
    XCTAssertNotNil(mqttClient)

    // Connect the Mqtt5 Client
    try mqttClient.start()
    // Await the expectation being fulfilled with a timeout.
    await fulfillment(of: [connectionExpectation], timeout: 5, enforceOrder: false)

    // Build and return the IotJobsClient
    let options: MqttRequestResponseClientOptions = MqttRequestResponseClientOptions(
      maxRequestResponseSubscription: 3, maxStreamingSubscription: 2,
      operationTimeout: 10)
    let iotJobsClient: IotJobsClient = try IotJobsClient(
      mqttClient: mqttClient, options: options)
    XCTAssertNotNil(iotJobsClient)
    return iotJobsClient
  }

  // Runs an AWS CLI command and returns trimmed stdout, or nil on failure.
  // Process is only available on macOS and Linux.
  #if os(macOS) || os(Linux)
    @discardableResult
    private func runAWSCLI(_ arguments: [String]) -> String? {
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

    // Creates AWS IoT resources needed for the Jobs integration test and registers
    // a teardown block to clean them up after the test completes.
    private func setupJobTestContext(testContext: TestContext) {
      let thingGroupName = "tgn_\(UUID().uuidString.lowercased())"
      let jobId = UUID().uuidString.lowercased()
      let thingName = "SwiftJobTest_\(UUID().uuidString.lowercased())"

      // Get account ID to construct the thing group ARN without needing iot:DescribeThingGroup
      guard
        let accountId = runAWSCLI([
          "sts", "get-caller-identity", "--query", "Account", "--output", "text",
        ])
      else {
        XCTFail("Failed to get AWS account ID")
        return
      }
      let thingGroupArn =
        "arn:aws:iot:us-east-1:\(accountId):thinggroup/\(thingGroupName)"

      runAWSCLI(["iot", "create-thing-group", "--thing-group-name", thingGroupName])
      runAWSCLI([
        "iot", "create-job",
        "--job-id", jobId,
        "--targets", thingGroupArn,
        "--document", "{\"test\":\"do-something\"}",
        "--target-selection", "CONTINUOUS",
      ])
      runAWSCLI(["iot", "create-thing", "--thing-name", thingName])

      testContext.thingGroupName = thingGroupName
      testContext.jobId = jobId
      testContext.thingName = thingName

      // Register teardown to clean up resources after the test, even on failure.
      addTeardownBlock {
        if let groupName = testContext.thingGroupName {
          self.runAWSCLI(["iot", "delete-thing-group", "--thing-group-name", groupName])
        }
        if let jId = testContext.jobId {
          self.runAWSCLI(["iot", "delete-job", "--job-id", jId, "--force"])
        }
        if let tName = testContext.thingName {
          self.runAWSCLI(["iot", "delete-thing", "--thing-name", tName])
        }
      }
    }
  #endif

  private func verifyNoPendingJobs(testContext: TestContext) async throws {
    // Verify there is no jobs in progress/pending
    let getPendingJobResponse = try await testContext.iotJobsClient!.getPendingJobExecutions(
      request: GetPendingJobExecutionsRequest(thingName: testContext.thingName!))
    XCTAssert(
      getPendingJobResponse.inProgressJobs?.isEmpty != nil
        && getPendingJobResponse.inProgressJobs!.isEmpty)
    XCTAssert(
      getPendingJobResponse.queuedJobs?.isEmpty != nil && getPendingJobResponse.queuedJobs!.isEmpty)
  }

  // Test job creation
  func testJobClientCreation() async throws {
    let iotJobsClient: IotJobsClient = try await getJobsClient()
    XCTAssertNotNil(iotJobsClient)
  }

  func testJobClient() async throws {
    do {

      // Obtain required endpoint and files from the environment or skip test.
      let _ = try getEnvironmentVarOrSkipTest(
        environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")

      let testContext = TestContext()

      // Create AWS IoT resources (thing group, job, thing) via the AWS CLI.
      // Resources are cleaned up automatically via addTeardownBlock.
      // Process (used by setupJobTestContext) is only available on macOS and Linux.
      #if os(macOS) || os(Linux)
        setupJobTestContext(testContext: testContext)
      #endif

      guard testContext.thingName != nil, testContext.jobId != nil,
        testContext.thingGroupName != nil
      else {
        throw XCTSkip("Skipping test: failed to set up AWS IoT test resources.")
      }

      let iotJobsClient: IotJobsClient = try await getJobsClient()
      testContext.iotJobsClient = iotJobsClient
      XCTAssertNotNil(iotJobsClient)

      let executionUpdateEstablishedExpectation = expectation(
        description: "executionUpdateEstablishedExpectation stream established")
      // The first jobs/notify event indicates the job is queued.
      let jobExecutionStartedExpectation = expectation(
        description: "jobExecutionStartedExpectation meets on job creation.")
      // When the job finished, the second jobs/notify event will be fired. And the event will includes an empty execution as no jobs left in the queue
      let jobExecutionFinishedExpectation = expectation(
        description: "jobExecutionFinishedExpectation meets on job finished.")

      let jobExecutionStreamingOperation = try iotJobsClient.createJobExecutionsChangedStream(
        request: JobExecutionsChangedSubscriptionRequest(thingName: testContext.thingName!),
        options: ClientStreamOptions<JobExecutionsChangedEvent>(
          streamEventHandler: { event in
            testContext.jobExecutionChangedEvents.append(event)
            if testContext.jobExecutionChangedEvents.count == 1 {
              jobExecutionStartedExpectation.fulfill()
            } else if testContext.jobExecutionChangedEvents.count == 2 {
              jobExecutionFinishedExpectation.fulfill()
            }
          },
          subscriptionEventHandler: { [executionUpdateEstablishedExpectation] event in
            if event.event == SubscriptionStatusEventType.established {
              executionUpdateEstablishedExpectation.fulfill()
            }
          }))

      try jobExecutionStreamingOperation.open()
      await fulfillment(of: [executionUpdateEstablishedExpectation], timeout: 5)

      let nextJobExecutionChangedEstablishedExpectation = expectation(
        description: "nextJobExecutionChangedExpectation stream established")
      // The first jobs/notify-next event indicates the job is queued.
      let nextJobExecutionQueuedExpectation = expectation(
        description: "nextJobExecutionQueuedExpectation meets on job creation.")
      // When the job finished, the second jobs/notify-next event will be fired. And the event will includes an empty execution as no jobs left in the queue
      let nextJobExecutionClearedExpectation = expectation(
        description: "nextJobExecutionClearedExpectation meets on job finished.")

      let nextJobExecutionChanged = try iotJobsClient.createNextJobExecutionChangedStream(
        request: NextJobExecutionChangedSubscriptionRequest(thingName: testContext.thingName!),
        options: ClientStreamOptions<NextJobExecutionChangedEvent>(
          streamEventHandler: { event in
            testContext.nextJobChangedEvents.append(event)
            if testContext.nextJobChangedEvents.count == 1 {
              nextJobExecutionQueuedExpectation.fulfill()
            } else if testContext.nextJobChangedEvents.count == 2 {
              nextJobExecutionClearedExpectation.fulfill()
            }
          },
          subscriptionEventHandler: { [nextJobExecutionChangedEstablishedExpectation] event in
            if event.event == SubscriptionStatusEventType.established {
              nextJobExecutionChangedEstablishedExpectation.fulfill()
            }
          },
          deserializationFailureHandler: { [testContext] _ in
            testContext.serializedFailed = true
          }
        ))
      try nextJobExecutionChanged.open()
      await fulfillment(of: [nextJobExecutionChangedEstablishedExpectation], timeout: 5)

      XCTAssertFalse(testContext.serializedFailed)

      // Verify there is no jobs in progress/pending
      try await verifyNoPendingJobs(testContext: testContext)

      // Now that streams are subscribed, add the thing to the group to trigger job notifications.
      // This is done via the AWS CLI so we don't need aws-sdk-swift as a dependency.
      // Process (used by runAWSCLI) is only available on macOS and Linux.
      #if os(macOS) || os(Linux)
        let addResult = runAWSCLI([
          "iot", "add-thing-to-thing-group",
          "--thing-group-name", testContext.thingGroupName!,
          "--thing-name", testContext.thingName!,
        ])
        XCTAssertNotNil(addResult, "Failed to add thing to thing group via AWS CLI")
      #endif

      await fulfillment(
        of: [nextJobExecutionQueuedExpectation, jobExecutionStartedExpectation], timeout: 30)
      XCTAssertFalse(testContext.nextJobChangedEvents.isEmpty)
      XCTAssertTrue(testContext.nextJobChangedEvents[0].execution?.jobId == testContext.jobId)
      XCTAssertTrue(testContext.nextJobChangedEvents[0].execution?.status == JobStatus.QUEUED)
      XCTAssertNotNil(testContext.jobExecutionChangedEvents[0].jobs[JobStatus.QUEUED])
      XCTAssertTrue(
        testContext.jobExecutionChangedEvents[0].jobs[JobStatus.QUEUED]?[0].jobId
          == testContext.jobId)

      let startNextProgress = try await iotJobsClient.startNextPendingJobExecution(
        request: StartNextPendingJobExecutionRequest(thingName: testContext.thingName!))

      XCTAssertTrue(startNextProgress.execution?.jobId == testContext.jobId)

      let describeJobResult = try await iotJobsClient.describeJobExecution(
        request: DescribeJobExecutionRequest(
          thingName: testContext.thingName!, jobId: testContext.jobId!))

      XCTAssertTrue(describeJobResult.execution.jobId == testContext.jobId!)

      // Update the job status to succeed
      _ = try await iotJobsClient.updateJobExecution(
        request: UpdateJobExecutionRequest(
          thingName: testContext.thingName!, jobId: testContext.jobId!, status: JobStatus.SUCCEEDED)
      )

      await fulfillment(
        of: [nextJobExecutionClearedExpectation, jobExecutionFinishedExpectation], timeout: 30)
      // As the jobs finished, the next job execution should be null
      XCTAssertNil(testContext.nextJobChangedEvents[1].execution)
      XCTAssertTrue(testContext.jobExecutionChangedEvents[1].jobs.isEmpty)

      try await verifyNoPendingJobs(testContext: testContext)
    }
  }
}
