// Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
// SPDX-License-Identifier: Apache-2.0.

// This file is generated

import AwsIotDeviceSdkSwift
import Foundation

/// The AWS IoT Device Shadow service adds shadows to AWS IoT thing objects. Shadows are a simple data store for device properties and state.  Shadows can make a device’s state available to apps and other services whether the device is connected to AWS IoT or not.
/// AWS Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html
public class IotShadowClient {
    internal let rrClient: AwsIotDeviceSdkSwift.MqttRequestResponseClient
    internal let encoder: JSONEncoder = JSONEncoder()
    internal let decoder: JSONDecoder = JSONDecoder()

    public init(rrClient: AwsIotDeviceSdkSwift.MqttRequestResponseClient) throws {
        self.rrClient = rrClient
    }

    /// Create a stream for NamedShadowDelta events for a named shadow of an AWS IoT thing.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#update-delta-pub-sub-topic
    ///
    /// - Parameters:
    ///   - request: `NamedShadowDeltaUpdatedSubscriptionRequest` modeled streaming operation subscription configuration
    ///   - options: options set of callbacks that the operation should invoke in response to related events
    /// - Throws: // TODO errors input here
    /// - Returns: a `StreamingOperation` which will invoke a callback every time a message is received on the
    ///            associated MQTT topic
    public func createNamedShadowDeltaUpdatedStream(
        request: NamedShadowDeltaUpdatedSubscriptionRequest
    ) async throws -> StreamingOperation {
        var topic: String = "$aws/things/{thingName}/shadow/name/{shadowName}/update/delta"

        guard let thingName = request.thingName, !thingName.isEmpty else {
            throw IotShadowClientError.thingNameNotFound
        }
        topic = topic.replacingOccurrences(of: "{thingName}", with: thingName)

        guard let shadowName = request.shadowName, !shadowName.isEmpty else {
            throw IotShadowClientError.shadowNameNotFound
        }
        topic = topic.replacingOccurrences(of: "{shadowName}", with: shadowName)

        let streamOptions: StreamingOperationOptions = StreamingOperationOptions(
            subscriptionStatusEventHandler: { event in
                // TODO
            },
            incomingPublishEventHandler: { event in
                // TODO
            },
            topicFilter: topic)
        return try await rrClient.createStream(streamOptions: streamOptions)
    }

    /// Create a stream for ShadowUpdated events for a named shadow of an AWS IoT thing.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#update-documents-pub-sub-topic
    ///
    /// - Parameters:
    ///   - request: `NamedShadowUpdatedSubscriptionRequest` modeled streaming operation subscription configuration
    ///   - options: options set of callbacks that the operation should invoke in response to related events
    /// - Throws: // TODO errors input here
    /// - Returns: a `StreamingOperation` which will invoke a callback every time a message is received on the
    ///            associated MQTT topic
    public func createNamedShadowUpdatedStream(
        request: NamedShadowUpdatedSubscriptionRequest
    ) async throws -> StreamingOperation {
        var topic: String = "$aws/things/{thingName}/shadow/name/{shadowName}/update/documents"

        guard let thingName = request.thingName, !thingName.isEmpty else {
            throw IotShadowClientError.thingNameNotFound
        }
        topic = topic.replacingOccurrences(of: "{thingName}", with: thingName)

        guard let shadowName = request.shadowName, !shadowName.isEmpty else {
            throw IotShadowClientError.shadowNameNotFound
        }
        topic = topic.replacingOccurrences(of: "{shadowName}", with: shadowName)

        let streamOptions: StreamingOperationOptions = StreamingOperationOptions(
            subscriptionStatusEventHandler: { event in
                // TODO
            },
            incomingPublishEventHandler: { event in
                // TODO
            },
            topicFilter: topic)
        return try await rrClient.createStream(streamOptions: streamOptions)
    }

    /// Create a stream for ShadowDelta events for the (classic) shadow of an AWS IoT thing.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#update-delta-pub-sub-topic
    ///
    /// - Parameters:
    ///   - request: `ShadowDeltaUpdatedSubscriptionRequest` modeled streaming operation subscription configuration
    ///   - options: options set of callbacks that the operation should invoke in response to related events
    /// - Throws: // TODO errors input here
    /// - Returns: a `StreamingOperation` which will invoke a callback every time a message is received on the
    ///            associated MQTT topic
    public func createShadowDeltaUpdatedStream(
        request: ShadowDeltaUpdatedSubscriptionRequest
    ) async throws -> StreamingOperation {
        var topic: String = "$aws/things/{thingName}/shadow/update/delta"

        guard let thingName = request.thingName, !thingName.isEmpty else {
            throw IotShadowClientError.thingNameNotFound
        }
        topic = topic.replacingOccurrences(of: "{thingName}", with: thingName)

        let streamOptions: StreamingOperationOptions = StreamingOperationOptions(
            subscriptionStatusEventHandler: { event in
                // TODO
            },
            incomingPublishEventHandler: { event in
                // TODO
            },
            topicFilter: topic)
        return try await rrClient.createStream(streamOptions: streamOptions)
    }

    /// Create a stream for ShadowUpdated events for the (classic) shadow of an AWS IoT thing.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#update-documents-pub-sub-topic
    ///
    /// - Parameters:
    ///   - request: `ShadowUpdatedSubscriptionRequest` modeled streaming operation subscription configuration
    ///   - options: options set of callbacks that the operation should invoke in response to related events
    /// - Throws: // TODO errors input here
    /// - Returns: a `StreamingOperation` which will invoke a callback every time a message is received on the
    ///            associated MQTT topic
    public func createShadowUpdatedStream(
        request: ShadowUpdatedSubscriptionRequest
    ) async throws -> StreamingOperation {
        var topic: String = "$aws/things/{thingName}/shadow/update/documents"

        guard let thingName = request.thingName, !thingName.isEmpty else {
            throw IotShadowClientError.thingNameNotFound
        }
        topic = topic.replacingOccurrences(of: "{thingName}", with: thingName)

        let streamOptions: StreamingOperationOptions = StreamingOperationOptions(
            subscriptionStatusEventHandler: { event in
                // TODO
            },
            incomingPublishEventHandler: { event in
                // TODO
            },
            topicFilter: topic)
        return try await rrClient.createStream(streamOptions: streamOptions)
    }

    /// Deletes a named shadow for an AWS IoT thing.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#delete-pub-sub-topic
    ///
    /// - Parameters:
    ///   - request: `DeleteNamedShadowRequest` modeled request to perform
    /// - Throws:  `CommonRuntimeError.crtError` // TODO setup Error to be thrown
    /// - Returns: a `StreamingOperation` Need to see implementation by Vera  // TODO update info on return
    public func deleteNamedShadow(request: DeleteNamedShadowRequest) async throws -> MqttRequestResponseResponse {
        // Check for mandatory members:

        // symbols.toSymbol(outputShape): DeleteShadowResponse
        // symbols.toSymbol(errorShape) V2ErrorResponse

        do {
            // Encode the event into Data.
            let jsonData = try encoder.encode(request)
            let requestResponseOperationOptions = RequestResponseOperationOptions(
                subscriptionTopicFilters: ["topic Filter"],
                responsePaths: nil,
                topic: "Topic",
                payload: jsonData,
                correlationToken: nil)

            return try await rrClient.submitRequest(operationOptions: requestResponseOperationOptions)
        }
    }

    /// Deletes the (classic) shadow for an AWS IoT thing.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#delete-pub-sub-topic
    ///
    /// - Parameters:
    ///   - request: `DeleteShadowRequest` modeled request to perform
    /// - Throws:  `CommonRuntimeError.crtError` // TODO setup Error to be thrown
    /// - Returns: a `StreamingOperation` Need to see implementation by Vera  // TODO update info on return
    public func deleteShadow(request: DeleteShadowRequest) async throws -> MqttRequestResponseResponse {
        // Check for mandatory members:

        // symbols.toSymbol(outputShape): DeleteShadowResponse
        // symbols.toSymbol(errorShape) V2ErrorResponse

        do {
            // Encode the event into Data.
            let jsonData = try encoder.encode(request)
            let requestResponseOperationOptions = RequestResponseOperationOptions(
                subscriptionTopicFilters: ["topic Filter"],
                responsePaths: nil,
                topic: "Topic",
                payload: jsonData,
                correlationToken: nil)

            return try await rrClient.submitRequest(operationOptions: requestResponseOperationOptions)
        }
    }

    /// Gets a named shadow for an AWS IoT thing.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#get-pub-sub-topic
    ///
    /// - Parameters:
    ///   - request: `GetNamedShadowRequest` modeled request to perform
    /// - Throws:  `CommonRuntimeError.crtError` // TODO setup Error to be thrown
    /// - Returns: a `StreamingOperation` Need to see implementation by Vera  // TODO update info on return
    public func getNamedShadow(request: GetNamedShadowRequest) async throws -> MqttRequestResponseResponse {
        // Check for mandatory members:

        // symbols.toSymbol(outputShape): GetShadowResponse
        // symbols.toSymbol(errorShape) V2ErrorResponse

        do {
            // Encode the event into Data.
            let jsonData = try encoder.encode(request)
            let requestResponseOperationOptions = RequestResponseOperationOptions(
                subscriptionTopicFilters: ["topic Filter"],
                responsePaths: nil,
                topic: "Topic",
                payload: jsonData,
                correlationToken: nil)

            return try await rrClient.submitRequest(operationOptions: requestResponseOperationOptions)
        }
    }

    /// Gets the (classic) shadow for an AWS IoT thing.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#get-pub-sub-topic
    ///
    /// - Parameters:
    ///   - request: `GetShadowRequest` modeled request to perform
    /// - Throws:  `CommonRuntimeError.crtError` // TODO setup Error to be thrown
    /// - Returns: a `StreamingOperation` Need to see implementation by Vera  // TODO update info on return
    public func getShadow(request: GetShadowRequest) async throws -> MqttRequestResponseResponse {
        // Check for mandatory members:

        // symbols.toSymbol(outputShape): GetShadowResponse
        // symbols.toSymbol(errorShape) V2ErrorResponse

        do {
            // Encode the event into Data.
            let jsonData = try encoder.encode(request)
            let requestResponseOperationOptions = RequestResponseOperationOptions(
                subscriptionTopicFilters: ["topic Filter"],
                responsePaths: nil,
                topic: "Topic",
                payload: jsonData,
                correlationToken: nil)

            return try await rrClient.submitRequest(operationOptions: requestResponseOperationOptions)
        }
    }

    /// Testing Operation for Request Response.
    ///
    /// API Docs: https://NonExistantLink.com
    ///
    /// - Parameters:
    ///   - request: `TestStructureData` modeled request to perform
    /// - Throws:  `CommonRuntimeError.crtError` // TODO setup Error to be thrown
    /// - Returns: a `StreamingOperation` Need to see implementation by Vera  // TODO update info on return
    public func testRequestResponseOperation(request: TestStructureData) async throws -> MqttRequestResponseResponse {
        // Check for mandatory members:

        // symbols.toSymbol(outputShape): TestStructureData
        // symbols.toSymbol(errorShape) V2ErrorResponse

        do {
            // Encode the event into Data.
            let jsonData = try encoder.encode(request)
            let requestResponseOperationOptions = RequestResponseOperationOptions(
                subscriptionTopicFilters: ["topic Filter"],
                responsePaths: nil,
                topic: "Topic",
                payload: jsonData,
                correlationToken: nil)

            return try await rrClient.submitRequest(operationOptions: requestResponseOperationOptions)
        }
    }

    /// Testing Operation for Streaming.
    ///
    /// API Docs: https://NonExistantLink.com
    ///
    /// - Parameters:
    ///   - request: `TestStructureData` modeled streaming operation subscription configuration
    ///   - options: options set of callbacks that the operation should invoke in response to related events
    /// - Throws: // TODO errors input here
    /// - Returns: a `StreamingOperation` which will invoke a callback every time a message is received on the
    ///            associated MQTT topic
    public func testStreamingOperation(
        request: TestStructureData
    ) async throws -> StreamingOperation {
        var topic: String = "$aws/things/{thingName}/test/streamingOperation/{shadowName}/update/documents"

        guard let thingName = request.thingName, !thingName.isEmpty else {
            throw IotShadowClientError.thingNameNotFound
        }
        topic = topic.replacingOccurrences(of: "{thingName}", with: thingName)

        guard let shadowName = request.shadowName, !shadowName.isEmpty else {
            throw IotShadowClientError.shadowNameNotFound
        }
        topic = topic.replacingOccurrences(of: "{shadowName}", with: shadowName)

        let streamOptions: StreamingOperationOptions = StreamingOperationOptions(
            subscriptionStatusEventHandler: { event in
                // TODO
            },
            incomingPublishEventHandler: { event in
                // TODO
            },
            topicFilter: topic)
        return try await rrClient.createStream(streamOptions: streamOptions)
    }

    /// Update a named shadow for a device.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#update-pub-sub-topic
    ///
    /// - Parameters:
    ///   - request: `UpdateNamedShadowRequest` modeled request to perform
    /// - Throws:  `CommonRuntimeError.crtError` // TODO setup Error to be thrown
    /// - Returns: a `StreamingOperation` Need to see implementation by Vera  // TODO update info on return
    public func updateNamedShadow(request: UpdateNamedShadowRequest) async throws -> MqttRequestResponseResponse {
        // Check for mandatory members:

        // symbols.toSymbol(outputShape): UpdateShadowResponse
        // symbols.toSymbol(errorShape) V2ErrorResponse

        do {
            // Encode the event into Data.
            let jsonData = try encoder.encode(request)
            let requestResponseOperationOptions = RequestResponseOperationOptions(
                subscriptionTopicFilters: ["topic Filter"],
                responsePaths: nil,
                topic: "Topic",
                payload: jsonData,
                correlationToken: nil)

            return try await rrClient.submitRequest(operationOptions: requestResponseOperationOptions)
        }
    }

    /// Update a device's (classic) shadow.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#update-pub-sub-topic
    ///
    /// - Parameters:
    ///   - request: `UpdateShadowRequest` modeled request to perform
    /// - Throws:  `CommonRuntimeError.crtError` // TODO setup Error to be thrown
    /// - Returns: a `StreamingOperation` Need to see implementation by Vera  // TODO update info on return
    public func updateShadow(request: UpdateShadowRequest) async throws -> MqttRequestResponseResponse {
        // Check for mandatory members:

        // symbols.toSymbol(outputShape): UpdateShadowResponse
        // symbols.toSymbol(errorShape) V2ErrorResponse

        do {
            // Encode the event into Data.
            let jsonData = try encoder.encode(request)
            let requestResponseOperationOptions = RequestResponseOperationOptions(
                subscriptionTopicFilters: ["topic Filter"],
                responsePaths: nil,
                topic: "Topic",
                payload: jsonData,
                correlationToken: nil)

            return try await rrClient.submitRequest(operationOptions: requestResponseOperationOptions)
        }
    }

}

/// (Potentially partial) state of an AWS IoT thing's shadow.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class ShadowState: Codable {

    /// The desired shadow state (from external services and devices).
    public var desired: [String: Any]?

    /// The (last) reported shadow state from the device.
    public var reported: [String: Any]?

    /// Initializes a new `ShadowState`
    public init() {
        desired = nil
        reported = nil
    }

    /// Assign the desired property a `ShadowState` value
    ///
    /// - Parameters:
    ///   - desired: `[String: Any]` The desired shadow state (from external services and devices).
    public func withDesired(desired: [String: Any]) {
        self.desired = desired
    }

    /// Assign the reported property a `ShadowState` value
    ///
    /// - Parameters:
    ///   - reported: `[String: Any]` The (last) reported shadow state from the device.
    public func withReported(reported: [String: Any]) {
        self.reported = reported
    }

    enum CodingKeys: String, CodingKey {
        case desired,
             reported
    }

    /// initialize this class containing the document trait from JSON
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let desiredJSON = try container.decodeIfPresent([String: JSONValue].self, forKey: .desired)
        self.desired = desiredJSON?.asAnyDictionary()
        let reportedJSON = try container.decodeIfPresent([String: JSONValue].self, forKey: .reported)
        self.reported = reportedJSON?.asAnyDictionary()
    }

    /// encode this class containing the document trait into JSON
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let desired = desired {
            let desiredJSON = desired.asJSONValueDictionary()
            try container.encode(desiredJSON, forKey: .desired)
        }
        if let reported = reported {
            let reportedJSON = reported.asJSONValueDictionary()
            try container.encode(reportedJSON, forKey: .reported)
        }
    }
}

/// (Potentially partial) state of an AWS IoT thing's shadow.  Includes the delta between the reported and desired states.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class ShadowStateWithDelta: Codable {

    /// The desired shadow state (from external services and devices).
    public var desired: [String: Any]?

    /// The (last) reported shadow state from the device.
    public var reported: [String: Any]?

    /// The delta between the reported and desired states.
    public var delta: [String: Any]?

    /// Initializes a new `ShadowStateWithDelta`
    public init() {
        desired = nil
        reported = nil
        delta = nil
    }

    /// Assign the desired property a `ShadowStateWithDelta` value
    ///
    /// - Parameters:
    ///   - desired: `[String: Any]` The desired shadow state (from external services and devices).
    public func withDesired(desired: [String: Any]) {
        self.desired = desired
    }

    /// Assign the reported property a `ShadowStateWithDelta` value
    ///
    /// - Parameters:
    ///   - reported: `[String: Any]` The (last) reported shadow state from the device.
    public func withReported(reported: [String: Any]) {
        self.reported = reported
    }

    /// Assign the delta property a `ShadowStateWithDelta` value
    ///
    /// - Parameters:
    ///   - delta: `[String: Any]` The delta between the reported and desired states.
    public func withDelta(delta: [String: Any]) {
        self.delta = delta
    }

    enum CodingKeys: String, CodingKey {
        case desired,
             reported,
             delta
    }

    /// initialize this class containing the document trait from JSON
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let desiredJSON = try container.decodeIfPresent([String: JSONValue].self, forKey: .desired)
        self.desired = desiredJSON?.asAnyDictionary()
        let reportedJSON = try container.decodeIfPresent([String: JSONValue].self, forKey: .reported)
        self.reported = reportedJSON?.asAnyDictionary()
        let deltaJSON = try container.decodeIfPresent([String: JSONValue].self, forKey: .delta)
        self.delta = deltaJSON?.asAnyDictionary()
    }

    /// encode this class containing the document trait into JSON
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let desired = desired {
            let desiredJSON = desired.asJSONValueDictionary()
            try container.encode(desiredJSON, forKey: .desired)
        }
        if let reported = reported {
            let reportedJSON = reported.asJSONValueDictionary()
            try container.encode(reportedJSON, forKey: .reported)
        }
        if let delta = delta {
            let deltaJSON = delta.asJSONValueDictionary()
            try container.encode(deltaJSON, forKey: .delta)
        }
    }
}

/// A description of the before and after states of a device shadow.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class ShadowUpdatedEvent: Codable {

    /// Contains the state of the object before the update.
    public var previous: ShadowUpdatedSnapshot?

    /// Contains the state of the object after the update.
    public var current: ShadowUpdatedSnapshot?

    /// The time the event was generated by AWS IoT.
    public var timestamp: Foundation.Date?

    /// Initializes a new `ShadowUpdatedEvent`
    public init() {
        previous = nil
        current = nil
        timestamp = nil
    }

    /// Assign the previous property a `ShadowUpdatedEvent` value
    ///
    /// - Parameters:
    ///   - previous: `ShadowUpdatedSnapshot` Contains the state of the object before the update.
    public func withPrevious(previous: ShadowUpdatedSnapshot) {
        self.previous = previous
    }

    /// Assign the current property a `ShadowUpdatedEvent` value
    ///
    /// - Parameters:
    ///   - current: `ShadowUpdatedSnapshot` Contains the state of the object after the update.
    public func withCurrent(current: ShadowUpdatedSnapshot) {
        self.current = current
    }

    /// Assign the timestamp property a `ShadowUpdatedEvent` value
    ///
    /// - Parameters:
    ///   - timestamp: `Foundation.Date` The time the event was generated by AWS IoT.
    public func withTimestamp(timestamp: Foundation.Date) {
        self.timestamp = timestamp
    }

}

/// An event generated when a shadow document was updated by a request to AWS IoT.  The event payload contains only the changes requested.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class ShadowDeltaUpdatedEvent: Codable {

    /// Shadow properties that were updated.
    public var state: [String: Any]?

    /// Timestamps for the shadow properties that were updated.
    public var metadata: [String: Any]?

    /// The time the event was generated by AWS IoT.
    public var timestamp: Foundation.Date?

    /// The current version of the document for the device's shadow.
    public var version: Int?

    /// An opaque token used to correlate requests and responses.  Present only if a client token was used in the request.
    public var clientToken: String?

    /// Initializes a new `ShadowDeltaUpdatedEvent`
    public init() {
        state = nil
        metadata = nil
        timestamp = nil
        version = nil
        clientToken = nil
    }

    /// Assign the state property a `ShadowDeltaUpdatedEvent` value
    ///
    /// - Parameters:
    ///   - state: `[String: Any]` Shadow properties that were updated.
    public func withState(state: [String: Any]) {
        self.state = state
    }

    /// Assign the metadata property a `ShadowDeltaUpdatedEvent` value
    ///
    /// - Parameters:
    ///   - metadata: `[String: Any]` Timestamps for the shadow properties that were updated.
    public func withMetadata(metadata: [String: Any]) {
        self.metadata = metadata
    }

    /// Assign the timestamp property a `ShadowDeltaUpdatedEvent` value
    ///
    /// - Parameters:
    ///   - timestamp: `Foundation.Date` The time the event was generated by AWS IoT.
    public func withTimestamp(timestamp: Foundation.Date) {
        self.timestamp = timestamp
    }

    /// Assign the version property a `ShadowDeltaUpdatedEvent` value
    ///
    /// - Parameters:
    ///   - version: `Int` The current version of the document for the device's shadow.
    public func withVersion(version: Int) {
        self.version = version
    }

    /// Assign the clientToken property a `ShadowDeltaUpdatedEvent` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` An opaque token used to correlate requests and responses.  Present only if a client token was used in the request.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

    enum CodingKeys: String, CodingKey {
        case state,
             metadata,
             timestamp,
             version,
             clientToken
    }

    /// initialize this class containing the document trait from JSON
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let stateJSON = try container.decodeIfPresent([String: JSONValue].self, forKey: .state)
        self.state = stateJSON?.asAnyDictionary()
        let metadataJSON = try container.decodeIfPresent([String: JSONValue].self, forKey: .metadata)
        self.metadata = metadataJSON?.asAnyDictionary()
        self.timestamp = try container.decodeIfPresent(Foundation.Date.self , forKey: .timestamp)
        self.version = try container.decodeIfPresent(Int.self , forKey: .version)
        self.clientToken = try container.decodeIfPresent(String.self , forKey: .clientToken)
    }

    /// encode this class containing the document trait into JSON
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let state = state {
            let stateJSON = state.asJSONValueDictionary()
            try container.encode(stateJSON, forKey: .state)
        }
        if let metadata = metadata {
            let metadataJSON = metadata.asJSONValueDictionary()
            try container.encode(metadataJSON, forKey: .metadata)
        }
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(version, forKey: .version)
        try container.encode(clientToken, forKey: .clientToken)
    }
}

/// Complete state of the (classic) shadow of an AWS IoT Thing.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class ShadowUpdatedSnapshot: Codable {

    /// Current shadow state.
    public var state: ShadowState?

    /// Contains the timestamps for each attribute in the desired and reported sections of the state.
    public var metadata: ShadowMetadata?

    /// The current version of the document for the device's shadow.
    public var version: Int?

    /// Initializes a new `ShadowUpdatedSnapshot`
    public init() {
        state = nil
        metadata = nil
        version = nil
    }

    /// Assign the state property a `ShadowUpdatedSnapshot` value
    ///
    /// - Parameters:
    ///   - state: `ShadowState` Current shadow state.
    public func withState(state: ShadowState) {
        self.state = state
    }

    /// Assign the metadata property a `ShadowUpdatedSnapshot` value
    ///
    /// - Parameters:
    ///   - metadata: `ShadowMetadata` Contains the timestamps for each attribute in the desired and reported sections of the state.
    public func withMetadata(metadata: ShadowMetadata) {
        self.metadata = metadata
    }

    /// Assign the version property a `ShadowUpdatedSnapshot` value
    ///
    /// - Parameters:
    ///   - version: `Int` The current version of the document for the device's shadow.
    public func withVersion(version: Int) {
        self.version = version
    }

}

/// Contains the last-updated timestamps for each attribute in the desired and reported sections of the shadow state.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class ShadowMetadata: Codable {

    /// Contains the timestamps for each attribute in the desired section of a shadow's state.
    public var desired: [String: Any]?

    /// Contains the timestamps for each attribute in the reported section of a shadow's state.
    public var reported: [String: Any]?

    /// Initializes a new `ShadowMetadata`
    public init() {
        desired = nil
        reported = nil
    }

    /// Assign the desired property a `ShadowMetadata` value
    ///
    /// - Parameters:
    ///   - desired: `[String: Any]` Contains the timestamps for each attribute in the desired section of a shadow's state.
    public func withDesired(desired: [String: Any]) {
        self.desired = desired
    }

    /// Assign the reported property a `ShadowMetadata` value
    ///
    /// - Parameters:
    ///   - reported: `[String: Any]` Contains the timestamps for each attribute in the reported section of a shadow's state.
    public func withReported(reported: [String: Any]) {
        self.reported = reported
    }

    enum CodingKeys: String, CodingKey {
        case desired,
             reported
    }

    /// initialize this class containing the document trait from JSON
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let desiredJSON = try container.decodeIfPresent([String: JSONValue].self, forKey: .desired)
        self.desired = desiredJSON?.asAnyDictionary()
        let reportedJSON = try container.decodeIfPresent([String: JSONValue].self, forKey: .reported)
        self.reported = reportedJSON?.asAnyDictionary()
    }

    /// encode this class containing the document trait into JSON
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let desired = desired {
            let desiredJSON = desired.asJSONValueDictionary()
            try container.encode(desiredJSON, forKey: .desired)
        }
        if let reported = reported {
            let reportedJSON = reported.asJSONValueDictionary()
            try container.encode(reportedJSON, forKey: .reported)
        }
    }
}

/// Data needed to make a DeleteNamedShadow request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class DeleteNamedShadowRequest: Codable {

    /// AWS IoT thing to delete a named shadow from.
    public var thingName: String?

    /// Name of the shadow to delete.
    public var shadowName: String?

    /// Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public var clientToken: String?

    /// Initializes a new `DeleteNamedShadowRequest`
    ///
    /// - Parameters:

    ///   - thingName: `String` AWS IoT thing to delete a named shadow from.

    ///   - shadowName: `String` Name of the shadow to delete.
    public init(thingName: String,
        shadowName: String) {
        self.thingName = thingName
        self.shadowName = shadowName
        clientToken = nil
    }

    /// Assign the clientToken property a `DeleteNamedShadowRequest` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

}

/// Data needed to make a DeleteShadow request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class DeleteShadowRequest: Codable {

    /// AWS IoT thing to delete the (classic) shadow of.
    public var thingName: String?

    /// Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public var clientToken: String?

    /// Initializes a new `DeleteShadowRequest`
    ///
    /// - Parameters:

    ///   - thingName: `String` AWS IoT thing to delete the (classic) shadow of.
    public init(thingName: String) {
        self.thingName = thingName
        clientToken = nil
    }

    /// Assign the clientToken property a `DeleteShadowRequest` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

}

/// Data needed to make a GetNamedShadow request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class GetNamedShadowRequest: Codable {

    /// AWS IoT thing to get the named shadow for.
    public var thingName: String?

    /// Name of the shadow to get.
    public var shadowName: String?

    /// Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public var clientToken: String?

    /// Initializes a new `GetNamedShadowRequest`
    ///
    /// - Parameters:

    ///   - thingName: `String` AWS IoT thing to get the named shadow for.

    ///   - shadowName: `String` Name of the shadow to get.
    public init(thingName: String,
        shadowName: String) {
        self.thingName = thingName
        self.shadowName = shadowName
        clientToken = nil
    }

    /// Assign the clientToken property a `GetNamedShadowRequest` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

}

/// Data needed to make a GetShadow request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class GetShadowRequest: Codable {

    /// AWS IoT thing to get the (classic) shadow for.
    public var thingName: String?

    /// Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public var clientToken: String?

    /// Initializes a new `GetShadowRequest`
    ///
    /// - Parameters:

    ///   - thingName: `String` AWS IoT thing to get the (classic) shadow for.
    public init(thingName: String) {
        self.thingName = thingName
        clientToken = nil
    }

    /// Assign the clientToken property a `GetShadowRequest` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

}

/// Data needed to make an UpdateNamedShadow request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class UpdateNamedShadowRequest: Codable {

    /// Aws IoT thing to update a named shadow of.
    public var thingName: String?

    /// Name of the shadow to update.
    public var shadowName: String?

    /// Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public var clientToken: String?

    /// Requested changes to shadow state.  Updates affect only the fields specified.
    public var state: ShadowState?

    /// (Optional) The Device Shadow service applies the update only if the specified version matches the latest version.
    public var version: Int?

    /// Initializes a new `UpdateNamedShadowRequest`
    ///
    /// - Parameters:

    ///   - thingName: `String` Aws IoT thing to update a named shadow of.

    ///   - shadowName: `String` Name of the shadow to update.
    public init(thingName: String,
        shadowName: String) {
        self.thingName = thingName
        self.shadowName = shadowName
        clientToken = nil
        state = nil
        version = nil
    }

    /// Assign the clientToken property a `UpdateNamedShadowRequest` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

    /// Assign the state property a `UpdateNamedShadowRequest` value
    ///
    /// - Parameters:
    ///   - state: `ShadowState` Requested changes to shadow state.  Updates affect only the fields specified.
    public func withState(state: ShadowState) {
        self.state = state
    }

    /// Assign the version property a `UpdateNamedShadowRequest` value
    ///
    /// - Parameters:
    ///   - version: `Int` (Optional) The Device Shadow service applies the update only if the specified version matches the latest version.
    public func withVersion(version: Int) {
        self.version = version
    }

}

/// Data needed to make an UpdateShadow request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class UpdateShadowRequest: Codable {

    /// Aws IoT thing to update the (classic) shadow of.
    public var thingName: String?

    /// Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public var clientToken: String?

    /// Requested changes to the shadow state.  Updates affect only the fields specified.
    public var state: ShadowState?

    /// (Optional) The Device Shadow service processes the update only if the specified version matches the latest version.
    public var version: Int?

    /// Initializes a new `UpdateShadowRequest`
    ///
    /// - Parameters:

    ///   - thingName: `String` Aws IoT thing to update the (classic) shadow of.
    public init(thingName: String) {
        self.thingName = thingName
        clientToken = nil
        state = nil
        version = nil
    }

    /// Assign the clientToken property a `UpdateShadowRequest` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

    /// Assign the state property a `UpdateShadowRequest` value
    ///
    /// - Parameters:
    ///   - state: `ShadowState` Requested changes to the shadow state.  Updates affect only the fields specified.
    public func withState(state: ShadowState) {
        self.state = state
    }

    /// Assign the version property a `UpdateShadowRequest` value
    ///
    /// - Parameters:
    ///   - version: `Int` (Optional) The Device Shadow service processes the update only if the specified version matches the latest version.
    public func withVersion(version: Int) {
        self.version = version
    }

}

/// Data needed to subscribe to DeleteNamedShadow responses for an AWS IoT thing.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class DeleteNamedShadowSubscriptionRequest: Codable {

    /// AWS IoT thing to subscribe to DeleteNamedShadow operations for.
    public var thingName: String?

    /// Name of the shadow to subscribe to DeleteNamedShadow operations for.
    public var shadowName: String?

    /// Initializes a new `DeleteNamedShadowSubscriptionRequest`
    ///
    /// - Parameters:

    ///   - thingName: `String` AWS IoT thing to subscribe to DeleteNamedShadow operations for.

    ///   - shadowName: `String` Name of the shadow to subscribe to DeleteNamedShadow operations for.
    public init(thingName: String,
        shadowName: String) {
        self.thingName = thingName
        self.shadowName = shadowName
    }

}

/// Data needed to subscribe to DeleteShadow responses for an AWS IoT thing.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class DeleteShadowSubscriptionRequest: Codable {

    /// AWS IoT thing to subscribe to DeleteShadow operations for.
    public var thingName: String?

    /// Initializes a new `DeleteShadowSubscriptionRequest`
    ///
    /// - Parameters:

    ///   - thingName: `String` AWS IoT thing to subscribe to DeleteShadow operations for.
    public init(thingName: String) {
        self.thingName = thingName
    }

}

/// Data needed to subscribe to GetNamedShadow responses.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class GetNamedShadowSubscriptionRequest: Codable {

    /// AWS IoT thing subscribe to GetNamedShadow responses for.
    public var thingName: String?

    /// Name of the shadow to subscribe to GetNamedShadow responses for.
    public var shadowName: String?

    /// Initializes a new `GetNamedShadowSubscriptionRequest`
    ///
    /// - Parameters:

    ///   - thingName: `String` AWS IoT thing subscribe to GetNamedShadow responses for.

    ///   - shadowName: `String` Name of the shadow to subscribe to GetNamedShadow responses for.
    public init(thingName: String,
        shadowName: String) {
        self.thingName = thingName
        self.shadowName = shadowName
    }

}

/// Data needed to subscribe to GetShadow responses.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class GetShadowSubscriptionRequest: Codable {

    /// AWS IoT thing subscribe to GetShadow responses for.
    public var thingName: String?

    /// Initializes a new `GetShadowSubscriptionRequest`
    ///
    /// - Parameters:

    ///   - thingName: `String` AWS IoT thing subscribe to GetShadow responses for.
    public init(thingName: String) {
        self.thingName = thingName
    }

}

/// Data needed to subscribe to UpdateNamedShadow responses.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class UpdateNamedShadowSubscriptionRequest: Codable {

    /// Name of the AWS IoT thing to listen to UpdateNamedShadow responses for.
    public var thingName: String?

    /// Name of the shadow to listen to UpdateNamedShadow responses for.
    public var shadowName: String?

    /// Initializes a new `UpdateNamedShadowSubscriptionRequest`
    ///
    /// - Parameters:

    ///   - thingName: `String` Name of the AWS IoT thing to listen to UpdateNamedShadow responses for.

    ///   - shadowName: `String` Name of the shadow to listen to UpdateNamedShadow responses for.
    public init(thingName: String,
        shadowName: String) {
        self.thingName = thingName
        self.shadowName = shadowName
    }

}

/// Data needed to subscribe to UpdateShadow responses.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class UpdateShadowSubscriptionRequest: Codable {

    /// Name of the AWS IoT thing to listen to UpdateShadow responses for.
    public var thingName: String?

    /// Initializes a new `UpdateShadowSubscriptionRequest`
    ///
    /// - Parameters:

    ///   - thingName: `String` Name of the AWS IoT thing to listen to UpdateShadow responses for.
    public init(thingName: String) {
        self.thingName = thingName
    }

}

/// Data needed to subscribe to a device's NamedShadowDelta events.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class NamedShadowDeltaUpdatedSubscriptionRequest: Codable {

    /// Name of the AWS IoT thing to get NamedShadowDelta events for.
    public var thingName: String?

    /// Name of the shadow to get ShadowDelta events for.
    public var shadowName: String?

    /// Initializes a new `NamedShadowDeltaUpdatedSubscriptionRequest`
    ///
    /// - Parameters:

    ///   - thingName: `String` Name of the AWS IoT thing to get NamedShadowDelta events for.

    ///   - shadowName: `String` Name of the shadow to get ShadowDelta events for.
    public init(thingName: String,
        shadowName: String) {
        self.thingName = thingName
        self.shadowName = shadowName
    }

}

/// Data needed to subscribe to a device's NamedShadowUpdated events.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class NamedShadowUpdatedSubscriptionRequest: Codable {

    /// Name of the AWS IoT thing to get NamedShadowUpdated events for.
    public var thingName: String?

    /// Name of the shadow to get NamedShadowUpdated events for.
    public var shadowName: String?

    /// Initializes a new `NamedShadowUpdatedSubscriptionRequest`
    ///
    /// - Parameters:

    ///   - thingName: `String` Name of the AWS IoT thing to get NamedShadowUpdated events for.

    ///   - shadowName: `String` Name of the shadow to get NamedShadowUpdated events for.
    public init(thingName: String,
        shadowName: String) {
        self.thingName = thingName
        self.shadowName = shadowName
    }

}

/// Data needed to subscribe to a device's ShadowDelta events.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class ShadowDeltaUpdatedSubscriptionRequest: Codable {

    /// Name of the AWS IoT thing to get ShadowDelta events for.
    public var thingName: String?

    /// Initializes a new `ShadowDeltaUpdatedSubscriptionRequest`
    ///
    /// - Parameters:

    ///   - thingName: `String` Name of the AWS IoT thing to get ShadowDelta events for.
    public init(thingName: String) {
        self.thingName = thingName
    }

}

/// Data needed to subscribe to a device's ShadowUpdated events.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class ShadowUpdatedSubscriptionRequest: Codable {

    /// Name of the AWS IoT thing to get ShadowUpdated events for.
    public var thingName: String?

    /// Initializes a new `ShadowUpdatedSubscriptionRequest`
    ///
    /// - Parameters:

    ///   - thingName: `String` Name of the AWS IoT thing to get ShadowUpdated events for.
    public init(thingName: String) {
        self.thingName = thingName
    }

}

/// Response document containing details about a failed request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class ErrorResponse: Codable {

    /// Opaque request-response correlation data.  Present only if a client token was used in the request.
    public var clientToken: String?

    /// An HTTP response code that indicates the type of error.
    public var code: Int?

    /// A text message that provides additional information.
    public var message: String?

    /// The date and time the response was generated by AWS IoT. This property is not present in all error response documents.
    public var timestamp: Foundation.Date?

    /// Initializes a new `ErrorResponse`
    ///
    /// - Parameters:

    ///   - code: `Int` An HTTP response code that indicates the type of error.
    public init(code: Int) {
        clientToken = nil
        self.code = code
        message = nil
        timestamp = nil
    }

    /// Assign the clientToken property a `ErrorResponse` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` Opaque request-response correlation data.  Present only if a client token was used in the request.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

    /// Assign the message property a `ErrorResponse` value
    ///
    /// - Parameters:
    ///   - message: `String` A text message that provides additional information.
    public func withMessage(message: String) {
        self.message = message
    }

    /// Assign the timestamp property a `ErrorResponse` value
    ///
    /// - Parameters:
    ///   - timestamp: `Foundation.Date` The date and time the response was generated by AWS IoT. This property is not present in all error response documents.
    public func withTimestamp(timestamp: Foundation.Date) {
        self.timestamp = timestamp
    }

}

/// Response document containing details about a failed request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class V2ErrorResponse: Codable {

    /// Opaque request-response correlation data.  Present only if a client token was used in the request.
    public var clientToken: String?

    /// An HTTP response code that indicates the type of error.
    public var code: Int?

    /// A text message that provides additional information.
    public var message: String?

    /// The date and time the response was generated by AWS IoT. This property is not present in all error response documents.
    public var timestamp: Foundation.Date?

    /// Initializes a new `V2ErrorResponse`
    ///
    /// - Parameters:

    ///   - code: `Int` An HTTP response code that indicates the type of error.
    public init(code: Int) {
        clientToken = nil
        self.code = code
        message = nil
        timestamp = nil
    }

    /// Assign the clientToken property a `V2ErrorResponse` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` Opaque request-response correlation data.  Present only if a client token was used in the request.
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
    ///   - timestamp: `Foundation.Date` The date and time the response was generated by AWS IoT. This property is not present in all error response documents.
    public func withTimestamp(timestamp: Foundation.Date) {
        self.timestamp = timestamp
    }

}

/// Response payload to a DeleteShadow request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class DeleteShadowResponse: Codable {

    /// A client token used to correlate requests and responses.
    public var clientToken: String?

    /// The time the response was generated by AWS IoT.
    public var timestamp: Foundation.Date?

    /// The current version of the document for the device's shadow.
    public var version: Int?

    /// Initializes a new `DeleteShadowResponse`
    public init() {
        clientToken = nil
        timestamp = nil
        version = nil
    }

    /// Assign the clientToken property a `DeleteShadowResponse` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` A client token used to correlate requests and responses.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

    /// Assign the timestamp property a `DeleteShadowResponse` value
    ///
    /// - Parameters:
    ///   - timestamp: `Foundation.Date` The time the response was generated by AWS IoT.
    public func withTimestamp(timestamp: Foundation.Date) {
        self.timestamp = timestamp
    }

    /// Assign the version property a `DeleteShadowResponse` value
    ///
    /// - Parameters:
    ///   - version: `Int` The current version of the document for the device's shadow.
    public func withVersion(version: Int) {
        self.version = version
    }

}

/// Response payload to a GetShadow request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class GetShadowResponse: Codable {

    /// An opaque token used to correlate requests and responses.
    public var clientToken: String?

    /// The (classic) shadow state of the AWS IoT thing.
    public var state: ShadowStateWithDelta?

    /// Contains the timestamps for each attribute in the desired and reported sections of the state.
    public var metadata: ShadowMetadata?

    /// The time the response was generated by AWS IoT.
    public var timestamp: Foundation.Date?

    /// The current version of the document for the device's shadow shared in AWS IoT. It is increased by one over the previous version of the document.
    public var version: Int?

    /// Initializes a new `GetShadowResponse`
    public init() {
        clientToken = nil
        state = nil
        metadata = nil
        timestamp = nil
        version = nil
    }

    /// Assign the clientToken property a `GetShadowResponse` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` An opaque token used to correlate requests and responses.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

    /// Assign the state property a `GetShadowResponse` value
    ///
    /// - Parameters:
    ///   - state: `ShadowStateWithDelta` The (classic) shadow state of the AWS IoT thing.
    public func withState(state: ShadowStateWithDelta) {
        self.state = state
    }

    /// Assign the metadata property a `GetShadowResponse` value
    ///
    /// - Parameters:
    ///   - metadata: `ShadowMetadata` Contains the timestamps for each attribute in the desired and reported sections of the state.
    public func withMetadata(metadata: ShadowMetadata) {
        self.metadata = metadata
    }

    /// Assign the timestamp property a `GetShadowResponse` value
    ///
    /// - Parameters:
    ///   - timestamp: `Foundation.Date` The time the response was generated by AWS IoT.
    public func withTimestamp(timestamp: Foundation.Date) {
        self.timestamp = timestamp
    }

    /// Assign the version property a `GetShadowResponse` value
    ///
    /// - Parameters:
    ///   - version: `Int` The current version of the document for the device's shadow shared in AWS IoT. It is increased by one over the previous version of the document.
    public func withVersion(version: Int) {
        self.version = version
    }

}

/// Response payload to an UpdateShadow request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class UpdateShadowResponse: Codable {

    /// An opaque token used to correlate requests and responses.  Present only if a client token was used in the request.
    public var clientToken: String?

    /// Updated device shadow state.
    public var state: ShadowState?

    /// Contains the timestamps for each attribute in the desired and reported sections so that you can determine when the state was updated.
    public var metadata: ShadowMetadata?

    /// The time the response was generated by AWS IoT.
    public var timestamp: Foundation.Date?

    /// The current version of the document for the device's shadow shared in AWS IoT. It is increased by one over the previous version of the document.
    public var version: Int?

    /// Initializes a new `UpdateShadowResponse`
    public init() {
        clientToken = nil
        state = nil
        metadata = nil
        timestamp = nil
        version = nil
    }

    /// Assign the clientToken property a `UpdateShadowResponse` value
    ///
    /// - Parameters:
    ///   - clientToken: `String` An opaque token used to correlate requests and responses.  Present only if a client token was used in the request.
    public func withClientToken(clientToken: String) {
        self.clientToken = clientToken
    }

    /// Assign the state property a `UpdateShadowResponse` value
    ///
    /// - Parameters:
    ///   - state: `ShadowState` Updated device shadow state.
    public func withState(state: ShadowState) {
        self.state = state
    }

    /// Assign the metadata property a `UpdateShadowResponse` value
    ///
    /// - Parameters:
    ///   - metadata: `ShadowMetadata` Contains the timestamps for each attribute in the desired and reported sections so that you can determine when the state was updated.
    public func withMetadata(metadata: ShadowMetadata) {
        self.metadata = metadata
    }

    /// Assign the timestamp property a `UpdateShadowResponse` value
    ///
    /// - Parameters:
    ///   - timestamp: `Foundation.Date` The time the response was generated by AWS IoT.
    public func withTimestamp(timestamp: Foundation.Date) {
        self.timestamp = timestamp
    }

    /// Assign the version property a `UpdateShadowResponse` value
    ///
    /// - Parameters:
    ///   - version: `Int` The current version of the document for the device's shadow shared in AWS IoT. It is increased by one over the previous version of the document.
    public func withVersion(version: Int) {
        self.version = version
    }

}

/// Smithy structure for testing that contains all supported symbol types.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after instaitiation.
public class TestStructureData: Codable {

    /// Required thingName.
    public var thingName: String?

    /// Required shadowName.
    public var shadowName: String?

    /// Blob
    public var testBlob: Foundation.Data?

    /// Boolean
    public var testBoolean: Bool?

    /// String
    public var testString: String?

    /// Byte
    public var testByte: Int?

    /// Short
    public var testShort: Int?

    /// Integer
    public var testInteger: Int?

    /// Long
    public var testLong: Int?

    /// Float
    public var testFloat: Double?

    /// Double
    public var testDouble: Double?

    /// BigInteger
    public var testBigInteger: Int?

    /// BigDecimal
    public var testBigDecimal: Decimal?

    /// Timestamp
    public var testTimestamp: Foundation.Date?

    /// Document
    public var testDocument: [String: Any]?

    /// Test Enum
    public var testEnum: TestEnum?

    /// Initializes a new `TestStructureData`
    ///
    /// - Parameters:

    ///   - thingName: `String` Required thingName.

    ///   - shadowName: `String` Required shadowName.
    public init(thingName: String,
        shadowName: String) {
        self.thingName = thingName
        self.shadowName = shadowName
        testBlob = nil
        testBoolean = nil
        testString = nil
        testByte = nil
        testShort = nil
        testInteger = nil
        testLong = nil
        testFloat = nil
        testDouble = nil
        testBigInteger = nil
        testBigDecimal = nil
        testTimestamp = nil
        testDocument = nil
        testEnum = nil
    }

    /// Assign the testBlob property a `TestStructureData` value
    ///
    /// - Parameters:
    ///   - testBlob: `Foundation.Data` Blob
    public func withTestBlob(testBlob: Foundation.Data) {
        self.testBlob = testBlob
    }

    /// Assign the testBoolean property a `TestStructureData` value
    ///
    /// - Parameters:
    ///   - testBoolean: `Bool` Boolean
    public func withTestBoolean(testBoolean: Bool) {
        self.testBoolean = testBoolean
    }

    /// Assign the testString property a `TestStructureData` value
    ///
    /// - Parameters:
    ///   - testString: `String` String
    public func withTestString(testString: String) {
        self.testString = testString
    }

    /// Assign the testByte property a `TestStructureData` value
    ///
    /// - Parameters:
    ///   - testByte: `Int` Byte
    public func withTestByte(testByte: Int) {
        self.testByte = testByte
    }

    /// Assign the testShort property a `TestStructureData` value
    ///
    /// - Parameters:
    ///   - testShort: `Int` Short
    public func withTestShort(testShort: Int) {
        self.testShort = testShort
    }

    /// Assign the testInteger property a `TestStructureData` value
    ///
    /// - Parameters:
    ///   - testInteger: `Int` Integer
    public func withTestInteger(testInteger: Int) {
        self.testInteger = testInteger
    }

    /// Assign the testLong property a `TestStructureData` value
    ///
    /// - Parameters:
    ///   - testLong: `Int` Long
    public func withTestLong(testLong: Int) {
        self.testLong = testLong
    }

    /// Assign the testFloat property a `TestStructureData` value
    ///
    /// - Parameters:
    ///   - testFloat: `Double` Float
    public func withTestFloat(testFloat: Double) {
        self.testFloat = testFloat
    }

    /// Assign the testDouble property a `TestStructureData` value
    ///
    /// - Parameters:
    ///   - testDouble: `Double` Double
    public func withTestDouble(testDouble: Double) {
        self.testDouble = testDouble
    }

    /// Assign the testBigInteger property a `TestStructureData` value
    ///
    /// - Parameters:
    ///   - testBigInteger: `Int` BigInteger
    public func withTestBigInteger(testBigInteger: Int) {
        self.testBigInteger = testBigInteger
    }

    /// Assign the testBigDecimal property a `TestStructureData` value
    ///
    /// - Parameters:
    ///   - testBigDecimal: `Decimal` BigDecimal
    public func withTestBigDecimal(testBigDecimal: Decimal) {
        self.testBigDecimal = testBigDecimal
    }

    /// Assign the testTimestamp property a `TestStructureData` value
    ///
    /// - Parameters:
    ///   - testTimestamp: `Foundation.Date` Timestamp
    public func withTestTimestamp(testTimestamp: Foundation.Date) {
        self.testTimestamp = testTimestamp
    }

    /// Assign the testDocument property a `TestStructureData` value
    ///
    /// - Parameters:
    ///   - testDocument: `[String: Any]` Document
    public func withTestDocument(testDocument: [String: Any]) {
        self.testDocument = testDocument
    }

    /// Assign the testEnum property a `TestStructureData` value
    ///
    /// - Parameters:
    ///   - testEnum: `TestEnum` Test Enum
    public func withTestEnum(testEnum: TestEnum) {
        self.testEnum = testEnum
    }

    enum CodingKeys: String, CodingKey {
        case thingName,
             shadowName,
             testBlob,
             testBoolean,
             testString,
             testByte,
             testShort,
             testInteger,
             testLong,
             testFloat,
             testDouble,
             testBigInteger,
             testBigDecimal,
             testTimestamp,
             testDocument,
             testEnum
    }

    /// initialize this class containing the document trait from JSON
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.thingName = try container.decodeIfPresent(String.self , forKey: .thingName)
        self.shadowName = try container.decodeIfPresent(String.self , forKey: .shadowName)
        self.testBlob = try container.decodeIfPresent(Foundation.Data.self , forKey: .testBlob)
        self.testBoolean = try container.decodeIfPresent(Bool.self , forKey: .testBoolean)
        self.testString = try container.decodeIfPresent(String.self , forKey: .testString)
        self.testByte = try container.decodeIfPresent(Int.self , forKey: .testByte)
        self.testShort = try container.decodeIfPresent(Int.self , forKey: .testShort)
        self.testInteger = try container.decodeIfPresent(Int.self , forKey: .testInteger)
        self.testLong = try container.decodeIfPresent(Int.self , forKey: .testLong)
        self.testFloat = try container.decodeIfPresent(Double.self , forKey: .testFloat)
        self.testDouble = try container.decodeIfPresent(Double.self , forKey: .testDouble)
        self.testBigInteger = try container.decodeIfPresent(Int.self , forKey: .testBigInteger)
        self.testBigDecimal = try container.decodeIfPresent(Decimal.self , forKey: .testBigDecimal)
        self.testTimestamp = try container.decodeIfPresent(Foundation.Date.self , forKey: .testTimestamp)
        let testDocumentJSON = try container.decodeIfPresent([String: JSONValue].self, forKey: .testDocument)
        self.testDocument = testDocumentJSON?.asAnyDictionary()
        self.testEnum = try container.decodeIfPresent(TestEnum.self , forKey: .testEnum)
    }

    /// encode this class containing the document trait into JSON
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(thingName, forKey: .thingName)
        try container.encode(shadowName, forKey: .shadowName)
        try container.encode(testBlob, forKey: .testBlob)
        try container.encode(testBoolean, forKey: .testBoolean)
        try container.encode(testString, forKey: .testString)
        try container.encode(testByte, forKey: .testByte)
        try container.encode(testShort, forKey: .testShort)
        try container.encode(testInteger, forKey: .testInteger)
        try container.encode(testLong, forKey: .testLong)
        try container.encode(testFloat, forKey: .testFloat)
        try container.encode(testDouble, forKey: .testDouble)
        try container.encode(testBigInteger, forKey: .testBigInteger)
        try container.encode(testBigDecimal, forKey: .testBigDecimal)
        try container.encode(testTimestamp, forKey: .testTimestamp)
        if let testDocument = testDocument {
            let testDocumentJSON = testDocument.asJSONValueDictionary()
            try container.encode(testDocumentJSON, forKey: .testDocument)
        }
        try container.encode(testEnum, forKey: .testEnum)
    }
}

/// A test enum
public enum TestEnum: Int, Codable {

    /// TEST DOCUMENTATION 1
    case FIRST

    /// TEST DOCUMENTATION 2
    case SECOND

    /// TEST DOCUMENTATION 3
    case THIRD

    /// TEST DOCUMENTATION 4
    case FOURTH

    /// TEST DOCUMENTATION 5
    case FIFTH

    /// TEST DOCUMENTATION 6. None after.
    case SIXTH

    case SEVENTH

    case EIGHTH

    case NINTH

    case TENTH

}

enum IotShadowClientError: Error {
    case codeNotFound
    case shadowNameNotFound
    case thingNameNotFound
}

extension IotShadowClientError : LocalizedError {
    var errorDescription: String? {
        switch self {
        case .codeNotFound: return "Required argument: code was not found."
        case .shadowNameNotFound: return "Required argument: shadowName was not found."
        case .thingNameNotFound: return "Required argument: thingName was not found."
        }
    }
}

