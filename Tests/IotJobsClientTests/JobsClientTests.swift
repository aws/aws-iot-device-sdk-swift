import AWSIoT
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
  var serilizedFailed = false
  var jobId: String?
  var thingGroupName: String?
  var thingName: String?
  var iotClient: IoTClient?
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

  override func tearDown() {
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

  static func jsonData(from dict: [String: Any]) throws -> Data {
    try JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])
  }

  // Helper function that creates an MqttClient, connects the client, uses the client to create an
  // IotShadowClient, then returns the shadow client in a ready for use state.
  private func getJobsClient() async throws -> IotJobsClient {
    // Obtain required endpoint and files from the environment or skip test.
    let certPath = try getEnvironmentVarOrSkipTest(
      environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_CERT")
    let keyPath = try getEnvironmentVarOrSkipTest(
      environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_RSA_KEY")
    let endpoint = try getEnvironmentVarOrSkipTest(
      environmentVarName: "AWS_TEST_MQTT5_IOT_CORE_HOST")

    // Used to track whether the Mqtt5 Client connection is successful.
    let connectionExpectation: XCTestExpectation = expectation(
      description: "Connection Success")
    let onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess = { successData in
      connectionExpectation.fulfill()
    }

    // Build the Mqtt5 Client
    let builder = try Mqtt5ClientBuilder.mtlsFromPath(
      certPath: certPath, keyPath: keyPath, endpoint: endpoint)
    builder.withOnLifecycleEventConnectionSuccess(onLifecycleEventConnectionSuccess)
    let mqttClient = try builder.build()
    XCTAssertNotNil(mqttClient)

    // Connect the Mqtt5 Client
    try mqttClient.start()
    // Await the expectation being fulfilled with a timeout.
    await fulfillment(of: [connectionExpectation], timeout: 5, enforceOrder: false)

    // Build and return the IotJobsClient
    let options: MqttRequestResponseClientOptions = MqttRequestResponseClientOptions(
      operationTimeout: 10)
    let iotJobsClient: IotJobsClient = try IotJobsClient(
      mqttClient: mqttClient, options: options)
    XCTAssertNotNil(iotJobsClient)
    return iotJobsClient
  }

  // Use AWS SDK iotClient to setup testing jobs in IoT account
  static private func setupJobTestContext(testContext: TestContext) async throws {

    testContext.iotClient = try await AWSIoT.IoTClient(
      config: IoTClient.IoTClientConfiguration(region: "us-east-1"))
    let iotClient = testContext.iotClient!

    let testGroupName = "tgn_" + UUID().uuidString
    let newThingGroup = try await iotClient.createThingGroup(
      input: CreateThingGroupInput(thingGroupName: testGroupName))

    XCTAssertNotNil(newThingGroup.thingGroupName)
    testContext.thingGroupName = newThingGroup.thingGroupName
    let thingGroupArn = newThingGroup.thingGroupArn

    let jobId = UUID().uuidString
    // Job with an empty document will not be executed
    let newJob = try await iotClient.createJob(
      input: CreateJobInput(
        document: "{\"test\":\"do-something\"}", jobId: jobId,
        targetSelection: IoTClientTypes.TargetSelection.continuous, targets: [thingGroupArn!]))
    XCTAssertNotNil(newJob.jobId)
    testContext.jobId = newJob.jobId

    let thingName = "SwiftJobTest_" + UUID().uuidString
    let createThingResponse = try await testContext.iotClient!.createThing(
      input: CreateThingInput(thingName: thingName))
    testContext.thingName = createThingResponse.thingName

  }

  // Use AWS SDK iotClient to setup testing jobs in IoT account
  static private func cleanupJobTestContext(testContext: TestContext) async throws {
    guard let iotClient = testContext.iotClient else {
      return
    }

    if let thingGroupName = testContext.thingGroupName {
      _ = try await iotClient.deleteThingGroup(
        input: DeleteThingGroupInput(thingGroupName: thingGroupName))
    }

    if let jobId = testContext.jobId {
      _ = try await iotClient.deleteJob(input: DeleteJobInput(force: true, jobId: jobId))
    }

    if let thingName = testContext.thingName {
      _ = try await iotClient.deleteThing(input: DeleteThingInput(thingName: thingName))
    }

  }

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
      // Job Test Context
      let testContext = TestContext()
      try await JobsClientTests.setupJobTestContext(testContext: testContext)

      addTeardownBlock {
        try await JobsClientTests.cleanupJobTestContext(testContext: testContext)
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
      await awaitExpectation([executionUpdateEstablishedExpectation])

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
          deserializationFailureHandler: { [testContext] event in
            testContext.serilizedFailed = true
          }
        ))
      try nextJobExecutionChanged.open()
      await awaitExpectation([nextJobExecutionChangedEstablishedExpectation])

      XCTAssertFalse(testContext.serilizedFailed)

      // Verify there is no jobs in progress/pending
      try await verifyNoPendingJobs(testContext: testContext)

      _ = try await testContext.iotClient?.addThingToThingGroup(
        input: AddThingToThingGroupInput(
          thingGroupName: testContext.thingGroupName, thingName: testContext.thingName))

      await awaitExpectation(
        [nextJobExecutionQueuedExpectation, jobExecutionStartedExpectation], 30)
      XCTAssertFalse(testContext.nextJobChangedEvents.isEmpty)
      XCTAssertTrue(testContext.nextJobChangedEvents[0].execution.jobId == testContext.jobId)
      XCTAssertTrue(testContext.nextJobChangedEvents[0].execution.status == JobStatus.QUEUED)
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
      let _ = try await iotJobsClient.updateJobExecution(
        request: UpdateJobExecutionRequest(
          thingName: testContext.thingName!, jobId: testContext.jobId!, status: JobStatus.SUCCEEDED)
      )

      await awaitExpectation(
        [nextJobExecutionClearedExpectation, jobExecutionFinishedExpectation], 30)

      try await verifyNoPendingJobs(testContext: testContext)
    }
  }
}
