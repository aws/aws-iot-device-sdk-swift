// Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
// SPDX-License-Identifier: Apache-2.0.

// This file is generated

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
        self.rrClient = try MqttRequestResponseClient.newFromMqtt5Client(
            mqtt5Client: mqttClient, options: options)
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
    ) async throws -> StreamingOperation {
        var topic: String = "$aws/things/{thingName}/jobs/notify"
        topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)

        let innerOptions: StreamingOperationOptions = StreamingOperationOptions(
            topicFilter: topic,
            subscriptionStatusCallback: { status in
                options.subscriptionEventHandler(status)
            },
            incomingPublishCallback: { publish in
                do {
                    let event = try self.decoder.decode(
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
    ) async throws -> StreamingOperation {
        var topic: String = "$aws/things/{thingName}/jobs/notify-next"
        topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)

        let innerOptions: StreamingOperationOptions = StreamingOperationOptions(
            topicFilter: topic,
            subscriptionStatusCallback: { status in
                options.subscriptionEventHandler(status)
            },
            incomingPublishCallback: { publish in
                do {
                    let event = try self.decoder.decode(
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
    /// - Returns:
    ///     - `DescribeJobExecutionResponse`: with the corresponding response.
    ///
    /// - Throws:
    ///     - `IotJobsClientError`
    public func describeJobExecution(request: DescribeJobExecutionRequest) async throws
        -> DescribeJobExecutionResponse
    {
        var correlationToken: String? = nil
        correlationToken = UUID().uuidString
        request.clientToken = correlationToken

        // Publish Topic
        var topic: String = "$aws/things/{thingName}/jobs/{jobId}/get"
        topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)
        topic = topic.replacingOccurrences(of: "{jobId}", with: request.jobId)

        // Subscription Topic Filters
        var subscriptionTopicFilters: [String] = []
        var subscription0: String = "$aws/things/{thingName}/jobs/{jobId}/get/+"
        subscription0 = subscription0.replacingOccurrences(
            of: "{thingName}", with: request.thingName)
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

            if response.topic == responseTopic1 {
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
    /// - Returns:
    ///     - `GetPendingJobExecutionsResponse`: with the corresponding response.
    ///
    /// - Throws:
    ///     - `IotJobsClientError`
    public func getPendingJobExecutions(request: GetPendingJobExecutionsRequest) async throws
        -> GetPendingJobExecutionsResponse
    {
        var correlationToken: String? = nil
        correlationToken = UUID().uuidString
        request.clientToken = correlationToken

        // Publish Topic
        var topic: String = "$aws/things/{thingName}/jobs/get"
        topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)

        // Subscription Topic Filters
        var subscriptionTopicFilters: [String] = []
        var subscription0: String = "$aws/things/{thingName}/jobs/get/+"
        subscription0 = subscription0.replacingOccurrences(
            of: "{thingName}", with: request.thingName)
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

            if response.topic == responseTopic1 {
                // Successful operation ack returns the expected output.
                return try decoder.decode(
                    GetPendingJobExecutionsResponse.self, from: response.payload)
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
    /// - Returns:
    ///     - `StartNextJobExecutionResponse`: with the corresponding response.
    ///
    /// - Throws:
    ///     - `IotJobsClientError`
    public func startNextPendingJobExecution(request: StartNextPendingJobExecutionRequest)
        async throws -> StartNextJobExecutionResponse
    {
        var correlationToken: String? = nil
        correlationToken = UUID().uuidString
        request.clientToken = correlationToken

        // Publish Topic
        var topic: String = "$aws/things/{thingName}/jobs/start-next"
        topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)

        // Subscription Topic Filters
        var subscriptionTopicFilters: [String] = []
        var subscription0: String = "$aws/things/{thingName}/jobs/start-next/+"
        subscription0 = subscription0.replacingOccurrences(
            of: "{thingName}", with: request.thingName)
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

            if response.topic == responseTopic1 {
                // Successful operation ack returns the expected output.
                return try decoder.decode(
                    StartNextJobExecutionResponse.self, from: response.payload)
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
    /// - Returns:
    ///     - `UpdateJobExecutionResponse`: with the corresponding response.
    ///
    /// - Throws:
    ///     - `IotJobsClientError`
    public func updateJobExecution(request: UpdateJobExecutionRequest) async throws
        -> UpdateJobExecutionResponse
    {
        var correlationToken: String? = nil
        correlationToken = UUID().uuidString
        request.clientToken = correlationToken

        // Publish Topic
        var topic: String = "$aws/things/{thingName}/jobs/{jobId}/update"
        topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)
        topic = topic.replacingOccurrences(of: "{jobId}", with: request.jobId)

        // Subscription Topic Filters
        var subscriptionTopicFilters: [String] = []
        var subscription0: String = "$aws/things/{thingName}/jobs/{jobId}/update/+"
        subscription0 = subscription0.replacingOccurrences(
            of: "{thingName}", with: request.thingName)
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

            if response.topic == responseTopic1 {
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
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class JobExecutionSummary: Codable {

    /// The unique identifier you assigned to this job when it was created.
    public var jobId: String?

    /// A number that identifies a job execution on a device.
    public var executionNumber: Int?

    /// The version of the job execution. Job execution versions are incremented each time the AWS IoT Jobs service receives an update from a device.
    public var versionNumber: Int?

    /// The time when the job execution was last updated.
    public var lastUpdatedAt: Foundation.Date?

    /// The time when the job execution was enqueued.
    public var queuedAt: Foundation.Date?

    /// The time when the job execution started.
    public var startedAt: Foundation.Date?

    /// Initializes a new `JobExecutionSummary`
    public init() {
        self.jobId = nil
        self.executionNumber = nil
        self.versionNumber = nil
        self.lastUpdatedAt = nil
        self.queuedAt = nil
        self.startedAt = nil
    }

    /// Assign the jobId property a `JobExecutionSummary` value
    ///
    /// - Parameters:
    ///   - jobId: `String` The unique identifier you assigned to this job when it was created.
    public func withJobId(jobId: String) {
        self.jobId = jobId
    }

    /// Assign the executionNumber property a `JobExecutionSummary` value
    ///
    /// - Parameters:
    ///   - executionNumber: `Int` A number that identifies a job execution on a device.
    public func withExecutionNumber(executionNumber: Int) {
        self.executionNumber = executionNumber
    }

    /// Assign the versionNumber property a `JobExecutionSummary` value
    ///
    /// - Parameters:
    ///   - versionNumber: `Int` The version of the job execution. Job execution versions are incremented each time the AWS IoT Jobs service receives an update from a device.
    public func withVersionNumber(versionNumber: Int) {
        self.versionNumber = versionNumber
    }

    /// Assign the lastUpdatedAt property a `JobExecutionSummary` value
    ///
    /// - Parameters:
    ///   - lastUpdatedAt: `Foundation.Date` The time when the job execution was last updated.
    public func withLastUpdatedAt(lastUpdatedAt: Foundation.Date) {
        self.lastUpdatedAt = lastUpdatedAt
    }

    /// Assign the queuedAt property a `JobExecutionSummary` value
    ///
    /// - Parameters:
    ///   - queuedAt: `Foundation.Date` The time when the job execution was enqueued.
    public func withQueuedAt(queuedAt: Foundation.Date) {
        self.queuedAt = queuedAt
    }

    /// Assign the startedAt property a `JobExecutionSummary` value
    ///
    /// - Parameters:
    ///   - startedAt: `Foundation.Date` The time when the job execution started.
    public func withStartedAt(startedAt: Foundation.Date) {
        self.startedAt = startedAt
    }

}

/// Data about a job execution.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class JobExecutionData: Codable {

    /// The unique identifier you assigned to this job when it was created.
    public var jobId: String?

    /// The name of the thing that is executing the job.
    public var thingName: String?

    /// The content of the job document.
    public var jobDocument: [String: Any]?

    /// The status of the job execution. Can be one of: QUEUED, IN_PROGRESS, FAILED, SUCCEEDED, CANCELED, TIMED_OUT, REJECTED, or REMOVED.
    public var status: JobStatus?

    /// A collection of name-value pairs that describe the status of the job execution.
    public var statusDetails: [String: String]?

    /// The time when the job execution was enqueued.
    public var queuedAt: Foundation.Date?

    /// The time when the job execution started.
    public var startedAt: Foundation.Date?

    /// The time when the job execution started.
    public var lastUpdatedAt: Foundation.Date?

    /// The version of the job execution. Job execution versions are incremented each time they are updated by a device.
    public var versionNumber: Int?

    /// A number that identifies a job execution on a device. It can be used later in commands that return or update job execution information.
    public var executionNumber: Int?

    /// Initializes a new `JobExecutionData`
    public init() {
        self.jobId = nil
        self.thingName = nil
        self.jobDocument = nil
        self.status = nil
        self.statusDetails = nil
        self.queuedAt = nil
        self.startedAt = nil
        self.lastUpdatedAt = nil
        self.versionNumber = nil
        self.executionNumber = nil
    }

    /// Assign the jobId property a `JobExecutionData` value
    ///
    /// - Parameters:
    ///   - jobId: `String` The unique identifier you assigned to this job when it was created.
    public func withJobId(jobId: String) {
        self.jobId = jobId
    }

    /// Assign the thingName property a `JobExecutionData` value
    ///
    /// - Parameters:
    ///   - thingName: `String` The name of the thing that is executing the job.
    public func withThingName(thingName: String) {
        self.thingName = thingName
    }

    /// Assign the jobDocument property a `JobExecutionData` value
    ///
    /// - Parameters:
    ///   - jobDocument: `[String: Any]` The content of the job document.
    public func withJobDocument(jobDocument: [String: Any]) {
        self.jobDocument = jobDocument
    }

    /// Assign the status property a `JobExecutionData` value
    ///
    /// - Parameters:
    ///   - status: `JobStatus` The status of the job execution. Can be one of: QUEUED, IN_PROGRESS, FAILED, SUCCEEDED, CANCELED, TIMED_OUT, REJECTED, or REMOVED.
    public func withStatus(status: JobStatus) {
        self.status = status
    }

    /// Assign the statusDetails property a `JobExecutionData` value
    ///
    /// - Parameters:
    ///   - statusDetails: `[String: String]` A collection of name-value pairs that describe the status of the job execution.
    public func withStatusDetails(statusDetails: [String: String]) {
        self.statusDetails = statusDetails
    }

    /// Assign the queuedAt property a `JobExecutionData` value
    ///
    /// - Parameters:
    ///   - queuedAt: `Foundation.Date` The time when the job execution was enqueued.
    public func withQueuedAt(queuedAt: Foundation.Date) {
        self.queuedAt = queuedAt
    }

    /// Assign the startedAt property a `JobExecutionData` value
    ///
    /// - Parameters:
    ///   - startedAt: `Foundation.Date` The time when the job execution started.
    public func withStartedAt(startedAt: Foundation.Date) {
        self.startedAt = startedAt
    }

    /// Assign the lastUpdatedAt property a `JobExecutionData` value
    ///
    /// - Parameters:
    ///   - lastUpdatedAt: `Foundation.Date` The time when the job execution started.
    public func withLastUpdatedAt(lastUpdatedAt: Foundation.Date) {
        self.lastUpdatedAt = lastUpdatedAt
    }

    /// Assign the versionNumber property a `JobExecutionData` value
    ///
    /// - Parameters:
    ///   - versionNumber: `Int` The version of the job execution. Job execution versions are incremented each time they are updated by a device.
    public func withVersionNumber(versionNumber: Int) {
        self.versionNumber = versionNumber
    }

    /// Assign the executionNumber property a `JobExecutionData` value
    ///
    /// - Parameters:
    ///   - executionNumber: `Int` A number that identifies a job execution on a device. It can be used later in commands that return or update job execution information.
    public func withExecutionNumber(executionNumber: Int) {
        self.executionNumber = executionNumber
    }

    enum CodingKeys: String, CodingKey {
        case jobId,
            thingName,
            jobDocument,
            status,
            statusDetails,
            queuedAt,
            startedAt,
            lastUpdatedAt,
            versionNumber,
            executionNumber
    }

    /// initialize this class containing the document trait from JSON
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.jobId = try container.decodeIfPresent(String.self, forKey: .jobId)
        self.thingName = try container.decodeIfPresent(String.self, forKey: .thingName)
        let jobDocumentJSON = try container.decodeIfPresent(
            [String: JSONValue].self, forKey: .jobDocument)
        self.jobDocument = jobDocumentJSON?.asAnyDictionary()
        self.status = try container.decodeIfPresent(JobStatus.self, forKey: .status)
        self.statusDetails = try container.decodeIfPresent(
            [String: String].self, forKey: .statusDetails)
        self.queuedAt = try container.decodeIfPresent(Foundation.Date.self, forKey: .queuedAt)
        self.startedAt = try container.decodeIfPresent(Foundation.Date.self, forKey: .startedAt)
        self.lastUpdatedAt = try container.decodeIfPresent(
            Foundation.Date.self, forKey: .lastUpdatedAt)
        self.versionNumber = try container.decodeIfPresent(Int.self, forKey: .versionNumber)
        self.executionNumber = try container.decodeIfPresent(Int.self, forKey: .executionNumber)
    }

    /// encode this class containing the document trait into JSON
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jobId, forKey: .jobId)
        try container.encode(thingName, forKey: .thingName)
        if let jobDocument = jobDocument {
            let jobDocumentJSON = jobDocument.asJSONValueDictionary()
            try container.encode(jobDocumentJSON, forKey: .jobDocument)
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
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class JobExecutionState: Codable {

    /// The status of the job execution. Can be one of: QUEUED, IN_PROGRESS, FAILED, SUCCEEDED, CANCELED, TIMED_OUT, REJECTED, or REMOVED.
    public var status: JobStatus?

    /// A collection of name-value pairs that describe the status of the job execution.
    public var statusDetails: [String: String]?

    /// The version of the job execution. Job execution versions are incremented each time they are updated by a device.
    public var versionNumber: Int?

    /// Initializes a new `JobExecutionState`
    public init() {
        self.status = nil
        self.statusDetails = nil
        self.versionNumber = nil
    }

    /// Assign the status property a `JobExecutionState` value
    ///
    /// - Parameters:
    ///   - status: `JobStatus` The status of the job execution. Can be one of: QUEUED, IN_PROGRESS, FAILED, SUCCEEDED, CANCELED, TIMED_OUT, REJECTED, or REMOVED.
    public func withStatus(status: JobStatus) {
        self.status = status
    }

    /// Assign the statusDetails property a `JobExecutionState` value
    ///
    /// - Parameters:
    ///   - statusDetails: `[String: String]` A collection of name-value pairs that describe the status of the job execution.
    public func withStatusDetails(statusDetails: [String: String]) {
        self.statusDetails = statusDetails
    }

    /// Assign the versionNumber property a `JobExecutionState` value
    ///
    /// - Parameters:
    ///   - versionNumber: `Int` The version of the job execution. Job execution versions are incremented each time they are updated by a device.
    public func withVersionNumber(versionNumber: Int) {
        self.versionNumber = versionNumber
    }

}

/// Data needed to make a DescribeJobExecution request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class DescribeJobExecutionRequest: Codable {

    /// The name of the thing associated with the device.
    public var thingName: String

    /// The unique identifier assigned to this job when it was created. Or use $next to return the next pending job execution for a thing (status IN_PROGRESS or QUEUED). In this case, any job executions with status IN_PROGRESS are returned first. Job executions are returned in the order in which they were created.
    public var jobId: String

    /// An opaque string used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public var clientToken: String?

    /// Optional. A number that identifies a job execution on a device. If not specified, the latest job execution is returned.
    public var executionNumber: Int?

    /// Optional. Unless set to false, the response contains the job document. The default is true.
    public var includeJobDocument: Bool?

    /// Initializes a new `DescribeJobExecutionRequest`
    ///
    /// - Parameters:
    ///   - thingName: `String` The name of the thing associated with the device.
    ///   - jobId: `String` The unique identifier assigned to this job when it was created. Or use $next to return the next pending job execution for a thing (status IN_PROGRESS or QUEUED). In this case, any job executions with status IN_PROGRESS are returned first. Job executions are returned in the order in which they were created.
    public init(
        thingName: String,
        jobId: String
    ) {
        self.thingName = thingName
        self.jobId = jobId
        self.clientToken = nil
        self.executionNumber = nil
        self.includeJobDocument = nil
    }

    /// Assign the clientToken property a `DescribeJobExecutionRequest` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` An opaque string used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

    /// Assign the executionNumber property a `DescribeJobExecutionRequest` value
    ///
    /// - Parameters:
    ///   - executionNumber: `Int` Optional. A number that identifies a job execution on a device. If not specified, the latest job execution is returned.
    public func withExecutionNumber(executionNumber: Int) {
        self.executionNumber = executionNumber
    }

    /// Assign the includeJobDocument property a `DescribeJobExecutionRequest` value
    ///
    /// - Parameters:
    ///   - includeJobDocument: `Bool` Optional. Unless set to false, the response contains the job document. The default is true.
    public func withIncludeJobDocument(includeJobDocument: Bool) {
        self.includeJobDocument = includeJobDocument
    }

}

/// Data needed to make a GetPendingJobExecutions request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class GetPendingJobExecutionsRequest: Codable {

    /// IoT Thing the request is relative to.
    public var thingName: String

    /// Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public var clientToken: String?

    /// Initializes a new `GetPendingJobExecutionsRequest`
    ///
    /// - Parameters:
    ///   - thingName: `String` IoT Thing the request is relative to.
    public init(thingName: String) {
        self.thingName = thingName
        self.clientToken = nil
    }

    /// Assign the clientToken property a `GetPendingJobExecutionsRequest` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

}

/// Data needed to make a StartNextPendingJobExecution request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class StartNextPendingJobExecutionRequest: Codable {

    /// IoT Thing the request is relative to.
    public var thingName: String

    /// Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public var clientToken: String?

    /// Specifies the amount of time this device has to finish execution of this job.
    public var stepTimeoutInMinutes: Int?

    /// A collection of name-value pairs that describe the status of the job execution. If not specified, the statusDetails are unchanged.
    public var statusDetails: [String: String]?

    /// Initializes a new `StartNextPendingJobExecutionRequest`
    ///
    /// - Parameters:
    ///   - thingName: `String` IoT Thing the request is relative to.
    public init(thingName: String) {
        self.thingName = thingName
        self.clientToken = nil
        self.stepTimeoutInMinutes = nil
        self.statusDetails = nil
    }

    /// Assign the clientToken property a `StartNextPendingJobExecutionRequest` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

    /// Assign the stepTimeoutInMinutes property a `StartNextPendingJobExecutionRequest` value
    ///
    /// - Parameters:
    ///   - stepTimeoutInMinutes: `Int` Specifies the amount of time this device has to finish execution of this job.
    public func withStepTimeoutInMinutes(stepTimeoutInMinutes: Int) {
        self.stepTimeoutInMinutes = stepTimeoutInMinutes
    }

    /// Assign the statusDetails property a `StartNextPendingJobExecutionRequest` value
    ///
    /// - Parameters:
    ///   - statusDetails: `[String: String]` A collection of name-value pairs that describe the status of the job execution. If not specified, the statusDetails are unchanged.
    public func withStatusDetails(statusDetails: [String: String]) {
        self.statusDetails = statusDetails
    }

}

/// Data needed to make an UpdateJobExecution request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class UpdateJobExecutionRequest: Codable {

    /// The name of the thing associated with the device.
    public var thingName: String

    /// The unique identifier assigned to this job when it was created.
    public var jobId: String

    /// The new status for the job execution (IN_PROGRESS, FAILED, SUCCEEDED, or REJECTED). This must be specified on every update.
    public var status: JobStatus

    /// A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public var clientToken: String?

    /// A collection of name-value pairs that describe the status of the job execution. If not specified, the statusDetails are unchanged.
    public var statusDetails: [String: String]?

    /// The expected current version of the job execution. Each time you update the job execution, its version is incremented. If the version of the job execution stored in the AWS IoT Jobs service does not match, the update is rejected with a VersionMismatch error, and an ErrorResponse that contains the current job execution status data is returned.
    public var expectedVersion: Int?

    /// Optional. A number that identifies a job execution on a device. If not specified, the latest job execution is used.
    public var executionNumber: Int?

    /// Optional. When included and set to true, the response contains the JobExecutionState field. The default is false.
    public var includeJobExecutionState: Bool?

    /// Optional. When included and set to true, the response contains the JobDocument. The default is false.
    public var includeJobDocument: Bool?

    /// Specifies the amount of time this device has to finish execution of this job. If the job execution status is not set to a terminal state before this timer expires, or before the timer is reset (by again calling UpdateJobExecution, setting the status to IN_PROGRESS and specifying a new timeout value in this field) the job execution status is set to TIMED_OUT. Setting or resetting this timeout has no effect on the job execution timeout that might have been specified when the job was created (by using CreateJob with the timeoutConfig).
    public var stepTimeoutInMinutes: Int?

    /// Initializes a new `UpdateJobExecutionRequest`
    ///
    /// - Parameters:
    ///   - thingName: `String` The name of the thing associated with the device.
    ///   - jobId: `String` The unique identifier assigned to this job when it was created.
    ///   - status: `JobStatus` The new status for the job execution (IN_PROGRESS, FAILED, SUCCEEDED, or REJECTED). This must be specified on every update.
    public init(
        thingName: String,
        jobId: String,
        status: JobStatus
    ) {
        self.thingName = thingName
        self.jobId = jobId
        self.status = status
        self.clientToken = nil
        self.statusDetails = nil
        self.expectedVersion = nil
        self.executionNumber = nil
        self.includeJobExecutionState = nil
        self.includeJobDocument = nil
        self.stepTimeoutInMinutes = nil
    }

    /// Assign the clientToken property a `UpdateJobExecutionRequest` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

    /// Assign the statusDetails property a `UpdateJobExecutionRequest` value
    ///
    /// - Parameters:
    ///   - statusDetails: `[String: String]` A collection of name-value pairs that describe the status of the job execution. If not specified, the statusDetails are unchanged.
    public func withStatusDetails(statusDetails: [String: String]) {
        self.statusDetails = statusDetails
    }

    /// Assign the expectedVersion property a `UpdateJobExecutionRequest` value
    ///
    /// - Parameters:
    ///   - expectedVersion: `Int` The expected current version of the job execution. Each time you update the job execution, its version is incremented. If the version of the job execution stored in the AWS IoT Jobs service does not match, the update is rejected with a VersionMismatch error, and an ErrorResponse that contains the current job execution status data is returned.
    public func withExpectedVersion(expectedVersion: Int) {
        self.expectedVersion = expectedVersion
    }

    /// Assign the executionNumber property a `UpdateJobExecutionRequest` value
    ///
    /// - Parameters:
    ///   - executionNumber: `Int` Optional. A number that identifies a job execution on a device. If not specified, the latest job execution is used.
    public func withExecutionNumber(executionNumber: Int) {
        self.executionNumber = executionNumber
    }

    /// Assign the includeJobExecutionState property a `UpdateJobExecutionRequest` value
    ///
    /// - Parameters:
    ///   - includeJobExecutionState: `Bool` Optional. When included and set to true, the response contains the JobExecutionState field. The default is false.
    public func withIncludeJobExecutionState(includeJobExecutionState: Bool) {
        self.includeJobExecutionState = includeJobExecutionState
    }

    /// Assign the includeJobDocument property a `UpdateJobExecutionRequest` value
    ///
    /// - Parameters:
    ///   - includeJobDocument: `Bool` Optional. When included and set to true, the response contains the JobDocument. The default is false.
    public func withIncludeJobDocument(includeJobDocument: Bool) {
        self.includeJobDocument = includeJobDocument
    }

    /// Assign the stepTimeoutInMinutes property a `UpdateJobExecutionRequest` value
    ///
    /// - Parameters:
    ///   - stepTimeoutInMinutes: `Int` Specifies the amount of time this device has to finish execution of this job. If the job execution status is not set to a terminal state before this timer expires, or before the timer is reset (by again calling UpdateJobExecution, setting the status to IN_PROGRESS and specifying a new timeout value in this field) the job execution status is set to TIMED_OUT. Setting or resetting this timeout has no effect on the job execution timeout that might have been specified when the job was created (by using CreateJob with the timeoutConfig).
    public func withStepTimeoutInMinutes(stepTimeoutInMinutes: Int) {
        self.stepTimeoutInMinutes = stepTimeoutInMinutes
    }

}

/// Data needed to subscribe to DescribeJobExecution responses.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class DescribeJobExecutionSubscriptionRequest: Codable {

    /// Name of the IoT Thing that you want to subscribe to DescribeJobExecution response events for.
    public var thingName: String

    /// Job ID that you want to subscribe to DescribeJobExecution response events for.
    public var jobId: String

    /// Initializes a new `DescribeJobExecutionSubscriptionRequest`
    ///
    /// - Parameters:
    ///   - thingName: `String` Name of the IoT Thing that you want to subscribe to DescribeJobExecution response events for.
    ///   - jobId: `String` Job ID that you want to subscribe to DescribeJobExecution response events for.
    public init(
        thingName: String,
        jobId: String
    ) {
        self.thingName = thingName
        self.jobId = jobId
    }

}

/// Data needed to subscribe to GetPendingJobExecutions responses.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class GetPendingJobExecutionsSubscriptionRequest: Codable {

    /// Name of the IoT Thing that you want to subscribe to GetPendingJobExecutions response events for.
    public var thingName: String

    /// Initializes a new `GetPendingJobExecutionsSubscriptionRequest`
    ///
    /// - Parameters:
    ///   - thingName: `String` Name of the IoT Thing that you want to subscribe to GetPendingJobExecutions response events for.
    public init(thingName: String) {
        self.thingName = thingName
    }

}

/// Data needed to subscribe to JobExecutionsChanged events.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class JobExecutionsChangedSubscriptionRequest: Codable {

    /// Name of the IoT Thing that you want to subscribe to JobExecutionsChanged events for.
    public var thingName: String

    /// Initializes a new `JobExecutionsChangedSubscriptionRequest`
    ///
    /// - Parameters:
    ///   - thingName: `String` Name of the IoT Thing that you want to subscribe to JobExecutionsChanged events for.
    public init(thingName: String) {
        self.thingName = thingName
    }

}

/// Data needed to subscribe to NextJobExecutionChanged events.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class NextJobExecutionChangedSubscriptionRequest: Codable {

    /// Name of the IoT Thing that you want to subscribe to NextJobExecutionChanged events for.
    public var thingName: String

    /// Initializes a new `NextJobExecutionChangedSubscriptionRequest`
    ///
    /// - Parameters:
    ///   - thingName: `String` Name of the IoT Thing that you want to subscribe to NextJobExecutionChanged events for.
    public init(thingName: String) {
        self.thingName = thingName
    }

}

/// Data needed to subscribe to StartNextPendingJobExecution responses.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class StartNextPendingJobExecutionSubscriptionRequest: Codable {

    /// Name of the IoT Thing that you want to subscribe to StartNextPendingJobExecution response events for.
    public var thingName: String

    /// Initializes a new `StartNextPendingJobExecutionSubscriptionRequest`
    ///
    /// - Parameters:
    ///   - thingName: `String` Name of the IoT Thing that you want to subscribe to StartNextPendingJobExecution response events for.
    public init(thingName: String) {
        self.thingName = thingName
    }

}

/// Data needed to subscribe to UpdateJobExecution responses.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class UpdateJobExecutionSubscriptionRequest: Codable {

    /// Name of the IoT Thing that you want to subscribe to UpdateJobExecution response events for.
    public var thingName: String

    /// Job ID that you want to subscribe to UpdateJobExecution response events for.
    public var jobId: String

    /// Initializes a new `UpdateJobExecutionSubscriptionRequest`
    ///
    /// - Parameters:
    ///   - thingName: `String` Name of the IoT Thing that you want to subscribe to UpdateJobExecution response events for.
    ///   - jobId: `String` Job ID that you want to subscribe to UpdateJobExecution response events for.
    public init(
        thingName: String,
        jobId: String
    ) {
        self.thingName = thingName
        self.jobId = jobId
    }

}

/// Response document containing details about a failed request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class RejectedError: Codable {

    /// Opaque token that can correlate this response to the original request.
    public var clientToken: String?

    /// Indicates the type of error.
    public var code: RejectedErrorCode

    /// A text message that provides additional information.
    public var message: String?

    /// The date and time the response was generated by AWS IoT.
    public var timestamp: Foundation.Date?

    /// A JobExecutionState object. This field is included only when the code field has the value InvalidStateTransition or VersionMismatch.
    public var executionState: JobExecutionState?

    /// Initializes a new `RejectedError`
    ///
    /// - Parameters:
    ///   - code: `RejectedErrorCode` Indicates the type of error.
    public init(code: RejectedErrorCode) {
        self.clientToken = nil
        self.code = code
        self.message = nil
        self.timestamp = nil
        self.executionState = nil
    }

    /// Assign the clientToken property a `RejectedError` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` Opaque token that can correlate this response to the original request.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

    /// Assign the message property a `RejectedError` value
    ///
    /// - Parameters:
    ///   - message: `String` A text message that provides additional information.
    public func withMessage(message: String) {
        self.message = message
    }

    /// Assign the timestamp property a `RejectedError` value
    ///
    /// - Parameters:
    ///   - timestamp: `Foundation.Date` The date and time the response was generated by AWS IoT.
    public func withTimestamp(timestamp: Foundation.Date) {
        self.timestamp = timestamp
    }

    /// Assign the executionState property a `RejectedError` value
    ///
    /// - Parameters:
    ///   - executionState: `JobExecutionState` A JobExecutionState object. This field is included only when the code field has the value InvalidStateTransition or VersionMismatch.
    public func withExecutionState(executionState: JobExecutionState) {
        self.executionState = executionState
    }

}

/// Response document containing details about a failed request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class V2ErrorResponse: Codable, @unchecked Sendable {

    /// Opaque token that can correlate this response to the original request.
    public var clientToken: String?

    /// Indicates the type of error.
    public var code: RejectedErrorCode

    /// A text message that provides additional information.
    public var message: String?

    /// The date and time the response was generated by AWS IoT.
    public var timestamp: Foundation.Date?

    /// A JobExecutionState object. This field is included only when the code field has the value InvalidStateTransition or VersionMismatch.
    public var executionState: JobExecutionState?

    /// Initializes a new `V2ErrorResponse`
    ///
    /// - Parameters:
    ///   - code: `RejectedErrorCode` Indicates the type of error.
    public init(code: RejectedErrorCode) {
        self.clientToken = nil
        self.code = code
        self.message = nil
        self.timestamp = nil
        self.executionState = nil
    }

    /// Assign the clientToken property a `V2ErrorResponse` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` Opaque token that can correlate this response to the original request.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

    /// Assign the message property a `V2ErrorResponse` value
    ///
    /// - Parameters:
    ///   - message: `String` A text message that provides additional information.
    public func withMessage(message: String) {
        self.message = message
    }

    /// Assign the timestamp property a `V2ErrorResponse` value
    ///
    /// - Parameters:
    ///   - timestamp: `Foundation.Date` The date and time the response was generated by AWS IoT.
    public func withTimestamp(timestamp: Foundation.Date) {
        self.timestamp = timestamp
    }

    /// Assign the executionState property a `V2ErrorResponse` value
    ///
    /// - Parameters:
    ///   - executionState: `JobExecutionState` A JobExecutionState object. This field is included only when the code field has the value InvalidStateTransition or VersionMismatch.
    public func withExecutionState(executionState: JobExecutionState) {
        self.executionState = executionState
    }

}

/// Response payload to a DescribeJobExecution request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class DescribeJobExecutionResponse: Codable {

    /// A client token used to correlate requests and responses.
    public var clientToken: String?

    /// Contains data about a job execution.
    public var execution: JobExecutionData

    /// The time when the message was sent.
    public var timestamp: Foundation.Date

    /// Initializes a new `DescribeJobExecutionResponse`
    ///
    /// - Parameters:
    ///   - execution: `JobExecutionData` Contains data about a job execution.
    ///   - timestamp: `Foundation.Date` The time when the message was sent.
    public init(
        execution: JobExecutionData,
        timestamp: Foundation.Date
    ) {
        self.clientToken = nil
        self.execution = execution
        self.timestamp = timestamp
    }

    /// Assign the clientToken property a `DescribeJobExecutionResponse` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` A client token used to correlate requests and responses.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

}

/// Response payload to a GetPendingJobExecutions request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class GetPendingJobExecutionsResponse: Codable {

    /// A list of JobExecutionSummary objects with status IN_PROGRESS.
    public var inProgressJobs: [JobExecutionSummary]?

    /// A list of JobExecutionSummary objects with status QUEUED.
    public var queuedJobs: [JobExecutionSummary]?

    /// The time when the message was sent.
    public var timestamp: Foundation.Date?

    /// A client token used to correlate requests and responses.
    public var clientToken: String?

    /// Initializes a new `GetPendingJobExecutionsResponse`
    public init() {
        self.inProgressJobs = nil
        self.queuedJobs = nil
        self.timestamp = nil
        self.clientToken = nil
    }

    /// Assign the inProgressJobs property a `GetPendingJobExecutionsResponse` value
    ///
    /// - Parameters:
    ///   - inProgressJobs: `[JobExecutionSummary]` A list of JobExecutionSummary objects with status IN_PROGRESS.
    public func withInProgressJobs(inProgressJobs: [JobExecutionSummary]) {
        self.inProgressJobs = inProgressJobs
    }

    /// Assign the queuedJobs property a `GetPendingJobExecutionsResponse` value
    ///
    /// - Parameters:
    ///   - queuedJobs: `[JobExecutionSummary]` A list of JobExecutionSummary objects with status QUEUED.
    public func withQueuedJobs(queuedJobs: [JobExecutionSummary]) {
        self.queuedJobs = queuedJobs
    }

    /// Assign the timestamp property a `GetPendingJobExecutionsResponse` value
    ///
    /// - Parameters:
    ///   - timestamp: `Foundation.Date` The time when the message was sent.
    public func withTimestamp(timestamp: Foundation.Date) {
        self.timestamp = timestamp
    }

    /// Assign the clientToken property a `GetPendingJobExecutionsResponse` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` A client token used to correlate requests and responses.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

}

/// Response payload to a StartNextJobExecution request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class StartNextJobExecutionResponse: Codable {

    /// A client token used to correlate requests and responses.
    public var clientToken: String?

    /// Contains data about a job execution.
    public var execution: JobExecutionData?

    /// The time when the message was sent to the device.
    public var timestamp: Foundation.Date?

    /// Initializes a new `StartNextJobExecutionResponse`
    public init() {
        self.clientToken = nil
        self.execution = nil
        self.timestamp = nil
    }

    /// Assign the clientToken property a `StartNextJobExecutionResponse` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` A client token used to correlate requests and responses.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

    /// Assign the execution property a `StartNextJobExecutionResponse` value
    ///
    /// - Parameters:
    ///   - execution: `JobExecutionData` Contains data about a job execution.
    public func withExecution(execution: JobExecutionData) {
        self.execution = execution
    }

    /// Assign the timestamp property a `StartNextJobExecutionResponse` value
    ///
    /// - Parameters:
    ///   - timestamp: `Foundation.Date` The time when the message was sent to the device.
    public func withTimestamp(timestamp: Foundation.Date) {
        self.timestamp = timestamp
    }

}

/// Response payload to an UpdateJobExecution request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class UpdateJobExecutionResponse: Codable {

    /// A client token used to correlate requests and responses.
    public var clientToken: String?

    /// Contains data about the state of a job execution.
    public var executionState: JobExecutionState

    /// A UTF-8 encoded JSON document that contains information that your devices need to perform the job.
    public var jobDocument: [String: Any]

    /// The time when the message was sent.
    public var timestamp: Foundation.Date

    /// Initializes a new `UpdateJobExecutionResponse`
    ///
    /// - Parameters:
    ///   - executionState: `JobExecutionState` Contains data about the state of a job execution.
    ///   - jobDocument: `[String: Any]` A UTF-8 encoded JSON document that contains information that your devices need to perform the job.
    ///   - timestamp: `Foundation.Date` The time when the message was sent.
    public init(
        executionState: JobExecutionState,
        jobDocument: [String: Any],
        timestamp: Foundation.Date
    ) {
        self.clientToken = nil
        self.executionState = executionState
        self.jobDocument = jobDocument
        self.timestamp = timestamp
    }

    /// Assign the clientToken property a `UpdateJobExecutionResponse` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` A client token used to correlate requests and responses.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

    enum CodingKeys: String, CodingKey {
        case clientToken,
            executionState,
            jobDocument,
            timestamp
    }

    /// initialize this class containing the document trait from JSON
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.clientToken = try container.decodeIfPresent(String.self, forKey: .clientToken)
        self.executionState = try container.decode(JobExecutionState.self, forKey: .executionState)
        let jobDocumentJSON = try container.decode([String: JSONValue].self, forKey: .jobDocument)
        self.jobDocument = jobDocumentJSON.asAnyDictionary()
        self.timestamp = try container.decode(Foundation.Date.self, forKey: .timestamp)
    }

    /// encode this class containing the document trait into JSON
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(clientToken, forKey: .clientToken)
        try container.encode(executionState, forKey: .executionState)
        let jobDocumentJSON = jobDocument.asJSONValueDictionary()
        try container.encode(jobDocumentJSON, forKey: .jobDocument)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

/// Sent whenever a job execution is added to or removed from the list of pending job executions for a thing.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class JobExecutionsChangedEvent: Codable {

    /// Map from JobStatus to a list of Jobs transitioning to that status.
    public var jobs: [JobStatus: [JobExecutionSummary]]

    /// The time when the message was sent.
    public var timestamp: Foundation.Date

    /// Initializes a new `JobExecutionsChangedEvent`
    ///
    /// - Parameters:
    ///   - jobs: `[JobStatus: [JobExecutionSummary]]` Map from JobStatus to a list of Jobs transitioning to that status.
    ///   - timestamp: `Foundation.Date` The time when the message was sent.
    public init(
        jobs: [JobStatus: [JobExecutionSummary]],
        timestamp: Foundation.Date
    ) {
        self.jobs = jobs
        self.timestamp = timestamp
    }

}

/// Sent whenever there is a change to which job execution is next on the list of pending job executions for a thing, as defined for DescribeJobExecution with jobId $next. This message is not sent when the next job's execution details change, only when the next job that would be returned by DescribeJobExecution with jobId $next has changed.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class NextJobExecutionChangedEvent: Codable {

    /// Contains data about a job execution.
    public var execution: JobExecutionData

    /// The time when the message was sent.
    public var timestamp: Foundation.Date

    /// Initializes a new `NextJobExecutionChangedEvent`
    ///
    /// - Parameters:
    ///   - execution: `JobExecutionData` Contains data about a job execution.
    ///   - timestamp: `Foundation.Date` The time when the message was sent.
    public init(
        execution: JobExecutionData,
        timestamp: Foundation.Date
    ) {
        self.execution = execution
        self.timestamp = timestamp
    }

}

/// A value indicating the kind of error encountered while processing an AWS IoT Jobs request
public enum RejectedErrorCode: Int, Codable {

    /// The request was sent to a topic in the AWS IoT Jobs namespace that does not map to any API.
    case INVALID_TOPIC

    /// The contents of the request could not be interpreted as valid UTF-8-encoded JSON.
    case INVALID_JSON

    /// The contents of the request were invalid. The message contains details about the error.
    case INVALID_REQUEST

    /// An update attempted to change the job execution to a state that is invalid because of the job execution's current state. In this case, the body of the error message also contains the executionState field.
    case INVALID_STATE_TRANSITION

    /// The JobExecution specified by the request topic does not exist.
    case RESOURCE_NOT_FOUND

    /// The expected version specified in the request does not match the version of the job execution in the AWS IoT Jobs service. In this case, the body of the error message also contains the executionState field.
    case VERSION_MISMATCH

    /// There was an internal error during the processing of the request.
    case INTERNAL_ERROR

    /// The request was throttled.
    case REQUEST_THROTTLED

    /// Occurs when a command to describe a job is performed on a job that is in a terminal state.
    case TERMINAL_STATE_REACHED

}

/// Configuration options for streaming operations created from service clients
///
/// `Event` is the Type that the stream deserializes MQTT messages into
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
public struct DeserializationFailureEvent: Sendable, Error {

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
    public init(cause: Error, payload: Data, topic: String) {
        self.cause = cause
        self.payload = payload
        self.topic = topic
    }
}

/// The status of the job execution.
public enum JobStatus: Int, Codable {

    case QUEUED

    case IN_PROGRESS

    case TIMED_OUT

    case FAILED

    case SUCCEEDED

    case CANCELED

    case REJECTED

    case REMOVED

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
