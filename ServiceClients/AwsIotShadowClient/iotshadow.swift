// Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
// SPDX-License-Identifier: Apache-2.0.

// This file is generated

import Foundation
import AwsIotDeviceSdkSwift
import Foundation

/// The AWS IoT Device Shadow service adds shadows to AWS IoT thing objects. Shadows are a simple data store for device properties and state.  Shadows can make a device’s state available to apps and other services whether the device is connected to AWS IoT or not.
/// AWS Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html
public class IotShadowClient {
    internal let rrClient: AwsIotDeviceSdkSwift.MqttRequestResponseClient
    internal let encoder: JSONEncoder = JSONEncoder()
    internal let decoder: JSONDecoder = JSONDecoder()

    public init(mqttClient: AwsIotDeviceSdkSwift.Mqtt5Client, options: MqttRequestResponseClientOptions) throws {
        self.rrClient = try MqttRequestResponseClient.newFromMqtt5Client(
            mqtt5Client: mqttClient, options: options)
    }

    /// Create a stream for NamedShadowDelta events for a named shadow of an AWS IoT thing.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#update-delta-pub-sub-topic
    ///
    /// - Parameters:
    ///     - request: `NamedShadowDeltaUpdatedSubscriptionRequest` modeled streaming operation subscription configuration
    ///     - options: options set of callbacks that the operation should invoke in response to success, subscription status,
    ///         and deserialization failure.
    /// - Returns:
    ///     - `StreamingOperation`: which will invoke a callback every time a message is received on the associated MQTT topic.
    /// - Throws:
    ///     - `IotShadowClientError`
    public func createNamedShadowDeltaUpdatedStream(
        request: NamedShadowDeltaUpdatedSubscriptionRequest, options: ClientStreamOptions<ShadowDeltaUpdatedEvent>
    ) throws -> StreamingOperation {
        var topic: String = "$aws/things/{thingName}/shadow/name/{shadowName}/update/delta"
        topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)
        topic = topic.replacingOccurrences(of: "{shadowName}", with: request.shadowName)

        let innerOptions: StreamingOperationOptions = StreamingOperationOptions(
            topicFilter: topic,
            subscriptionStatusCallback:  { status in
                options.subscriptionEventHandler(status)
            },
            incomingPublishCallback:  { publish in
                do {
                    let event = try self.decoder.decode(ShadowDeltaUpdatedEvent.self, from: publish.payload)
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
        } catch let clientErr as IotShadowClientError {
            // Pass along the thrown IotShadowClientError
            throw clientErr
        } catch let CommonRunTimeError.crtError(crtErr) {
            // Throw IotShadowClientError.crt containing the `CRTError`
            throw IotShadowClientError.crt(crtErr)
        } catch {
            // Throw IotShadowClientError.underlying containing any other `Error`
            throw IotShadowClientError.underlying(error)
        }
    }

    /// Create a stream for ShadowUpdated events for a named shadow of an AWS IoT thing.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#update-documents-pub-sub-topic
    ///
    /// - Parameters:
    ///     - request: `NamedShadowUpdatedSubscriptionRequest` modeled streaming operation subscription configuration
    ///     - options: options set of callbacks that the operation should invoke in response to success, subscription status,
    ///         and deserialization failure.
    /// - Returns:
    ///     - `StreamingOperation`: which will invoke a callback every time a message is received on the associated MQTT topic.
    /// - Throws:
    ///     - `IotShadowClientError`
    public func createNamedShadowUpdatedStream(
        request: NamedShadowUpdatedSubscriptionRequest, options: ClientStreamOptions<ShadowUpdatedEvent>
    ) throws -> StreamingOperation {
        var topic: String = "$aws/things/{thingName}/shadow/name/{shadowName}/update/documents"
        topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)
        topic = topic.replacingOccurrences(of: "{shadowName}", with: request.shadowName)

        let innerOptions: StreamingOperationOptions = StreamingOperationOptions(
            topicFilter: topic,
            subscriptionStatusCallback:  { status in
                options.subscriptionEventHandler(status)
            },
            incomingPublishCallback:  { publish in
                do {
                    let event = try self.decoder.decode(ShadowUpdatedEvent.self, from: publish.payload)
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
        } catch let clientErr as IotShadowClientError {
            // Pass along the thrown IotShadowClientError
            throw clientErr
        } catch let CommonRunTimeError.crtError(crtErr) {
            // Throw IotShadowClientError.crt containing the `CRTError`
            throw IotShadowClientError.crt(crtErr)
        } catch {
            // Throw IotShadowClientError.underlying containing any other `Error`
            throw IotShadowClientError.underlying(error)
        }
    }

    /// Create a stream for ShadowDelta events for the (classic) shadow of an AWS IoT thing.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#update-delta-pub-sub-topic
    ///
    /// - Parameters:
    ///     - request: `ShadowDeltaUpdatedSubscriptionRequest` modeled streaming operation subscription configuration
    ///     - options: options set of callbacks that the operation should invoke in response to success, subscription status,
    ///         and deserialization failure.
    /// - Returns:
    ///     - `StreamingOperation`: which will invoke a callback every time a message is received on the associated MQTT topic.
    /// - Throws:
    ///     - `IotShadowClientError`
    public func createShadowDeltaUpdatedStream(
        request: ShadowDeltaUpdatedSubscriptionRequest, options: ClientStreamOptions<ShadowDeltaUpdatedEvent>
    ) throws -> StreamingOperation {
        var topic: String = "$aws/things/{thingName}/shadow/update/delta"
        topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)

        let innerOptions: StreamingOperationOptions = StreamingOperationOptions(
            topicFilter: topic,
            subscriptionStatusCallback:  { status in
                options.subscriptionEventHandler(status)
            },
            incomingPublishCallback:  { publish in
                do {
                    let event = try self.decoder.decode(ShadowDeltaUpdatedEvent.self, from: publish.payload)
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
        } catch let clientErr as IotShadowClientError {
            // Pass along the thrown IotShadowClientError
            throw clientErr
        } catch let CommonRunTimeError.crtError(crtErr) {
            // Throw IotShadowClientError.crt containing the `CRTError`
            throw IotShadowClientError.crt(crtErr)
        } catch {
            // Throw IotShadowClientError.underlying containing any other `Error`
            throw IotShadowClientError.underlying(error)
        }
    }

    /// Create a stream for ShadowUpdated events for the (classic) shadow of an AWS IoT thing.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#update-documents-pub-sub-topic
    ///
    /// - Parameters:
    ///     - request: `ShadowUpdatedSubscriptionRequest` modeled streaming operation subscription configuration
    ///     - options: options set of callbacks that the operation should invoke in response to success, subscription status,
    ///         and deserialization failure.
    /// - Returns:
    ///     - `StreamingOperation`: which will invoke a callback every time a message is received on the associated MQTT topic.
    /// - Throws:
    ///     - `IotShadowClientError`
    public func createShadowUpdatedStream(
        request: ShadowUpdatedSubscriptionRequest, options: ClientStreamOptions<ShadowUpdatedEvent>
    ) throws -> StreamingOperation {
        var topic: String = "$aws/things/{thingName}/shadow/update/documents"
        topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)

        let innerOptions: StreamingOperationOptions = StreamingOperationOptions(
            topicFilter: topic,
            subscriptionStatusCallback:  { status in
                options.subscriptionEventHandler(status)
            },
            incomingPublishCallback:  { publish in
                do {
                    let event = try self.decoder.decode(ShadowUpdatedEvent.self, from: publish.payload)
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
        } catch let clientErr as IotShadowClientError {
            // Pass along the thrown IotShadowClientError
            throw clientErr
        } catch let CommonRunTimeError.crtError(crtErr) {
            // Throw IotShadowClientError.crt containing the `CRTError`
            throw IotShadowClientError.crt(crtErr)
        } catch {
            // Throw IotShadowClientError.underlying containing any other `Error`
            throw IotShadowClientError.underlying(error)
        }
    }

    /// Deletes a named shadow for an AWS IoT thing.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#delete-pub-sub-topic
    ///
    /// - Parameters:
    ///     - request: `DeleteNamedShadowRequest` modeled request to perform.
    /// - Returns: `DeleteShadowResponse`: with the corresponding response.
    ///
    /// - Throws: `IotShadowClientError` Thrown when the provided request is rejected or when
    ///             a low-level `CRTError` or other underlying `Error` is thrown.
    public func deleteNamedShadow(request: DeleteNamedShadowRequest) async throws -> DeleteShadowResponse {

        let correlationToken: String = UUID().uuidString
        request.clientToken = correlationToken

        // Publish Topic
        var topic: String = "$aws/things/{thingName}/shadow/name/{shadowName}/delete"
        topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)
        topic = topic.replacingOccurrences(of: "{shadowName}", with: request.shadowName)

        // Subscription Topic Filters
        var subscriptionTopicFilters: [String] = []
        var subscription0: String = "$aws/things/{thingName}/shadow/name/{shadowName}/delete/+"
        subscription0 = subscription0.replacingOccurrences(of: "{thingName}", with: request.thingName)
        subscription0 = subscription0.replacingOccurrences(of: "{shadowName}", with: request.shadowName)
        subscriptionTopicFilters.append(subscription0)

        // Response paths
        let responseTopic1: String = topic + "/accepted"
        let responseTopic2: String = topic + "/rejected"
        let token1 = "clientToken"
        let token2 = "clientToken"
        let responsePath1: ResponsePath = ResponsePath(topic: responseTopic1, correlationTokenJsonPath: token1)
        let responsePath2: ResponsePath = ResponsePath(topic: responseTopic2, correlationTokenJsonPath: token2)

        do {
            // Encode the event into JSON Data.
            let payload = try encoder.encode(request)

            let requestResponseOperationOptions = RequestResponseOperationOptions(
                subscriptionTopicFilters: subscriptionTopicFilters,
                responsePaths: [responsePath1, responsePath2],
                topic: topic,
                payload: payload,
                correlationToken: correlationToken)

            let response = try await rrClient.submitRequest(operationOptions: requestResponseOperationOptions)

            if (response.topic == responseTopic1) {
                // Successful operation ack returns the expected output.
                return try decoder.decode(DeleteShadowResponse.self, from: response.payload)
            } else {
                // Unsuccessful operation ack throws IotShadowClientError.errorResponse
                throw IotShadowClientError.errorResponse(try decoder.decode(V2ErrorResponse.self, from: response.payload))
            }
        } catch let clientErr as IotShadowClientError {
            // Pass along the thrown IotShadowClientError
            throw clientErr
        } catch let CommonRunTimeError.crtError(crtErr) {
            // Throw IotShadowClientError.crt containing the `CRTError`
            throw IotShadowClientError.crt(crtErr)
        } catch {
            // Throw IotShadowClientError.underlying containing any other `Error`
            throw IotShadowClientError.underlying(error)
        }
    }

    /// Deletes the (classic) shadow for an AWS IoT thing.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#delete-pub-sub-topic
    ///
    /// - Parameters:
    ///     - request: `DeleteShadowRequest` modeled request to perform.
    /// - Returns: `DeleteShadowResponse`: with the corresponding response.
    ///
    /// - Throws: `IotShadowClientError` Thrown when the provided request is rejected or when
    ///             a low-level `CRTError` or other underlying `Error` is thrown.
    public func deleteShadow(request: DeleteShadowRequest) async throws -> DeleteShadowResponse {

        let correlationToken: String = UUID().uuidString
        request.clientToken = correlationToken

        // Publish Topic
        var topic: String = "$aws/things/{thingName}/shadow/delete"
        topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)

        // Subscription Topic Filters
        var subscriptionTopicFilters: [String] = []
        var subscription0: String = "$aws/things/{thingName}/shadow/delete/+"
        subscription0 = subscription0.replacingOccurrences(of: "{thingName}", with: request.thingName)
        subscriptionTopicFilters.append(subscription0)

        // Response paths
        let responseTopic1: String = topic + "/accepted"
        let responseTopic2: String = topic + "/rejected"
        let token1 = "clientToken"
        let token2 = "clientToken"
        let responsePath1: ResponsePath = ResponsePath(topic: responseTopic1, correlationTokenJsonPath: token1)
        let responsePath2: ResponsePath = ResponsePath(topic: responseTopic2, correlationTokenJsonPath: token2)

        do {
            // Encode the event into JSON Data.
            let payload = try encoder.encode(request)

            let requestResponseOperationOptions = RequestResponseOperationOptions(
                subscriptionTopicFilters: subscriptionTopicFilters,
                responsePaths: [responsePath1, responsePath2],
                topic: topic,
                payload: payload,
                correlationToken: correlationToken)

            let response = try await rrClient.submitRequest(operationOptions: requestResponseOperationOptions)

            if (response.topic == responseTopic1) {
                // Successful operation ack returns the expected output.
                return try decoder.decode(DeleteShadowResponse.self, from: response.payload)
            } else {
                // Unsuccessful operation ack throws IotShadowClientError.errorResponse
                throw IotShadowClientError.errorResponse(try decoder.decode(V2ErrorResponse.self, from: response.payload))
            }
        } catch let clientErr as IotShadowClientError {
            // Pass along the thrown IotShadowClientError
            throw clientErr
        } catch let CommonRunTimeError.crtError(crtErr) {
            // Throw IotShadowClientError.crt containing the `CRTError`
            throw IotShadowClientError.crt(crtErr)
        } catch {
            // Throw IotShadowClientError.underlying containing any other `Error`
            throw IotShadowClientError.underlying(error)
        }
    }

    /// Gets a named shadow for an AWS IoT thing.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#get-pub-sub-topic
    ///
    /// - Parameters:
    ///     - request: `GetNamedShadowRequest` modeled request to perform.
    /// - Returns: `GetShadowResponse`: with the corresponding response.
    ///
    /// - Throws: `IotShadowClientError` Thrown when the provided request is rejected or when
    ///             a low-level `CRTError` or other underlying `Error` is thrown.
    public func getNamedShadow(request: GetNamedShadowRequest) async throws -> GetShadowResponse {

        let correlationToken: String = UUID().uuidString
        request.clientToken = correlationToken

        // Publish Topic
        var topic: String = "$aws/things/{thingName}/shadow/name/{shadowName}/get"
        topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)
        topic = topic.replacingOccurrences(of: "{shadowName}", with: request.shadowName)

        // Subscription Topic Filters
        var subscriptionTopicFilters: [String] = []
        var subscription0: String = "$aws/things/{thingName}/shadow/name/{shadowName}/get/+"
        subscription0 = subscription0.replacingOccurrences(of: "{thingName}", with: request.thingName)
        subscription0 = subscription0.replacingOccurrences(of: "{shadowName}", with: request.shadowName)
        subscriptionTopicFilters.append(subscription0)

        // Response paths
        let responseTopic1: String = topic + "/accepted"
        let responseTopic2: String = topic + "/rejected"
        let token1 = "clientToken"
        let token2 = "clientToken"
        let responsePath1: ResponsePath = ResponsePath(topic: responseTopic1, correlationTokenJsonPath: token1)
        let responsePath2: ResponsePath = ResponsePath(topic: responseTopic2, correlationTokenJsonPath: token2)

        do {
            // Encode the event into JSON Data.
            let payload = try encoder.encode(request)

            let requestResponseOperationOptions = RequestResponseOperationOptions(
                subscriptionTopicFilters: subscriptionTopicFilters,
                responsePaths: [responsePath1, responsePath2],
                topic: topic,
                payload: payload,
                correlationToken: correlationToken)

            let response = try await rrClient.submitRequest(operationOptions: requestResponseOperationOptions)

            if (response.topic == responseTopic1) {
                // Successful operation ack returns the expected output.
                return try decoder.decode(GetShadowResponse.self, from: response.payload)
            } else {
                // Unsuccessful operation ack throws IotShadowClientError.errorResponse
                throw IotShadowClientError.errorResponse(try decoder.decode(V2ErrorResponse.self, from: response.payload))
            }
        } catch let clientErr as IotShadowClientError {
            // Pass along the thrown IotShadowClientError
            throw clientErr
        } catch let CommonRunTimeError.crtError(crtErr) {
            // Throw IotShadowClientError.crt containing the `CRTError`
            throw IotShadowClientError.crt(crtErr)
        } catch {
            // Throw IotShadowClientError.underlying containing any other `Error`
            throw IotShadowClientError.underlying(error)
        }
    }

    /// Gets the (classic) shadow for an AWS IoT thing.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#get-pub-sub-topic
    ///
    /// - Parameters:
    ///     - request: `GetShadowRequest` modeled request to perform.
    /// - Returns: `GetShadowResponse`: with the corresponding response.
    ///
    /// - Throws: `IotShadowClientError` Thrown when the provided request is rejected or when
    ///             a low-level `CRTError` or other underlying `Error` is thrown.
    public func getShadow(request: GetShadowRequest) async throws -> GetShadowResponse {

        let correlationToken: String = UUID().uuidString
        request.clientToken = correlationToken

        // Publish Topic
        var topic: String = "$aws/things/{thingName}/shadow/get"
        topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)

        // Subscription Topic Filters
        var subscriptionTopicFilters: [String] = []
        var subscription0: String = "$aws/things/{thingName}/shadow/get/+"
        subscription0 = subscription0.replacingOccurrences(of: "{thingName}", with: request.thingName)
        subscriptionTopicFilters.append(subscription0)

        // Response paths
        let responseTopic1: String = topic + "/accepted"
        let responseTopic2: String = topic + "/rejected"
        let token1 = "clientToken"
        let token2 = "clientToken"
        let responsePath1: ResponsePath = ResponsePath(topic: responseTopic1, correlationTokenJsonPath: token1)
        let responsePath2: ResponsePath = ResponsePath(topic: responseTopic2, correlationTokenJsonPath: token2)

        do {
            // Encode the event into JSON Data.
            let payload = try encoder.encode(request)

            let requestResponseOperationOptions = RequestResponseOperationOptions(
                subscriptionTopicFilters: subscriptionTopicFilters,
                responsePaths: [responsePath1, responsePath2],
                topic: topic,
                payload: payload,
                correlationToken: correlationToken)

            let response = try await rrClient.submitRequest(operationOptions: requestResponseOperationOptions)

            if (response.topic == responseTopic1) {
                // Successful operation ack returns the expected output.
                return try decoder.decode(GetShadowResponse.self, from: response.payload)
            } else {
                // Unsuccessful operation ack throws IotShadowClientError.errorResponse
                throw IotShadowClientError.errorResponse(try decoder.decode(V2ErrorResponse.self, from: response.payload))
            }
        } catch let clientErr as IotShadowClientError {
            // Pass along the thrown IotShadowClientError
            throw clientErr
        } catch let CommonRunTimeError.crtError(crtErr) {
            // Throw IotShadowClientError.crt containing the `CRTError`
            throw IotShadowClientError.crt(crtErr)
        } catch {
            // Throw IotShadowClientError.underlying containing any other `Error`
            throw IotShadowClientError.underlying(error)
        }
    }

    /// Update a named shadow for a device.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#update-pub-sub-topic
    ///
    /// - Parameters:
    ///     - request: `UpdateNamedShadowRequest` modeled request to perform.
    /// - Returns: `UpdateShadowResponse`: with the corresponding response.
    ///
    /// - Throws: `IotShadowClientError` Thrown when the provided request is rejected or when
    ///             a low-level `CRTError` or other underlying `Error` is thrown.
    public func updateNamedShadow(request: UpdateNamedShadowRequest) async throws -> UpdateShadowResponse {

        let correlationToken: String = UUID().uuidString
        request.clientToken = correlationToken

        // Publish Topic
        var topic: String = "$aws/things/{thingName}/shadow/name/{shadowName}/update"
        topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)
        topic = topic.replacingOccurrences(of: "{shadowName}", with: request.shadowName)

        // Subscription Topic Filters
        var subscriptionTopicFilters: [String] = []
        var subscription0: String = "$aws/things/{thingName}/shadow/name/{shadowName}/update/accepted"
        subscription0 = subscription0.replacingOccurrences(of: "{thingName}", with: request.thingName)
        subscription0 = subscription0.replacingOccurrences(of: "{shadowName}", with: request.shadowName)
        subscriptionTopicFilters.append(subscription0)
        var subscription1: String = "$aws/things/{thingName}/shadow/name/{shadowName}/update/rejected"
        subscription1 = subscription1.replacingOccurrences(of: "{thingName}", with: request.thingName)
        subscription1 = subscription1.replacingOccurrences(of: "{shadowName}", with: request.shadowName)
        subscriptionTopicFilters.append(subscription1)

        // Response paths
        let responseTopic1: String = topic + "/accepted"
        let responseTopic2: String = topic + "/rejected"
        let token1 = "clientToken"
        let token2 = "clientToken"
        let responsePath1: ResponsePath = ResponsePath(topic: responseTopic1, correlationTokenJsonPath: token1)
        let responsePath2: ResponsePath = ResponsePath(topic: responseTopic2, correlationTokenJsonPath: token2)

        do {
            // Encode the event into JSON Data.
            let payload = try encoder.encode(request)

            let requestResponseOperationOptions = RequestResponseOperationOptions(
                subscriptionTopicFilters: subscriptionTopicFilters,
                responsePaths: [responsePath1, responsePath2],
                topic: topic,
                payload: payload,
                correlationToken: correlationToken)

            let response = try await rrClient.submitRequest(operationOptions: requestResponseOperationOptions)

            if (response.topic == responseTopic1) {
                // Successful operation ack returns the expected output.
                return try decoder.decode(UpdateShadowResponse.self, from: response.payload)
            } else {
                // Unsuccessful operation ack throws IotShadowClientError.errorResponse
                throw IotShadowClientError.errorResponse(try decoder.decode(V2ErrorResponse.self, from: response.payload))
            }
        } catch let clientErr as IotShadowClientError {
            // Pass along the thrown IotShadowClientError
            throw clientErr
        } catch let CommonRunTimeError.crtError(crtErr) {
            // Throw IotShadowClientError.crt containing the `CRTError`
            throw IotShadowClientError.crt(crtErr)
        } catch {
            // Throw IotShadowClientError.underlying containing any other `Error`
            throw IotShadowClientError.underlying(error)
        }
    }

    /// Update a device's (classic) shadow.
    ///
    /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html#update-pub-sub-topic
    ///
    /// - Parameters:
    ///     - request: `UpdateShadowRequest` modeled request to perform.
    /// - Returns: `UpdateShadowResponse`: with the corresponding response.
    ///
    /// - Throws: `IotShadowClientError` Thrown when the provided request is rejected or when
    ///             a low-level `CRTError` or other underlying `Error` is thrown.
    public func updateShadow(request: UpdateShadowRequest) async throws -> UpdateShadowResponse {

        let correlationToken: String = UUID().uuidString
        request.clientToken = correlationToken

        // Publish Topic
        var topic: String = "$aws/things/{thingName}/shadow/update"
        topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)

        // Subscription Topic Filters
        var subscriptionTopicFilters: [String] = []
        var subscription0: String = "$aws/things/{thingName}/shadow/update/accepted"
        subscription0 = subscription0.replacingOccurrences(of: "{thingName}", with: request.thingName)
        subscriptionTopicFilters.append(subscription0)
        var subscription1: String = "$aws/things/{thingName}/shadow/update/rejected"
        subscription1 = subscription1.replacingOccurrences(of: "{thingName}", with: request.thingName)
        subscriptionTopicFilters.append(subscription1)

        // Response paths
        let responseTopic1: String = topic + "/accepted"
        let responseTopic2: String = topic + "/rejected"
        let token1 = "clientToken"
        let token2 = "clientToken"
        let responsePath1: ResponsePath = ResponsePath(topic: responseTopic1, correlationTokenJsonPath: token1)
        let responsePath2: ResponsePath = ResponsePath(topic: responseTopic2, correlationTokenJsonPath: token2)

        do {
            // Encode the event into JSON Data.
            let payload = try encoder.encode(request)

            let requestResponseOperationOptions = RequestResponseOperationOptions(
                subscriptionTopicFilters: subscriptionTopicFilters,
                responsePaths: [responsePath1, responsePath2],
                topic: topic,
                payload: payload,
                correlationToken: correlationToken)

            let response = try await rrClient.submitRequest(operationOptions: requestResponseOperationOptions)

            if (response.topic == responseTopic1) {
                // Successful operation ack returns the expected output.
                return try decoder.decode(UpdateShadowResponse.self, from: response.payload)
            } else {
                // Unsuccessful operation ack throws IotShadowClientError.errorResponse
                throw IotShadowClientError.errorResponse(try decoder.decode(V2ErrorResponse.self, from: response.payload))
            }
        } catch let clientErr as IotShadowClientError {
            // Pass along the thrown IotShadowClientError
            throw clientErr
        } catch let CommonRunTimeError.crtError(crtErr) {
            // Throw IotShadowClientError.crt containing the `CRTError`
            throw IotShadowClientError.crt(crtErr)
        } catch {
            // Throw IotShadowClientError.underlying containing any other `Error`
            throw IotShadowClientError.underlying(error)
        }
    }

}

/// (Potentially partial) state of an AWS IoT thing's shadow.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class ShadowState: Codable {

    /// The desired shadow state (from external services and devices).
    public var desired: [String: Any]?

    /// The (last) reported shadow state from the device.
    public var reported: [String: Any]?

    /// Initializes a new `ShadowState`
    /// - Parameters:
    public init() {
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
        case desired
        case reported
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
/// Use the provided builder with() functions to configure optional properties after initialization.
public class ShadowStateWithDelta: Codable {

    /// The desired shadow state (from external services and devices).
    public var desired: [String: Any]?

    /// The (last) reported shadow state from the device.
    public var reported: [String: Any]?

    /// The delta between the reported and desired states.
    public var delta: [String: Any]?

    /// Initializes a new `ShadowStateWithDelta`
    /// - Parameters:
    public init() {
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
        case desired
        case reported
        case delta
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
/// Use the provided builder with() functions to configure optional properties after initialization.
public class ShadowUpdatedEvent: Codable {

    /// Contains the state of the object before the update.
    public var previous: ShadowUpdatedSnapshot?

    /// Contains the state of the object after the update.
    public var current: ShadowUpdatedSnapshot?

    /// The time the event was generated by AWS IoT.
    public var timestamp: Foundation.Date?

    /// Initializes a new `ShadowUpdatedEvent`
    /// - Parameters:
    public init() {
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
/// Use the provided builder with() functions to configure optional properties after initialization.
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
    /// - Parameters:
    public init() {
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
        case state
        case metadata
        case timestamp
        case version
        case clientToken
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
/// Use the provided builder with() functions to configure optional properties after initialization.
public class ShadowUpdatedSnapshot: Codable {

    /// Current shadow state.
    public var state: ShadowState?

    /// Contains the timestamps for each attribute in the desired and reported sections of the state.
    public var metadata: ShadowMetadata?

    /// The current version of the document for the device's shadow.
    public var version: Int?

    /// Initializes a new `ShadowUpdatedSnapshot`
    /// - Parameters:
    public init() {
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
/// Use the provided builder with() functions to configure optional properties after initialization.
public class ShadowMetadata: Codable {

    /// Contains the timestamps for each attribute in the desired section of a shadow's state.
    public var desired: [String: Any]?

    /// Contains the timestamps for each attribute in the reported section of a shadow's state.
    public var reported: [String: Any]?

    /// Initializes a new `ShadowMetadata`
    /// - Parameters:
    public init() {
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
        case desired
        case reported
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
/// Use the provided builder with() functions to configure optional properties after initialization.
public class DeleteNamedShadowRequest: Codable {

    /// AWS IoT thing to delete a named shadow from.
    public var thingName: String

    /// Name of the shadow to delete.
    public var shadowName: String

    /// Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public var clientToken: String?

    /// Initializes a new `DeleteNamedShadowRequest`
    public init(
                thingName: String,
                shadowName: String) {
        self.thingName = thingName
        self.shadowName = shadowName
        self.clientToken = nil
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
/// Use the provided builder with() functions to configure optional properties after initialization.
public class DeleteShadowRequest: Codable {

    /// AWS IoT thing to delete the (classic) shadow of.
    public var thingName: String

    /// Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public var clientToken: String?

    /// Initializes a new `DeleteShadowRequest`
    public init(
                thingName: String) {
        self.thingName = thingName
        self.clientToken = nil
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
/// Use the provided builder with() functions to configure optional properties after initialization.
public class GetNamedShadowRequest: Codable {

    /// AWS IoT thing to get the named shadow for.
    public var thingName: String

    /// Name of the shadow to get.
    public var shadowName: String

    /// Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public var clientToken: String?

    /// Initializes a new `GetNamedShadowRequest`
    public init(
                thingName: String,
                shadowName: String) {
        self.thingName = thingName
        self.shadowName = shadowName
        self.clientToken = nil
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
/// Use the provided builder with() functions to configure optional properties after initialization.
public class GetShadowRequest: Codable {

    /// AWS IoT thing to get the (classic) shadow for.
    public var thingName: String

    /// Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public var clientToken: String?

    /// Initializes a new `GetShadowRequest`
    public init(
                thingName: String) {
        self.thingName = thingName
        self.clientToken = nil
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
/// Use the provided builder with() functions to configure optional properties after initialization.
public class UpdateNamedShadowRequest: Codable {

    /// Aws IoT thing to update a named shadow of.
    public var thingName: String

    /// Name of the shadow to update.
    public var shadowName: String

    /// Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public var clientToken: String?

    /// Requested changes to shadow state.  Updates affect only the fields specified.
    public var state: ShadowState?

    /// (Optional) The Device Shadow service applies the update only if the specified version matches the latest version.
    public var version: Int?

    /// Initializes a new `UpdateNamedShadowRequest`
    public init(
                thingName: String,
                shadowName: String) {
        self.thingName = thingName
        self.shadowName = shadowName
        self.clientToken = nil
        self.state = nil
        self.version = nil
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
/// Use the provided builder with() functions to configure optional properties after initialization.
public class UpdateShadowRequest: Codable {

    /// Aws IoT thing to update the (classic) shadow of.
    public var thingName: String

    /// Optional. A client token used to correlate requests and responses. Enter an arbitrary value here and it is reflected in the response.
    public var clientToken: String?

    /// Requested changes to the shadow state.  Updates affect only the fields specified.
    public var state: ShadowState?

    /// (Optional) The Device Shadow service processes the update only if the specified version matches the latest version.
    public var version: Int?

    /// Initializes a new `UpdateShadowRequest`
    public init(
                thingName: String) {
        self.thingName = thingName
        self.clientToken = nil
        self.state = nil
        self.version = nil
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
/// Use the provided builder with() functions to configure optional properties after initialization.
public class DeleteNamedShadowSubscriptionRequest: Codable {

    /// AWS IoT thing to subscribe to DeleteNamedShadow operations for.
    public var thingName: String

    /// Name of the shadow to subscribe to DeleteNamedShadow operations for.
    public var shadowName: String

    /// Initializes a new `DeleteNamedShadowSubscriptionRequest`
    public init(
                thingName: String,
                shadowName: String) {
        self.thingName = thingName
        self.shadowName = shadowName
    }

}

/// Data needed to subscribe to DeleteShadow responses for an AWS IoT thing.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class DeleteShadowSubscriptionRequest: Codable {

    /// AWS IoT thing to subscribe to DeleteShadow operations for.
    public var thingName: String

    /// Initializes a new `DeleteShadowSubscriptionRequest`
    public init(
                thingName: String) {
        self.thingName = thingName
    }

}

/// Data needed to subscribe to GetNamedShadow responses.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class GetNamedShadowSubscriptionRequest: Codable {

    /// AWS IoT thing subscribe to GetNamedShadow responses for.
    public var thingName: String

    /// Name of the shadow to subscribe to GetNamedShadow responses for.
    public var shadowName: String

    /// Initializes a new `GetNamedShadowSubscriptionRequest`
    public init(
                thingName: String,
                shadowName: String) {
        self.thingName = thingName
        self.shadowName = shadowName
    }

}

/// Data needed to subscribe to GetShadow responses.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class GetShadowSubscriptionRequest: Codable {

    /// AWS IoT thing subscribe to GetShadow responses for.
    public var thingName: String

    /// Initializes a new `GetShadowSubscriptionRequest`
    public init(
                thingName: String) {
        self.thingName = thingName
    }

}

/// Data needed to subscribe to UpdateNamedShadow responses.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class UpdateNamedShadowSubscriptionRequest: Codable {

    /// Name of the AWS IoT thing to listen to UpdateNamedShadow responses for.
    public var thingName: String

    /// Name of the shadow to listen to UpdateNamedShadow responses for.
    public var shadowName: String

    /// Initializes a new `UpdateNamedShadowSubscriptionRequest`
    public init(
                thingName: String,
                shadowName: String) {
        self.thingName = thingName
        self.shadowName = shadowName
    }

}

/// Data needed to subscribe to UpdateShadow responses.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class UpdateShadowSubscriptionRequest: Codable {

    /// Name of the AWS IoT thing to listen to UpdateShadow responses for.
    public var thingName: String

    /// Initializes a new `UpdateShadowSubscriptionRequest`
    public init(
                thingName: String) {
        self.thingName = thingName
    }

}

/// Data needed to subscribe to a device's NamedShadowDelta events.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class NamedShadowDeltaUpdatedSubscriptionRequest: Codable {

    /// Name of the AWS IoT thing to get NamedShadowDelta events for.
    public var thingName: String

    /// Name of the shadow to get ShadowDelta events for.
    public var shadowName: String

    /// Initializes a new `NamedShadowDeltaUpdatedSubscriptionRequest`
    public init(
                thingName: String,
                shadowName: String) {
        self.thingName = thingName
        self.shadowName = shadowName
    }

}

/// Data needed to subscribe to a device's NamedShadowUpdated events.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class NamedShadowUpdatedSubscriptionRequest: Codable {

    /// Name of the AWS IoT thing to get NamedShadowUpdated events for.
    public var thingName: String

    /// Name of the shadow to get NamedShadowUpdated events for.
    public var shadowName: String

    /// Initializes a new `NamedShadowUpdatedSubscriptionRequest`
    public init(
                thingName: String,
                shadowName: String) {
        self.thingName = thingName
        self.shadowName = shadowName
    }

}

/// Data needed to subscribe to a device's ShadowDelta events.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class ShadowDeltaUpdatedSubscriptionRequest: Codable {

    /// Name of the AWS IoT thing to get ShadowDelta events for.
    public var thingName: String

    /// Initializes a new `ShadowDeltaUpdatedSubscriptionRequest`
    public init(
                thingName: String) {
        self.thingName = thingName
    }

}

/// Data needed to subscribe to a device's ShadowUpdated events.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class ShadowUpdatedSubscriptionRequest: Codable {

    /// Name of the AWS IoT thing to get ShadowUpdated events for.
    public var thingName: String

    /// Initializes a new `ShadowUpdatedSubscriptionRequest`
    public init(
                thingName: String) {
        self.thingName = thingName
    }

}

/// Response document containing details about a failed request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class ErrorResponse: Codable {

    /// An HTTP response code that indicates the type of error.
    public var code: Int

    /// Opaque request-response correlation data.  Present only if a client token was used in the request.
    public var clientToken: String?

    /// A text message that provides additional information.
    public var message: String?

    /// The date and time the response was generated by AWS IoT. This property is not present in all error response documents.
    public var timestamp: Foundation.Date?

    /// Initializes a new `ErrorResponse`
    public init(
                code: Int) {
        self.code = code
        self.clientToken = nil
        self.message = nil
        self.timestamp = nil
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
/// Use the provided builder with() functions to configure optional properties after initialization.
public class V2ErrorResponse: Codable, @unchecked Sendable {

    /// An HTTP response code that indicates the type of error.
    public let code: Int

    /// Opaque request-response correlation data.  Present only if a client token was used in the request.
    public let clientToken: String?

    /// A text message that provides additional information.
    public let message: String?

    /// The date and time the response was generated by AWS IoT. This property is not present in all error response documents.
    public let timestamp: Foundation.Date?

    /// Initializes a new `V2ErrorResponse`
    public init(
                clientToken: String? = nil,
                code: Int,
                message: String? = nil,
                timestamp: Foundation.Date? = nil) {
        self.clientToken = clientToken
        self.code = code
        self.message = message
        self.timestamp = timestamp
    }

}

/// Response payload to a DeleteShadow request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class DeleteShadowResponse: Codable {

    /// A client token used to correlate requests and responses.
    public var clientToken: String?

    /// The time the response was generated by AWS IoT.
    public var timestamp: Foundation.Date?

    /// The current version of the document for the device's shadow.
    public var version: Int?

    /// Initializes a new `DeleteShadowResponse`
    /// - Parameters:
    public init() {
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
/// Use the provided builder with() functions to configure optional properties after initialization.
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
    /// - Parameters:
    public init() {
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
/// Use the provided builder with() functions to configure optional properties after initialization.
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
    /// - Parameters:
    public init() {
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
        deserializationFailureHandler: @escaping FailureHandler = { _ in }) {
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
        self.cause   = cause
        self.payload = payload
        self.topic   = topic
    }
}

/// Use the `IotShadowClientError` enum to surface *all* errors thrown by the
/// IotShadowClient. The three cases preserve the original error intact so
/// callers can inspect, log, or switch on them.
public enum IotShadowClientError: Error, Sendable {
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

