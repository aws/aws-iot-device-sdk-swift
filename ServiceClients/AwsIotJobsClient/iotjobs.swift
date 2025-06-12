// Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
// SPDX-License-Identifier: Apache-2.0.

// This file is generated

import Foundation

import AwsIotDeviceSdkSwift
import Foundation

/// The AWS IoT jobs service can be used to define a set of remote operations that are sent to and executed on one or more devices connected to AWS IoT.
/// AWS Docs: https://docs.aws.amazon.com/iot/latest/developerguide/jobs-api.html#jobs-mqtt-api
public class IotJobsClient {
  internal let rrClient: AwsIotDeviceSdkSwift.MqttRequestResponseClient
  internal let encoder: JSONEncoder = JSONEncoder()
  internal let decoder: JSONDecoder = JSONDecoder()

  public init(
    mqttClient: AwsIotDeviceSdkSwift.Mqtt5Client, options: MqttRequestResponseClientOptions
  ) throws {
    self.rrClient = try MqttRequestResponseClient(mqtt5Client: mqttClient, options: options)
  }

  /// Creates a stream of JobExecutionsChanged notifications for a given IoT thing.
  ///
  /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/jobs-api.html#mqtt-jobexecutionschanged
  ///
  /// - Parameters:
  ///     - request: `JobExecutionsChangedSubscriptionRequest` modeled streaming operation subscription configuration
  ///     - options: options set of callbacks that the operation should invoke in response to success, subscription status,
  ///         and deserialization failure.
  /// - Returns:
  ///     - `StreamingOperation`: which will invoke a callback every time a message is received on the associated MQTT topic.
  /// - Throws:
  ///     - `IotJobsClientError`
  public func createJobExecutionsChangedStream(
    request: JobExecutionsChangedSubscriptionRequest,
    options: ClientStreamOptions<JobExecutionsChangedEvent>
  ) throws -> StreamingOperation {
    var topic: String = "$aws/things/{thingName}/jobs/notify"
    topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)

    let innerOptions: StreamingOperationOptions = StreamingOperationOptions(
      topicFilter: topic,
      subscriptionStatusCallback: { status in
        options.subscriptionEventHandler(status)
      },
      incomingPublishCallback: { publish in
        do {
          let event = try JSONDecoder().decode(
            JobExecutionsChangedEvent.self, from: publish.payload)
          options.streamEventHandler(event)
        } catch {
          let failure = DeserializationFailureEvent(
            cause: error,
            payload: publish.payload,
            topic: publish.topic
          )
          options.deserializationFailureHandler(failure)
        }
      })

    do {
      return try rrClient.createStream(streamOptions: innerOptions)
    } catch let clientErr as IotJobsClientError {
      // Pass along the thrown IotJobsClientError
      throw clientErr
    } catch let CommonRunTimeError.crtError(crtErr) {
      // Throw IotJobsClientError.crt containing the `CRTError`
      throw IotJobsClientError.crt(crtErr)
    } catch {
      // Throw IotJobsClientError.underlying containing any other `Error`
      throw IotJobsClientError.underlying(error)
    }
  }

  ///
  ///
  /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/jobs-api.html#mqtt-nextjobexecutionchanged
  ///
  /// - Parameters:
  ///     - request: `NextJobExecutionChangedSubscriptionRequest` modeled streaming operation subscription configuration
  ///     - options: options set of callbacks that the operation should invoke in response to success, subscription status,
  ///         and deserialization failure.
  /// - Returns:
  ///     - `StreamingOperation`: which will invoke a callback every time a message is received on the associated MQTT topic.
  /// - Throws:
  ///     - `IotJobsClientError`
  public func createNextJobExecutionChangedStream(
    request: NextJobExecutionChangedSubscriptionRequest,
    options: ClientStreamOptions<NextJobExecutionChangedEvent>
  ) throws -> StreamingOperation {
    var topic: String = "$aws/things/{thingName}/jobs/notify-next"
    topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)

    let innerOptions: StreamingOperationOptions = StreamingOperationOptions(
      topicFilter: topic,
      subscriptionStatusCallback: { status in
        options.subscriptionEventHandler(status)
      },
      incomingPublishCallback: { publish in
        do {
          let event = try JSONDecoder().decode(
            NextJobExecutionChangedEvent.self, from: publish.payload)
          options.streamEventHandler(event)
        } catch {
          let failure = DeserializationFailureEvent(
            cause: error,
            payload: publish.payload,
            topic: publish.topic
          )
          options.deserializationFailureHandler(failure)
        }
      })

    do {
      return try rrClient.createStream(streamOptions: innerOptions)
    } catch let clientErr as IotJobsClientError {
      // Pass along the thrown IotJobsClientError
      throw clientErr
    } catch let CommonRunTimeError.crtError(crtErr) {
      // Throw IotJobsClientError.crt containing the `CRTError`
      throw IotJobsClientError.crt(crtErr)
    } catch {
      // Throw IotJobsClientError.underlying containing any other `Error`
      throw IotJobsClientError.underlying(error)
    }
  }

  /// Gets detailed information about a job execution.
  ///
  /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/jobs-api.html#mqtt-describejobexecution
  ///
  /// - Parameters:
  ///     - request: `DescribeJobExecutionRequest` modeled request to perform.
  /// - Returns: `DescribeJobExecutionResponse`: with the corresponding response.
  ///
  /// - Throws: `IotJobsClientError` Thrown when the provided request is rejected or when
  ///             a low-level `CRTError` or other underlying `Error` is thrown.
  public func describeJobExecution(request: DescribeJobExecutionRequest) async throws
    -> DescribeJobExecutionResponse
  {
    let correlationToken: String = UUID().uuidString

    // Publish Topic
    var topic: String = "$aws/things/{thingName}/jobs/{jobId}/get"
    topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)
    topic = topic.replacingOccurrences(of: "{jobId}", with: request.jobId)

    // Subscription Topic Filters
    var subscriptionTopicFilters: [String] = []
    var subscription0: String = "$aws/things/{thingName}/jobs/{jobId}/get/+"
    subscription0 = subscription0.replacingOccurrences(of: "{thingName}", with: request.thingName)
    subscription0 = subscription0.replacingOccurrences(of: "{jobId}", with: request.jobId)
    subscriptionTopicFilters.append(subscription0)

    // Response paths
    let responseTopic1: String = topic + "/accepted"
    let responseTopic2: String = topic + "/rejected"
    let token1 = "clientToken"
    let token2 = "clientToken"
    let responsePath1: ResponsePath = ResponsePath(
      topic: responseTopic1, correlationTokenJsonPath: token1)
    let responsePath2: ResponsePath = ResponsePath(
      topic: responseTopic2, correlationTokenJsonPath: token2)

    do {
      // Encode the event into JSON Data.
      let payload = try encoder.encode(request)

      let requestResponseOperationOptions = RequestResponseOperationOptions(
        subscriptionTopicFilters: subscriptionTopicFilters,
        responsePaths: [responsePath1, responsePath2],
        topic: topic,
        payload: payload,
        correlationToken: correlationToken)

      let response = try await rrClient.submitRequest(
        operationOptions: requestResponseOperationOptions)

      if (response.topic == responseTopic1) {
        // Successful operation ack returns the expected output.
        return try decoder.decode(DescribeJobExecutionResponse.self, from: response.payload)
      } else {
        // Unsuccessful operation ack throws IotJobsClientError.errorResponse
        throw IotJobsClientError.errorResponse(
          try decoder.decode(V2ErrorResponse.self, from: response.payload))
      }
    } catch let clientErr as IotJobsClientError {
      // Pass along the thrown IotJobsClientError
      throw clientErr
    } catch let CommonRunTimeError.crtError(crtErr) {
      // Throw IotJobsClientError.crt containing the `CRTError`
      throw IotJobsClientError.crt(crtErr)
    } catch {
      // Throw IotJobsClientError.underlying containing any other `Error`
      throw IotJobsClientError.underlying(error)
    }
  }

  /// Gets the list of all jobs for a thing that are not in a terminal state.
  ///
  /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/jobs-api.html#mqtt-getpendingjobexecutions
  ///
  /// - Parameters:
  ///     - request: `GetPendingJobExecutionsRequest` modeled request to perform.
  /// - Returns: `GetPendingJobExecutionsResponse`: with the corresponding response.
  ///
  /// - Throws: `IotJobsClientError` Thrown when the provided request is rejected or when
  ///             a low-level `CRTError` or other underlying `Error` is thrown.
  public func getPendingJobExecutions(request: GetPendingJobExecutionsRequest) async throws
    -> GetPendingJobExecutionsResponse
  {
    let correlationToken: String = UUID().uuidString

    // Publish Topic
    var topic: String = "$aws/things/{thingName}/jobs/get"
    topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)

    // Subscription Topic Filters
    var subscriptionTopicFilters: [String] = []
    var subscription0: String = "$aws/things/{thingName}/jobs/get/+"
    subscription0 = subscription0.replacingOccurrences(of: "{thingName}", with: request.thingName)
    subscriptionTopicFilters.append(subscription0)

    // Response paths
    let responseTopic1: String = topic + "/accepted"
    let responseTopic2: String = topic + "/rejected"
    let token1 = "clientToken"
    let token2 = "clientToken"
    let responsePath1: ResponsePath = ResponsePath(
      topic: responseTopic1, correlationTokenJsonPath: token1)
    let responsePath2: ResponsePath = ResponsePath(
      topic: responseTopic2, correlationTokenJsonPath: token2)

    do {
      // Encode the event into JSON Data.
      let payload = try encoder.encode(request)

      let requestResponseOperationOptions = RequestResponseOperationOptions(
        subscriptionTopicFilters: subscriptionTopicFilters,
        responsePaths: [responsePath1, responsePath2],
        topic: topic,
        payload: payload,
        correlationToken: correlationToken)

      let response = try await rrClient.submitRequest(
        operationOptions: requestResponseOperationOptions)

      if (response.topic == responseTopic1) {
        // Successful operation ack returns the expected output.
        return try decoder.decode(GetPendingJobExecutionsResponse.self, from: response.payload)
      } else {
        // Unsuccessful operation ack throws IotJobsClientError.errorResponse
        throw IotJobsClientError.errorResponse(
          try decoder.decode(V2ErrorResponse.self, from: response.payload))
      }
    } catch let clientErr as IotJobsClientError {
      // Pass along the thrown IotJobsClientError
      throw clientErr
    } catch let CommonRunTimeError.crtError(crtErr) {
      // Throw IotJobsClientError.crt containing the `CRTError`
      throw IotJobsClientError.crt(crtErr)
    } catch {
      // Throw IotJobsClientError.underlying containing any other `Error`
      throw IotJobsClientError.underlying(error)
    }
  }

  /// Gets and starts the next pending job execution for a thing (status IN_PROGRESS or QUEUED).
  ///
  /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/jobs-api.html#mqtt-startnextpendingjobexecution
  ///
  /// - Parameters:
  ///     - request: `StartNextPendingJobExecutionRequest` modeled request to perform.
  /// - Returns: `StartNextJobExecutionResponse`: with the corresponding response.
  ///
  /// - Throws: `IotJobsClientError` Thrown when the provided request is rejected or when
  ///             a low-level `CRTError` or other underlying `Error` is thrown.
  public func startNextPendingJobExecution(request: StartNextPendingJobExecutionRequest)
    async throws -> StartNextJobExecutionResponse
  {
    let correlationToken: String = UUID().uuidString

    // Publish Topic
    var topic: String = "$aws/things/{thingName}/jobs/start-next"
    topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)

    // Subscription Topic Filters
    var subscriptionTopicFilters: [String] = []
    var subscription0: String = "$aws/things/{thingName}/jobs/start-next/+"
    subscription0 = subscription0.replacingOccurrences(of: "{thingName}", with: request.thingName)
    subscriptionTopicFilters.append(subscription0)

    // Response paths
    let responseTopic1: String = topic + "/accepted"
    let responseTopic2: String = topic + "/rejected"
    let token1 = "clientToken"
    let token2 = "clientToken"
    let responsePath1: ResponsePath = ResponsePath(
      topic: responseTopic1, correlationTokenJsonPath: token1)
    let responsePath2: ResponsePath = ResponsePath(
      topic: responseTopic2, correlationTokenJsonPath: token2)

    do {
      // Encode the event into JSON Data.
      let payload = try encoder.encode(request)

      let requestResponseOperationOptions = RequestResponseOperationOptions(
        subscriptionTopicFilters: subscriptionTopicFilters,
        responsePaths: [responsePath1, responsePath2],
        topic: topic,
        payload: payload,
        correlationToken: correlationToken)

      let response = try await rrClient.submitRequest(
        operationOptions: requestResponseOperationOptions)

      if (response.topic == responseTopic1) {
        // Successful operation ack returns the expected output.
        return try decoder.decode(StartNextJobExecutionResponse.self, from: response.payload)
      } else {
        // Unsuccessful operation ack throws IotJobsClientError.errorResponse
        throw IotJobsClientError.errorResponse(
          try decoder.decode(V2ErrorResponse.self, from: response.payload))
      }
    } catch let clientErr as IotJobsClientError {
      // Pass along the thrown IotJobsClientError
      throw clientErr
    } catch let CommonRunTimeError.crtError(crtErr) {
      // Throw IotJobsClientError.crt containing the `CRTError`
      throw IotJobsClientError.crt(crtErr)
    } catch {
      // Throw IotJobsClientError.underlying containing any other `Error`
      throw IotJobsClientError.underlying(error)
    }
  }

  /// Updates the status of a job execution. You can optionally create a step timer by setting a value for the stepTimeoutInMinutes property. If you don't update the value of this property by running UpdateJobExecution again, the job execution times out when the step timer expires.
  ///
  /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/jobs-api.html#mqtt-updatejobexecution
  ///
  /// - Parameters:
  ///     - request: `UpdateJobExecutionRequest` modeled request to perform.
  /// - Returns: `UpdateJobExecutionResponse`: with the corresponding response.
  ///
  /// - Throws: `IotJobsClientError` Thrown when the provided request is rejected or when
  ///             a low-level `CRTError` or other underlying `Error` is thrown.
  public func updateJobExecution(request: UpdateJobExecutionRequest) async throws
    -> UpdateJobExecutionResponse
  {
    let correlationToken: String = UUID().uuidString

    // Publish Topic
    var topic: String = "$aws/things/{thingName}/jobs/{jobId}/update"
    topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)
    topic = topic.replacingOccurrences(of: "{jobId}", with: request.jobId)

    // Subscription Topic Filters
    var subscriptionTopicFilters: [String] = []
    var subscription0: String = "$aws/things/{thingName}/jobs/{jobId}/update/+"
    subscription0 = subscription0.replacingOccurrences(of: "{thingName}", with: request.thingName)
    subscription0 = subscription0.replacingOccurrences(of: "{jobId}", with: request.jobId)
    subscriptionTopicFilters.append(subscription0)

    // Response paths
    let responseTopic1: String = topic + "/accepted"
    let responseTopic2: String = topic + "/rejected"
    let token1 = "clientToken"
    let token2 = "clientToken"
    let responsePath1: ResponsePath = ResponsePath(
      topic: responseTopic1, correlationTokenJsonPath: token1)
    let responsePath2: ResponsePath = ResponsePath(
      topic: responseTopic2, correlationTokenJsonPath: token2)

    do {
      // Encode the event into JSON Data.
      let payload = try encoder.encode(request)

      let requestResponseOperationOptions = RequestResponseOperationOptions(
        subscriptionTopicFilters: subscriptionTopicFilters,
        responsePaths: [responsePath1, responsePath2],
        topic: topic,
        payload: payload,
        correlationToken: correlationToken)

      let response = try await rrClient.submitRequest(
        operationOptions: requestResponseOperationOptions)

      if (response.topic == responseTopic1) {
        // Successful operation ack returns the expected output.
        return try decoder.decode(UpdateJobExecutionResponse.self, from: response.payload)
      } else {
        // Unsuccessful operation ack throws IotJobsClientError.errorResponse
        throw IotJobsClientError.errorResponse(
          try decoder.decode(V2ErrorResponse.self, from: response.payload))
      }
    } catch let clientErr as IotJobsClientError {
      // Pass along the thrown IotJobsClientError
      throw clientErr
    } catch let CommonRunTimeError.crtError(crtErr) {
      // Throw IotJobsClientError.crt containing the `CRTError`
      throw IotJobsClientError.crt(crtErr)
    } catch {
      // Throw IotJobsClientError.underlying containing any other `Error`
      throw IotJobsClientError.underlying(error)
    }
  }

}

/// Contains a subset of information about a job execution.
///
final public class JobExecutionSummary: Codable, Sendable {

  /// The unique identifier you assigned to this job when it was created.
  public let jobId: String?

  /// A number that identifies a job execution on a device.
  public let executionNumber: Int?

  /// The version of the job execution. Job execution versions are incremented each time the AWS IoT Jobs service receives an update from a device.
  public let versionNumber: Int?

  /// The time when the job execution was last updated.
  public let lastUpdatedAt: Foundation.Date?

  /// The time when the job execution was enqueued.
  public let queuedAt: Foundation.Date?

  /// The time when the job execution started.
  public let startedAt: Foundation.Date?

  /// Initializes a new `JobExecutionSummary`
  public init(
    jobId: String? = nil, executionNumber: Int? = nil, versionNumber: Int? = nil,
    lastUpdatedAt: Foundation.Date? = nil, queuedAt: Foundation.Date? = nil,
    startedAt: Foundation.Date? = nil
  ) {
    self.jobId = jobId
    self.executionNumber = executionNumber
    self.versionNumber = versionNumber
    self.lastUpdatedAt = lastUpdatedAt
    self.queuedAt = queuedAt
    self.startedAt = startedAt
  }

}

/// Data about a job execution.
///
final public class JobExecutionData: Codable, Sendable {

  /// The unique identifier you assigned to this job when it was created.
  public let jobId: String?

  /// The name of the thing that is executing the job.
  public let thingName: String?

  /// The content of the job document.
  private let jobDocumentInternal: [String: JSONValue]?

  /// The status of the job execution. Can be one of: QUEUED, IN_PROGRESS, FAILED, SUCCEEDED, CANCELED, TIMED_OUT, REJECTED, or REMOVED.
  public let status: JobStatus?

  /// A collection of name-value pairs that describe the status of the job execution.
  public let statusDetails: [String: String]?

  /// The time when the job execution was enqueued.
  public let queuedAt: Foundation.Date?

  /// The time when the job execution started.
  public let startedAt: Foundation.Date?

  /// The time when the job execution started.
  public let lastUpdatedAt: Foundation.Date?

  /// The version of the job execution. Job execution versions are incremented each time they are updated by a device.
  public let versionNumber: Int?

  /// A number that identifies a job execution on a device. It can be used later in commands that return or update job execution information.
  public let executionNumber: Int?

  /// Initializes a new `JobExecutionData`
  public init(
    jobId: String? = nil, thingName: String? = nil, jobDocument: [String: Any]? = nil,
    status: JobStatus? = nil, statusDetails: [String: String]? = nil,
    queuedAt: Foundation.Date? = nil, startedAt: Foundation.Date? = nil,
    lastUpdatedAt: Foundation.Date? = nil, versionNumber: Int? = nil, executionNumber: Int? = nil
  ) {
    self.jobId = jobId
    self.thingName = thingName
    self.jobDocumentInternal = jobDocument?.asJSONValueDictionary()
    self.status = status
    self.statusDetails = statusDetails
    self.queuedAt = queuedAt
    self.startedAt = startedAt
    self.lastUpdatedAt = lastUpdatedAt
    self.versionNumber = versionNumber
    self.executionNumber = executionNumber
  }

  enum CodingKeys: String, CodingKey {
    case jobId
    case thingName
    case jobDocument
    case status
    case statusDetails
    case queuedAt
    case startedAt
    case lastUpdatedAt
    case versionNumber
    case executionNumber
  }

  public var jobDocument: [String: Any]? {
    return jobDocumentInternal?.asAnyDictionary()
  }

  /// initialize this class containing the document trait from JSON
  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.jobId = try container.decodeIfPresent(String.self, forKey: .jobId)
    self.thingName = try container.decodeIfPresent(String.self, forKey: .thingName)
    let jobDocumentJSON = try container.decodeIfPresent(
      [String: JSONValue].self, forKey: .jobDocument)
    self.jobDocumentInternal = jobDocumentJSON
    self.status = try container.decodeIfPresent(JobStatus.self, forKey: .status)
    self.statusDetails = try container.decodeIfPresent(
      [String: String].self, forKey: .statusDetails)
    self.queuedAt = try container.decodeIfPresent(Foundation.Date.self, forKey: .queuedAt)
    self.startedAt = try container.decodeIfPresent(Foundation.Date.self, forKey: .startedAt)
    self.lastUpdatedAt = try container.decodeIfPresent(Foundation.Date.self, forKey: .lastUpdatedAt)
    self.versionNumber = try container.decodeIfPresent(Int.self, forKey: .versionNumber)
    self.executionNumber = try container.decodeIfPresent(Int.self, forKey: .executionNumber)
  }

  /// encode this class containing the document trait into JSON
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(jobId, forKey: .jobId)
    try container.encode(thingName, forKey: .thingName)
    if let jobDocumentInternal = jobDocumentInternal {
      try container.encode(jobDocumentInternal, forKey: .jobDocument)
    }
    try container.encode(status, forKey: .status)
    try container.encode(statusDetails, forKey: .statusDetails)
    try container.encode(queuedAt, forKey: .queuedAt)
    try container.encode(startedAt, forKey: .startedAt)
    try container.encode(lastUpdatedAt, forKey: .lastUpdatedAt)
    try container.encode(versionNumber, forKey: .versionNumber)
    try container.encode(executionNumber, forKey: .executionNumber)
  }
}

/// Data about the state of a job execution.
///
final public class JobExecutionState: Codable, Sendable {

  /// The status of the job execution. Can be one of: QUEUED, IN_PROGRESS, FAILED, SUCCEEDED, CANCELED, TIMED_OUT, REJECTED, or REMOVED.
  public let status: JobStatus?

  /// A collection of name-value pairs that describe the status of the job execution.
  public let statusDetails: [String: String]?

  /// The version of the job execution. Job execution versions are incremented each time they are updated by a device.
  public let versionNumber: Int?

  /// Initializes a new `JobExecutionState`
  public init(
    status: JobStatus? = nil, statusDetails: [String: String]? = nil, versionNumber: Int? = nil
  ) {
    self.status = status
    self.statusDetails = statusDetails
    self.versionNumber = versionNumber
  }

}

/// Data needed to make a DescribeJobExecution request.
///
final public class DescribeJobExecutionRequest: Codable, Sendable {

  /// The name of the thing associated with the device.
  public let thingName: String

  /// The unique identifier assigned to this job when it was created. Or use $next to return the next pending job execution for a thing (status IN_PROGRESS or QUEUED). In this case, any job executions with status IN_PROGRESS are returned first. Job executions are returned in the order in which they were created.
  public let jobId: String

  /// Optional. A number that identifies a job execution on a device. If not specified, the latest job execution is returned.
  public let executionNumber: Int?

  /// Optional. Unless set to false, the response contains the job document. The default is true.
  public let includeJobDocument: Bool?

  /// Initializes a new `DescribeJobExecutionRequest`
  public init(
    thingName: String, jobId: String, executionNumber: Int? = nil, includeJobDocument: Bool? = nil
  ) {
    self.thingName = thingName
    self.jobId = jobId
    self.executionNumber = executionNumber
    self.includeJobDocument = includeJobDocument
  }

}

/// Data needed to make a GetPendingJobExecutions request.
///
final public class GetPendingJobExecutionsRequest: Codable, Sendable {

  /// IoT Thing the request is relative to.
  public let thingName: String

  /// Initializes a new `GetPendingJobExecutionsRequest`
  public init(
    thingName: String
  ) {
    self.thingName = thingName
  }

}

/// Data needed to make a StartNextPendingJobExecution request.
///
final public class StartNextPendingJobExecutionRequest: Codable, Sendable {

  /// IoT Thing the request is relative to.
  public let thingName: String

  /// Specifies the amount of time this device has to finish execution of this job.
  public let stepTimeoutInMinutes: Int?

  /// A collection of name-value pairs that describe the status of the job execution. If not specified, the statusDetails are unchanged.
  public let statusDetails: [String: String]?

  /// Initializes a new `StartNextPendingJobExecutionRequest`
  public init(
    thingName: String, stepTimeoutInMinutes: Int? = nil, statusDetails: [String: String]? = nil
  ) {
    self.thingName = thingName
    self.stepTimeoutInMinutes = stepTimeoutInMinutes
    self.statusDetails = statusDetails
  }

}

/// Data needed to make an UpdateJobExecution request.
///
final public class UpdateJobExecutionRequest: Codable, Sendable {

  /// The name of the thing associated with the device.
  public let thingName: String

  /// The unique identifier assigned to this job when it was created.
  public let jobId: String

  /// The new status for the job execution (IN_PROGRESS, FAILED, SUCCEEDED, or REJECTED). This must be specified on every update.
  public let status: JobStatus

  /// A collection of name-value pairs that describe the status of the job execution. If not specified, the statusDetails are unchanged.
  public let statusDetails: [String: String]?

  /// The expected current version of the job execution. Each time you update the job execution, its version is incremented. If the version of the job execution stored in the AWS IoT Jobs service does not match, the update is rejected with a VersionMismatch error, and an ErrorResponse that contains the current job execution status data is returned.
  public let expectedVersion: Int?

  /// Optional. A number that identifies a job execution on a device. If not specified, the latest job execution is used.
  public let executionNumber: Int?

  /// Optional. When included and set to true, the response contains the JobExecutionState field. The default is false.
  public let includeJobExecutionState: Bool?

  /// Optional. When included and set to true, the response contains the JobDocument. The default is false.
  public let includeJobDocument: Bool?

  /// Specifies the amount of time this device has to finish execution of this job. If the job execution status is not set to a terminal state before this timer expires, or before the timer is reset (by again calling UpdateJobExecution, setting the status to IN_PROGRESS and specifying a new timeout value in this field) the job execution status is set to TIMED_OUT. Setting or resetting this timeout has no effect on the job execution timeout that might have been specified when the job was created (by using CreateJob with the timeoutConfig).
  public let stepTimeoutInMinutes: Int?

  /// Initializes a new `UpdateJobExecutionRequest`
  public init(
    thingName: String, jobId: String, status: JobStatus, statusDetails: [String: String]? = nil,
    expectedVersion: Int? = nil, executionNumber: Int? = nil, includeJobExecutionState: Bool? = nil,
    includeJobDocument: Bool? = nil, stepTimeoutInMinutes: Int? = nil
  ) {
    self.thingName = thingName
    self.jobId = jobId
    self.status = status
    self.statusDetails = statusDetails
    self.expectedVersion = expectedVersion
    self.executionNumber = executionNumber
    self.includeJobExecutionState = includeJobExecutionState
    self.includeJobDocument = includeJobDocument
    self.stepTimeoutInMinutes = stepTimeoutInMinutes
  }

}

/// Data needed to subscribe to DescribeJobExecution responses.
///
final public class DescribeJobExecutionSubscriptionRequest: Codable, Sendable {

  /// Name of the IoT Thing that you want to subscribe to DescribeJobExecution response events for.
  public let thingName: String

  /// Job ID that you want to subscribe to DescribeJobExecution response events for.
  public let jobId: String

  /// Initializes a new `DescribeJobExecutionSubscriptionRequest`
  public init(
    thingName: String, jobId: String
  ) {
    self.thingName = thingName
    self.jobId = jobId
  }

}

/// Data needed to subscribe to GetPendingJobExecutions responses.
///
final public class GetPendingJobExecutionsSubscriptionRequest: Codable, Sendable {

  /// Name of the IoT Thing that you want to subscribe to GetPendingJobExecutions response events for.
  public let thingName: String

  /// Initializes a new `GetPendingJobExecutionsSubscriptionRequest`
  public init(
    thingName: String
  ) {
    self.thingName = thingName
  }

}

/// Data needed to subscribe to JobExecutionsChanged events.
///
final public class JobExecutionsChangedSubscriptionRequest: Codable, Sendable {

  /// Name of the IoT Thing that you want to subscribe to JobExecutionsChanged events for.
  public let thingName: String

  /// Initializes a new `JobExecutionsChangedSubscriptionRequest`
  public init(
    thingName: String
  ) {
    self.thingName = thingName
  }

}

/// Data needed to subscribe to NextJobExecutionChanged events.
///
final public class NextJobExecutionChangedSubscriptionRequest: Codable, Sendable {

  /// Name of the IoT Thing that you want to subscribe to NextJobExecutionChanged events for.
  public let thingName: String

  /// Initializes a new `NextJobExecutionChangedSubscriptionRequest`
  public init(
    thingName: String
  ) {
    self.thingName = thingName
  }

}

/// Data needed to subscribe to StartNextPendingJobExecution responses.
///
final public class StartNextPendingJobExecutionSubscriptionRequest: Codable, Sendable {

  /// Name of the IoT Thing that you want to subscribe to StartNextPendingJobExecution response events for.
  public let thingName: String

  /// Initializes a new `StartNextPendingJobExecutionSubscriptionRequest`
  public init(
    thingName: String
  ) {
    self.thingName = thingName
  }

}

/// Data needed to subscribe to UpdateJobExecution responses.
///
final public class UpdateJobExecutionSubscriptionRequest: Codable, Sendable {

  /// Name of the IoT Thing that you want to subscribe to UpdateJobExecution response events for.
  public let thingName: String

  /// Job ID that you want to subscribe to UpdateJobExecution response events for.
  public let jobId: String

  /// Initializes a new `UpdateJobExecutionSubscriptionRequest`
  public init(
    thingName: String, jobId: String
  ) {
    self.thingName = thingName
    self.jobId = jobId
  }

}

/// Response document containing details about a failed request.
///
final public class RejectedError: Codable, Sendable {

  /// Indicates the type of error.
  public let code: RejectedErrorCode

  /// A text message that provides additional information.
  public let message: String?

  /// The date and time the response was generated by AWS IoT.
  public let timestamp: Foundation.Date?

  /// A JobExecutionState object. This field is included only when the code field has the value InvalidStateTransition or VersionMismatch.
  public let executionState: JobExecutionState?

  /// Initializes a new `RejectedError`
  public init(
    code: RejectedErrorCode, message: String? = nil, timestamp: Foundation.Date? = nil,
    executionState: JobExecutionState? = nil
  ) {
    self.code = code
    self.message = message
    self.timestamp = timestamp
    self.executionState = executionState
  }

}

/// Response document containing details about a failed request.
///
final public class V2ErrorResponse: Codable, Sendable {

  /// Indicates the type of error.
  public let code: RejectedErrorCode

  /// A text message that provides additional information.
  public let message: String?

  /// The date and time the response was generated by AWS IoT.
  public let timestamp: Foundation.Date?

  /// A JobExecutionState object. This field is included only when the code field has the value InvalidStateTransition or VersionMismatch.
  public let executionState: JobExecutionState?

  /// Initializes a new `V2ErrorResponse`
  public init(
    code: RejectedErrorCode, message: String? = nil, timestamp: Foundation.Date? = nil,
    executionState: JobExecutionState? = nil
  ) {
    self.code = code
    self.message = message
    self.timestamp = timestamp
    self.executionState = executionState
  }

}

/// Response payload to a DescribeJobExecution request.
///
final public class DescribeJobExecutionResponse: Codable, Sendable {

  /// Contains data about a job execution.
  public let execution: JobExecutionData

  /// The time when the message was sent.
  public let timestamp: Foundation.Date

  /// Initializes a new `DescribeJobExecutionResponse`
  public init(
    execution: JobExecutionData, timestamp: Foundation.Date
  ) {
    self.execution = execution
    self.timestamp = timestamp
  }

}

/// Response payload to a GetPendingJobExecutions request.
///
final public class GetPendingJobExecutionsResponse: Codable, Sendable {

  /// A list of JobExecutionSummary objects with status IN_PROGRESS.
  public let inProgressJobs: [JobExecutionSummary]?

  /// A list of JobExecutionSummary objects with status QUEUED.
  public let queuedJobs: [JobExecutionSummary]?

  /// The time when the message was sent.
  public let timestamp: Foundation.Date?

  /// Initializes a new `GetPendingJobExecutionsResponse`
  public init(
    inProgressJobs: [JobExecutionSummary]? = nil, queuedJobs: [JobExecutionSummary]? = nil,
    timestamp: Foundation.Date? = nil
  ) {
    self.inProgressJobs = inProgressJobs
    self.queuedJobs = queuedJobs
    self.timestamp = timestamp
  }

}

/// Response payload to a StartNextJobExecution request.
///
final public class StartNextJobExecutionResponse: Codable, Sendable {

  /// Contains data about a job execution.
  public let execution: JobExecutionData?

  /// The time when the message was sent to the device.
  public let timestamp: Foundation.Date?

  /// Initializes a new `StartNextJobExecutionResponse`
  public init(
    execution: JobExecutionData? = nil, timestamp: Foundation.Date? = nil
  ) {
    self.execution = execution
    self.timestamp = timestamp
  }

}

/// Response payload to an UpdateJobExecution request.
///
final public class UpdateJobExecutionResponse: Codable, Sendable {

  /// The time when the message was sent.
  public let timestamp: Foundation.Date

  /// Contains data about the state of a job execution.
  public let executionState: JobExecutionState?

  /// A UTF-8 encoded JSON document that contains information that your devices need to perform the job.
  private let jobDocumentInternal: [String: JSONValue]?

  /// Initializes a new `UpdateJobExecutionResponse`
  public init(
    executionState: JobExecutionState? = nil, jobDocument: [String: Any]? = nil,
    timestamp: Foundation.Date
  ) {
    self.executionState = executionState
    self.jobDocumentInternal = jobDocument?.asJSONValueDictionary()
    self.timestamp = timestamp
  }

  enum CodingKeys: String, CodingKey {
    case executionState
    case jobDocument
    case timestamp
  }

  public var jobDocument: [String: Any]? {
    return jobDocumentInternal?.asAnyDictionary()
  }

  /// initialize this class containing the document trait from JSON
  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.timestamp = try container.decode(Foundation.Date.self, forKey: .timestamp)
    self.executionState = try container.decodeIfPresent(
      JobExecutionState.self, forKey: .executionState)
    let jobDocumentJSON = try container.decodeIfPresent(
      [String: JSONValue].self, forKey: .jobDocument)
    self.jobDocumentInternal = jobDocumentJSON
  }

  /// encode this class containing the document trait into JSON
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(timestamp, forKey: .timestamp)
    try container.encode(executionState, forKey: .executionState)
    if let jobDocumentInternal = jobDocumentInternal {
      try container.encode(jobDocumentInternal, forKey: .jobDocument)
    }
  }
}

/// Sent whenever a job execution is added to or removed from the list of pending job executions for a thing.
///
final public class JobExecutionsChangedEvent: Codable, Sendable {

  /// Map from JobStatus to a list of Jobs transitioning to that status.
  public let jobs: [JobStatus: [JobExecutionSummary]]

  /// The time when the message was sent.
  public let timestamp: Foundation.Date

  /// Initializes a new `JobExecutionsChangedEvent`
  public init(
    jobs: [JobStatus: [JobExecutionSummary]], timestamp: Foundation.Date
  ) {
    self.jobs = jobs
    self.timestamp = timestamp
  }

}

/// Sent whenever there is a change to which job execution is next on the list of pending job executions for a thing, as defined for DescribeJobExecution with jobId $next. This message is not sent when the next job's execution details change, only when the next job that would be returned by DescribeJobExecution with jobId $next has changed.
///
final public class NextJobExecutionChangedEvent: Codable, Sendable {

  /// The time when the message was sent.
  public let timestamp: Foundation.Date

  /// Contains data about a job execution.
  public let execution: JobExecutionData?

  /// Initializes a new `NextJobExecutionChangedEvent`
  public init(
    execution: JobExecutionData? = nil, timestamp: Foundation.Date
  ) {
    self.execution = execution
    self.timestamp = timestamp
  }

}

/// A value indicating the kind of error encountered while processing an AWS IoT Jobs request
public enum RejectedErrorCode: String, Codable, Sendable, CodingKeyRepresentable {

  /// The request was sent to a topic in the AWS IoT Jobs namespace that does not map to any API.
  case INVALID_TOPIC = "InvalidTopic"

  /// The contents of the request could not be interpreted as valid UTF-8-encoded JSON.
  case INVALID_JSON = "InvalidJson"

  /// The contents of the request were invalid. The message contains details about the error.
  case INVALID_REQUEST = "InvalidRequest"

  /// An update attempted to change the job execution to a state that is invalid because of the job execution's current state. In this case, the body of the error message also contains the executionState field.
  case INVALID_STATE_TRANSITION = "InvalidStateTransition"

  /// The JobExecution specified by the request topic does not exist.
  case RESOURCE_NOT_FOUND = "ResourceNotFound"

  /// The expected version specified in the request does not match the version of the job execution in the AWS IoT Jobs service. In this case, the body of the error message also contains the executionState field.
  case VERSION_MISMATCH = "VersionMismatch"

  /// There was an internal error during the processing of the request.
  case INTERNAL_ERROR = "InternalError"

  /// The request was throttled.
  case REQUEST_THROTTLED = "RequestThrottled"

  /// Occurs when a command to describe a job is performed on a job that is in a terminal state.
  case TERMINAL_STATE_REACHED = "TerminalStateReached"

}

/// Configuration options for streaming operations created from service clients
///
/// `Event` is the Type that the stream deserializes MQTT payload messages into
public struct ClientStreamOptions<Event: Sendable>: Sendable {
  // Type-aliases for clarity
  public typealias StreamHandler = @Sendable (Event) -> Void
  public typealias SubscriptionHandler = @Sendable (SubscriptionStatusEvent) -> Void
  public typealias FailureHandler = @Sendable (DeserializationFailureEvent) -> Void

  // Stored properties (all immutable -> thread-safe)
  public let streamEventHandler: StreamHandler
  public let subscriptionEventHandler: SubscriptionHandler
  public let deserializationFailureHandler: FailureHandler

  /// Initializes a new `ClientStreamOptions`
  ///
  /// - Parameters:
  ///   - streamEventHandler: the callback the stream should invoke on a successfully deserialized message.
  ///   - subscriptionEventHandler: the callback the stream should invoke when something changes about the underlying subscription.
  ///   - deserializationFailureHandler: the callback the stream should invoke when a message fails to deserialize.
  public init(
    streamEventHandler: @escaping StreamHandler = { _ in },
    subscriptionEventHandler: @escaping SubscriptionHandler = { _ in },
    deserializationFailureHandler: @escaping FailureHandler = { _ in }
  ) {
    self.streamEventHandler = streamEventHandler
    self.subscriptionEventHandler = subscriptionEventHandler
    self.deserializationFailureHandler = deserializationFailureHandler
  }
}

/// An event emitted by a streaming operation when an incoming message fails to deserialize
public struct DeserializationFailureEvent: Sendable {

  /// The decoding error that triggered the failure.
  public let cause: Error

  /// Raw MQTT payload that failed to decode.
  public let payload: Data

  /// Topic from which the payload was received.
  public let topic: String

  /// Initializes a new `DeserializationFailureEvent`
  ///
  /// - Parameters:
  ///   - cause: sets the `Error` that triggered the failure.
  ///   - payload: the payload of the message that triggered the failure.
  ///   - topic: the topic of the message that triggered the failure.
  internal init(cause: Error, payload: Data, topic: String) {
    self.cause = cause
    self.payload = payload
    self.topic = topic
  }
}

/// The status of the job execution.
public enum JobStatus: String, Codable, Sendable, CodingKeyRepresentable {

  case QUEUED = "QUEUED"

  case IN_PROGRESS = "IN_PROGRESS"

  case TIMED_OUT = "TIMED_OUT"

  case FAILED = "FAILED"

  case SUCCEEDED = "SUCCEEDED"

  case CANCELED = "CANCELED"

  case REJECTED = "REJECTED"

  case REMOVED = "REMOVED"

}

/// Use the `IotJobsClientError` enum to surface *all* errors thrown by the
/// IotJobsClient. The three cases preserve the original error intact so
/// callers can inspect, log, or switch on them.
public enum IotJobsClientError: Error, Sendable {
  /// A low-level error reported by aws-crt-swift.
  /// These errors correspond to the values returned by `aws_last_error()` and
  /// include TLS failures, socket errors, mqtt errors, and other transport-layer issues.
  case crt(CRTError)

  /// The service accepted the request frame but *rejected* it,
  /// returning a structured payload that conforms to the protocol `ServiceError`.
  case errorResponse(V2ErrorResponse)

  /// Any other Swift error the client didn't recognise.
  /// Examples include JSON decoding failures, time-outs thrown by the
  /// concurrency runtime, and user-provided call-backs that threw.
  case underlying(Error)
}
