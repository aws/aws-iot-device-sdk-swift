import Foundation

/// The type of change to the state of a streaming operation subscription
public enum SubscriptionStatusEventType {
    /**
     * The streaming operation is successfully subscribed to its topic (filter)
     */
    case established

    /**
     * The streaming operation has temporarily lost its subscription to its topic (filter)
     */
    case lost

    /**
     * The streaming operation has entered a terminal state where it has given up trying to subscribe
     * to its topic (filter).  This is always due to user error (bad topic filter or IoT Core permission
     * policy).
     */
    case halted
}

/// An event that describes a change in subscription status for a streaming operation.
public struct SubscriptionStatusEvent {
    /// The type of the event
    public let event: SubscriptionStatusEventType

    /// An optional error code associated with the event. Only set for SubscriptionLost and SubscriptionHalted.
    public let error: CRTError?
}

// TODO: Igor has updated the events for IoT Command. Need update later
/// An event that describes an incoming publish message received on a streaming operation.
public struct IncomingPublishEvent {

    /// The payload of the publish message in a byte buffer format
    let payload: Data

    /// The topic associated with this PUBLISH packet.
    let topic: String

    // TODO: More options for IoT Command changes
}

/// Function signature of a SubscriptionStatusEvent event handler
public typealias SubscriptionStatusEventHandler = @Sendable (SubscriptionStatusEvent) async -> Void

/// Function signature of an IncomingPublishEvent event handler
public typealias IncomingPublishEventHandler = @Sendable (IncomingPublishEvent) async -> Void

/// Encapsulates a response to an AWS IoT Core MQTT-based service request
public struct MqttRequestResponseResponse {
    public let topic: String
    public let payload: Data
}

/// A response path is a pair of values - MQTT topic and a JSON path - that describe where a response to
/// an MQTT-based request may arrive.  For a given request type, there may be multiple response paths and each
/// one is associated with a separate JSON schema for the response body.
public struct ResponsePath {
    let topic: String
    let correlationTokenJsonPath: [String]
}

/// Generic configuration options for request response operation
public struct RequestResponseOperationOptions {
    let subscriptionTopicFilters: [String]
    let responsePaths: [ResponsePath]?
    let topic: String
    let payload: Data
    let correlationToken: [String]?

    public init(
        subscriptionTopicFilters: [String], responsePaths: [ResponsePath]?, topic: String,
        payload: Data, correlationToken: [String]?
    ) {
        self.subscriptionTopicFilters = subscriptionTopicFilters
        self.responsePaths = responsePaths
        self.topic = topic
        self.payload = payload
        self.correlationToken = correlationToken
    }
}

/// Configuration options for streaming operations
public struct StreamingOperationOptions {
    let subscriptionStatusEventHandler: SubscriptionStatusEventHandler
    let incomingPublishEventHandler: IncomingPublishEventHandler
    let topicFilter: String

    public init(
        subscriptionStatusEventHandler: @escaping SubscriptionStatusEventHandler,
        incomingPublishEventHandler: @escaping IncomingPublishEventHandler,
        topicFilter: String
    ) {
        self.subscriptionStatusEventHandler = subscriptionStatusEventHandler
        self.incomingPublishEventHandler = incomingPublishEventHandler
        self.topicFilter = topicFilter
    }
}

/// A streaming operation is automatically closed (and an MQTT unsubscribe triggered) when its
/// destructor is invoked.
public class StreamingOperation {
    public init() {
    }

    /**
     * Opens a streaming operation by making the appropriate MQTT subscription with the broker.
     */
    public func open() {
        // TODO:
    }

    deinit {
        // TODO: close the oepration
    }
}

// Place holder for
public typealias StreamStatusHandler = (SubscriptionStatusEvent) async -> Void

public class MqttRequestResponseClient {
    let mqttClient: Mqtt5Client

    public init(mqttClient: Mqtt5Client) {
        self.mqttClient = mqttClient
    }

    /// Submit a request responds operation, throws CRTError if the operation failed
    ///
    /// - Parameters:
    ///     - operationOptions: configuration options for request response operation
    /// - Returns:
    ///     - MqttRequestResponseResponse
    /// - Throws:CommonRuntimeError.crtError if submit failed
    public func submitRequest(operationOptions: RequestResponseOperationOptions) async throws
        -> MqttRequestResponseResponse
    {
        print("Mqtt Request Response Client submitRequest()")
        if let payloadJSON = String(data: operationOptions.payload, encoding: .utf8) {
            print("payloadJSON: " + payloadJSON)
        } else {
            print("payloadJSON not creatable from operationOptions.payload")
        }
        return MqttRequestResponseResponse(topic: "", payload: operationOptions.payload)
    }

    /// Create a stream operation, throws CRTError if the creation failed. You would need call open() on the operation to start the stream
    /// - Parameters:
    ///     - streamOptions: Configuration options for streaming operations
    /// - Returns:
    ///     - StreamingOperation
    /// - Throws:CommonRuntimeError.crtError if creation failed
    public func createStream(streamOptions: StreamingOperationOptions) async throws
        -> StreamingOperation
    {
        print("Mqtt Request Response Client createStream()")
        print("topic recieved is: " + streamOptions.topicFilter)
        // TODO: create streamming operation
        return StreamingOperation()
    }
}
