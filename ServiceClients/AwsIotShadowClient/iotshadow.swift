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

  public init(
    mqttClient: AwsIotDeviceSdkSwift.Mqtt5Client, options: MqttRequestResponseClientOptions
  ) throws {
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
    request: NamedShadowDeltaUpdatedSubscriptionRequest,
    options: ClientStreamOptions<ShadowDeltaUpdatedEvent>
  ) throws -> StreamingOperation {
    var topic: String = "$aws/things/{thingName}/shadow/name/{shadowName}/update/delta"
    topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)
    topic = topic.replacingOccurrences(of: "{shadowName}", with: request.shadowName)

    let innerOptions: StreamingOperationOptions = StreamingOperationOptions(
      topicFilter: topic,
      subscriptionStatusCallback: { status in
        options.subscriptionEventHandler(status)
      },
      incomingPublishCallback: { publish in
        do {
          let event = try JSONDecoder().decode(
            ShadowDeltaUpdatedEvent.self, from: publish.payload)
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
    request: NamedShadowUpdatedSubscriptionRequest,
    options: ClientStreamOptions<ShadowUpdatedEvent>
  ) throws -> StreamingOperation {
    var topic: String = "$aws/things/{thingName}/shadow/name/{shadowName}/update/documents"
    topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)
    topic = topic.replacingOccurrences(of: "{shadowName}", with: request.shadowName)

    let innerOptions: StreamingOperationOptions = StreamingOperationOptions(
      topicFilter: topic,
      subscriptionStatusCallback: { status in
        options.subscriptionEventHandler(status)
      },
      incomingPublishCallback: { publish in
        do {
          let event = try JSONDecoder().decode(
            ShadowUpdatedEvent.self, from: publish.payload)
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
    request: ShadowDeltaUpdatedSubscriptionRequest,
    options: ClientStreamOptions<ShadowDeltaUpdatedEvent>
  ) throws -> StreamingOperation {
    var topic: String = "$aws/things/{thingName}/shadow/update/delta"
    topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)

    let innerOptions: StreamingOperationOptions = StreamingOperationOptions(
      topicFilter: topic,
      subscriptionStatusCallback: { status in
        options.subscriptionEventHandler(status)
      },
      incomingPublishCallback: { publish in
        do {
          let event = try JSONDecoder().decode(
            ShadowDeltaUpdatedEvent.self, from: publish.payload)
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
      subscriptionStatusCallback: { status in
        options.subscriptionEventHandler(status)
      },
      incomingPublishCallback: { publish in
        do {
          let event = try JSONDecoder().decode(
            ShadowUpdatedEvent.self, from: publish.payload)
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
  public func deleteNamedShadow(request: DeleteNamedShadowRequest) async throws
    -> DeleteShadowResponse
  {
    let correlationToken: String = request.clientToken

    // Publish Topic
    var topic: String = "$aws/things/{thingName}/shadow/name/{shadowName}/delete"
    topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)
    topic = topic.replacingOccurrences(of: "{shadowName}", with: request.shadowName)

    // Subscription Topic Filters
    var subscriptionTopicFilters: [String] = []
    var subscription0: String = "$aws/things/{thingName}/shadow/name/{shadowName}/delete/+"
    subscription0 = subscription0.replacingOccurrences(
      of: "{thingName}", with: request.thingName)
    subscription0 = subscription0.replacingOccurrences(
      of: "{shadowName}", with: request.shadowName)
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
        return try decoder.decode(DeleteShadowResponse.self, from: response.payload)
      } else {
        // Unsuccessful operation ack throws IotShadowClientError.errorResponse
        throw IotShadowClientError.errorResponse(
          try decoder.decode(V2ErrorResponse.self, from: response.payload))
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
    let correlationToken: String = request.clientToken

    // Publish Topic
    var topic: String = "$aws/things/{thingName}/shadow/delete"
    topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)

    // Subscription Topic Filters
    var subscriptionTopicFilters: [String] = []
    var subscription0: String = "$aws/things/{thingName}/shadow/delete/+"
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
        return try decoder.decode(DeleteShadowResponse.self, from: response.payload)
      } else {
        // Unsuccessful operation ack throws IotShadowClientError.errorResponse
        throw IotShadowClientError.errorResponse(
          try decoder.decode(V2ErrorResponse.self, from: response.payload))
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
    let correlationToken: String = request.clientToken

    // Publish Topic
    var topic: String = "$aws/things/{thingName}/shadow/name/{shadowName}/get"
    topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)
    topic = topic.replacingOccurrences(of: "{shadowName}", with: request.shadowName)

    // Subscription Topic Filters
    var subscriptionTopicFilters: [String] = []
    var subscription0: String = "$aws/things/{thingName}/shadow/name/{shadowName}/get/+"
    subscription0 = subscription0.replacingOccurrences(
      of: "{thingName}", with: request.thingName)
    subscription0 = subscription0.replacingOccurrences(
      of: "{shadowName}", with: request.shadowName)
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
        return try decoder.decode(GetShadowResponse.self, from: response.payload)
      } else {
        // Unsuccessful operation ack throws IotShadowClientError.errorResponse
        throw IotShadowClientError.errorResponse(
          try decoder.decode(V2ErrorResponse.self, from: response.payload))
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
    let correlationToken: String = request.clientToken

    // Publish Topic
    var topic: String = "$aws/things/{thingName}/shadow/get"
    topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)

    // Subscription Topic Filters
    var subscriptionTopicFilters: [String] = []
    var subscription0: String = "$aws/things/{thingName}/shadow/get/+"
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
        return try decoder.decode(GetShadowResponse.self, from: response.payload)
      } else {
        // Unsuccessful operation ack throws IotShadowClientError.errorResponse
        throw IotShadowClientError.errorResponse(
          try decoder.decode(V2ErrorResponse.self, from: response.payload))
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
  public func updateNamedShadow(request: UpdateNamedShadowRequest) async throws
    -> UpdateShadowResponse
  {
    let correlationToken: String = request.clientToken

    // Publish Topic
    var topic: String = "$aws/things/{thingName}/shadow/name/{shadowName}/update"
    topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)
    topic = topic.replacingOccurrences(of: "{shadowName}", with: request.shadowName)

    // Subscription Topic Filters
    var subscriptionTopicFilters: [String] = []
    var subscription0: String =
      "$aws/things/{thingName}/shadow/name/{shadowName}/update/accepted"
    subscription0 = subscription0.replacingOccurrences(
      of: "{thingName}", with: request.thingName)
    subscription0 = subscription0.replacingOccurrences(
      of: "{shadowName}", with: request.shadowName)
    subscriptionTopicFilters.append(subscription0)
    var subscription1: String =
      "$aws/things/{thingName}/shadow/name/{shadowName}/update/rejected"
    subscription1 = subscription1.replacingOccurrences(
      of: "{thingName}", with: request.thingName)
    subscription1 = subscription1.replacingOccurrences(
      of: "{shadowName}", with: request.shadowName)
    subscriptionTopicFilters.append(subscription1)

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
        return try decoder.decode(UpdateShadowResponse.self, from: response.payload)
      } else {
        // Unsuccessful operation ack throws IotShadowClientError.errorResponse
        throw IotShadowClientError.errorResponse(
          try decoder.decode(V2ErrorResponse.self, from: response.payload))
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
    let correlationToken: String = request.clientToken

    // Publish Topic
    var topic: String = "$aws/things/{thingName}/shadow/update"
    topic = topic.replacingOccurrences(of: "{thingName}", with: request.thingName)

    // Subscription Topic Filters
    var subscriptionTopicFilters: [String] = []
    var subscription0: String = "$aws/things/{thingName}/shadow/update/accepted"
    subscription0 = subscription0.replacingOccurrences(
      of: "{thingName}", with: request.thingName)
    subscriptionTopicFilters.append(subscription0)
    var subscription1: String = "$aws/things/{thingName}/shadow/update/rejected"
    subscription1 = subscription1.replacingOccurrences(
      of: "{thingName}", with: request.thingName)
    subscriptionTopicFilters.append(subscription1)

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
        return try decoder.decode(UpdateShadowResponse.self, from: response.payload)
      } else {
        // Unsuccessful operation ack throws IotShadowClientError.errorResponse
        throw IotShadowClientError.errorResponse(
          try decoder.decode(V2ErrorResponse.self, from: response.payload))
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
final public class ShadowState: Codable, Sendable {

  /// The desired shadow state (from external services and devices).
  private let desiredInternal: [String: JSONValue]?

  /// The (last) reported shadow state from the device.
  private let reportedInternal: [String: JSONValue]?

  /// Initializes a new `ShadowState`
  public init(
    desired: [String: Any]? = nil, reported: [String: Any]? = nil
  ) {
    self.desiredInternal = desired?.asJSONValueDictionary()
    self.reportedInternal = reported?.asJSONValueDictionary()
  }

  enum CodingKeys: String, CodingKey {
    case desired
    case reported
  }

  public var desired: [String: Any]? {
    return desiredInternal?.asAnyDictionary()
  }
  public var reported: [String: Any]? {
    return reportedInternal?.asAnyDictionary()
  }

  /// initialize this class containing the document trait from JSON
  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let desiredJSON = try container.decodeIfPresent([String: JSONValue].self, forKey: .desired)
    self.desiredInternal = desiredJSON
    let reportedJSON = try container.decodeIfPresent(
      [String: JSONValue].self, forKey: .reported)
    self.reportedInternal = reportedJSON
  }

  /// encode this class containing the document trait into JSON
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    if let desiredInternal = desiredInternal {
      try container.encode(desiredInternal, forKey: .desired)
    }
    if let reportedInternal = reportedInternal {
      try container.encode(reportedInternal, forKey: .reported)
    }
  }
}

/// (Potentially partial) state of an AWS IoT thing's shadow.  Includes the delta between the reported and desired states.
///
final public class ShadowStateWithDelta: Codable, Sendable {

  /// The desired shadow state (from external services and devices).
  private let desiredInternal: [String: JSONValue]?

  /// The (last) reported shadow state from the device.
  private let reportedInternal: [String: JSONValue]?

  /// The delta between the reported and desired states.
  private let deltaInternal: [String: JSONValue]?

  /// Initializes a new `ShadowStateWithDelta`
  public init(
    desired: [String: Any]? = nil, reported: [String: Any]? = nil, delta: [String: Any]? = nil
  ) {
    self.desiredInternal = desired?.asJSONValueDictionary()
    self.reportedInternal = reported?.asJSONValueDictionary()
    self.deltaInternal = delta?.asJSONValueDictionary()
  }

  enum CodingKeys: String, CodingKey {
    case desired
    case reported
    case delta
  }

  public var desired: [String: Any]? {
    return desiredInternal?.asAnyDictionary()
  }
  public var reported: [String: Any]? {
    return reportedInternal?.asAnyDictionary()
  }
  public var delta: [String: Any]? {
    return deltaInternal?.asAnyDictionary()
  }

  /// initialize this class containing the document trait from JSON
  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let desiredJSON = try container.decodeIfPresent([String: JSONValue].self, forKey: .desired)
    self.desiredInternal = desiredJSON
    let reportedJSON = try container.decodeIfPresent(
      [String: JSONValue].self, forKey: .reported)
    self.reportedInternal = reportedJSON
    let deltaJSON = try container.decodeIfPresent([String: JSONValue].self, forKey: .delta)
    self.deltaInternal = deltaJSON
  }

  /// encode this class containing the document trait into JSON
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    if let desiredInternal = desiredInternal {
      try container.encode(desiredInternal, forKey: .desired)
    }
    if let reportedInternal = reportedInternal {
      try container.encode(reportedInternal, forKey: .reported)
    }
    if let deltaInternal = deltaInternal {
      try container.encode(deltaInternal, forKey: .delta)
    }
  }
}

/// A description of the before and after states of a device shadow.
///
final public class ShadowUpdatedEvent: Codable, Sendable {

  /// Contains the state of the object before the update.
  public let previous: ShadowUpdatedSnapshot?

  /// Contains the state of the object after the update.
  public let current: ShadowUpdatedSnapshot?

  /// The time the event was generated by AWS IoT.
  public let timestamp: Foundation.Date?

  /// Initializes a new `ShadowUpdatedEvent`
  public init(
    previous: ShadowUpdatedSnapshot? = nil, current: ShadowUpdatedSnapshot? = nil,
    timestamp: Foundation.Date? = nil
  ) {
    self.previous = previous
    self.current = current
    self.timestamp = timestamp
  }

}

/// An event generated when a shadow document was updated by a request to AWS IoT.  The event payload contains only the changes requested.
///
final public class ShadowDeltaUpdatedEvent: Codable, Sendable {

  /// Shadow properties that were updated.
  private let stateInternal: [String: JSONValue]?

  /// Timestamps for the shadow properties that were updated.
  private let metadataInternal: [String: JSONValue]?

  /// The time the event was generated by AWS IoT.
  public let timestamp: Foundation.Date?

  /// The current version of the document for the device's shadow.
  public let version: Int?

  /// An opaque token used to correlate requests and responses.  Present only if a client token was used in the request.
  public let clientToken: String

  /// Initializes a new `ShadowDeltaUpdatedEvent`
  public init(
    state: [String: Any]? = nil, metadata: [String: Any]? = nil,
    timestamp: Foundation.Date? = nil, version: Int? = nil
  ) {
    self.stateInternal = state?.asJSONValueDictionary()
    self.metadataInternal = metadata?.asJSONValueDictionary()
    self.timestamp = timestamp
    self.version = version
    self.clientToken = UUID().uuidString
  }

  enum CodingKeys: String, CodingKey {
    case state
    case metadata
    case timestamp
    case version
    case clientToken
  }

  public var state: [String: Any]? {
    return stateInternal?.asAnyDictionary()
  }
  public var metadata: [String: Any]? {
    return metadataInternal?.asAnyDictionary()
  }

  /// initialize this class containing the document trait from JSON
  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let stateJSON = try container.decodeIfPresent([String: JSONValue].self, forKey: .state)
    self.stateInternal = stateJSON
    let metadataJSON = try container.decodeIfPresent(
      [String: JSONValue].self, forKey: .metadata)
    self.metadataInternal = metadataJSON
    self.timestamp = try container.decodeIfPresent(Foundation.Date.self, forKey: .timestamp)
    self.version = try container.decodeIfPresent(Int.self, forKey: .version)
    self.clientToken = try container.decode(String.self, forKey: .clientToken)
  }

  /// encode this class containing the document trait into JSON
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    if let stateInternal = stateInternal {
      try container.encode(stateInternal, forKey: .state)
    }
    if let metadataInternal = metadataInternal {
      try container.encode(metadataInternal, forKey: .metadata)
    }
    try container.encode(timestamp, forKey: .timestamp)
    try container.encode(version, forKey: .version)
    try container.encode(clientToken, forKey: .clientToken)
  }
}

/// Complete state of the (classic) shadow of an AWS IoT Thing.
///
final public class ShadowUpdatedSnapshot: Codable, Sendable {

  /// Current shadow state.
  public let state: ShadowState?

  /// Contains the timestamps for each attribute in the desired and reported sections of the state.
  public let metadata: ShadowMetadata?

  /// The current version of the document for the device's shadow.
  public let version: Int?

  /// Initializes a new `ShadowUpdatedSnapshot`
  public init(
    state: ShadowState? = nil, metadata: ShadowMetadata? = nil, version: Int? = nil
  ) {
    self.state = state
    self.metadata = metadata
    self.version = version
  }

}

/// Contains the last-updated timestamps for each attribute in the desired and reported sections of the shadow state.
///
final public class ShadowMetadata: Codable, Sendable {

  /// Contains the timestamps for each attribute in the desired section of a shadow's state.
  private let desiredInternal: [String: JSONValue]?

  /// Contains the timestamps for each attribute in the reported section of a shadow's state.
  private let reportedInternal: [String: JSONValue]?

  /// Initializes a new `ShadowMetadata`
  public init(
    desired: [String: Any]? = nil, reported: [String: Any]? = nil
  ) {
    self.desiredInternal = desired?.asJSONValueDictionary()
    self.reportedInternal = reported?.asJSONValueDictionary()
  }

  enum CodingKeys: String, CodingKey {
    case desired
    case reported
  }

  public var desired: [String: Any]? {
    return desiredInternal?.asAnyDictionary()
  }
  public var reported: [String: Any]? {
    return reportedInternal?.asAnyDictionary()
  }

  /// initialize this class containing the document trait from JSON
  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let desiredJSON = try container.decodeIfPresent([String: JSONValue].self, forKey: .desired)
    self.desiredInternal = desiredJSON
    let reportedJSON = try container.decodeIfPresent(
      [String: JSONValue].self, forKey: .reported)
    self.reportedInternal = reportedJSON
  }

  /// encode this class containing the document trait into JSON
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    if let desiredInternal = desiredInternal {
      try container.encode(desiredInternal, forKey: .desired)
    }
    if let reportedInternal = reportedInternal {
      try container.encode(reportedInternal, forKey: .reported)
    }
  }
}

/// Data needed to make a DeleteNamedShadow request.
///
final public class DeleteNamedShadowRequest: Codable, Sendable {

  /// AWS IoT thing to delete a named shadow from.
  public let thingName: String

  /// Name of the shadow to delete.
  public let shadowName: String

  /// An opaque token used to correlate requests and responses.  Present only if a client token was used in the request.
  public let clientToken: String

  /// Initializes a new `DeleteNamedShadowRequest`
  public init(
    thingName: String, shadowName: String
  ) {
    self.thingName = thingName
    self.shadowName = shadowName
    self.clientToken = UUID().uuidString
  }

}

/// Data needed to make a DeleteShadow request.
///
final public class DeleteShadowRequest: Codable, Sendable {

  /// AWS IoT thing to delete the (classic) shadow of.
  public let thingName: String

  /// An opaque token used to correlate requests and responses.  Present only if a client token was used in the request.
  public let clientToken: String

  /// Initializes a new `DeleteShadowRequest`
  public init(
    thingName: String
  ) {
    self.thingName = thingName
    self.clientToken = UUID().uuidString
  }

}

/// Data needed to make a GetNamedShadow request.
///
final public class GetNamedShadowRequest: Codable, Sendable {

  /// AWS IoT thing to get the named shadow for.
  public let thingName: String

  /// Name of the shadow to get.
  public let shadowName: String

  /// An opaque token used to correlate requests and responses.  Present only if a client token was used in the request.
  public let clientToken: String

  /// Initializes a new `GetNamedShadowRequest`
  public init(
    thingName: String, shadowName: String
  ) {
    self.thingName = thingName
    self.shadowName = shadowName
    self.clientToken = UUID().uuidString
  }

}

/// Data needed to make a GetShadow request.
///
final public class GetShadowRequest: Codable, Sendable {

  /// AWS IoT thing to get the (classic) shadow for.
  public let thingName: String

  /// An opaque token used to correlate requests and responses.  Present only if a client token was used in the request.
  public let clientToken: String

  /// Initializes a new `GetShadowRequest`
  public init(
    thingName: String
  ) {
    self.thingName = thingName
    self.clientToken = UUID().uuidString
  }

}

/// Data needed to make an UpdateNamedShadow request.
///
final public class UpdateNamedShadowRequest: Codable, Sendable {

  /// Aws IoT thing to update a named shadow of.
  public let thingName: String

  /// Name of the shadow to update.
  public let shadowName: String

  /// Requested changes to shadow state.  Updates affect only the fields specified.
  public let state: ShadowState?

  /// (Optional) The Device Shadow service applies the update only if the specified version matches the latest version.
  public let version: Int?

  /// An opaque token used to correlate requests and responses.  Present only if a client token was used in the request.
  public let clientToken: String

  /// Initializes a new `UpdateNamedShadowRequest`
  public init(
    thingName: String, shadowName: String, state: ShadowState? = nil, version: Int? = nil
  ) {
    self.thingName = thingName
    self.shadowName = shadowName
    self.state = state
    self.version = version
    self.clientToken = UUID().uuidString
  }

}

/// Data needed to make an UpdateShadow request.
///
final public class UpdateShadowRequest: Codable, Sendable {

  /// Aws IoT thing to update the (classic) shadow of.
  public let thingName: String

  /// Requested changes to the shadow state.  Updates affect only the fields specified.
  public let state: ShadowState?

  /// (Optional) The Device Shadow service processes the update only if the specified version matches the latest version.
  public let version: Int?

  /// An opaque token used to correlate requests and responses.  Present only if a client token was used in the request.
  public let clientToken: String

  /// Initializes a new `UpdateShadowRequest`
  public init(
    thingName: String, state: ShadowState? = nil, version: Int? = nil
  ) {
    self.thingName = thingName
    self.state = state
    self.version = version
    self.clientToken = UUID().uuidString
  }

}

/// Data needed to subscribe to DeleteNamedShadow responses for an AWS IoT thing.
///
final public class DeleteNamedShadowSubscriptionRequest: Codable, Sendable {

  /// AWS IoT thing to subscribe to DeleteNamedShadow operations for.
  public let thingName: String

  /// Name of the shadow to subscribe to DeleteNamedShadow operations for.
  public let shadowName: String

  /// Initializes a new `DeleteNamedShadowSubscriptionRequest`
  public init(
    thingName: String, shadowName: String
  ) {
    self.thingName = thingName
    self.shadowName = shadowName
  }

}

/// Data needed to subscribe to DeleteShadow responses for an AWS IoT thing.
///
final public class DeleteShadowSubscriptionRequest: Codable, Sendable {

  /// AWS IoT thing to subscribe to DeleteShadow operations for.
  public let thingName: String

  /// Initializes a new `DeleteShadowSubscriptionRequest`
  public init(
    thingName: String
  ) {
    self.thingName = thingName
  }

}

/// Data needed to subscribe to GetNamedShadow responses.
///
final public class GetNamedShadowSubscriptionRequest: Codable, Sendable {

  /// AWS IoT thing subscribe to GetNamedShadow responses for.
  public let thingName: String

  /// Name of the shadow to subscribe to GetNamedShadow responses for.
  public let shadowName: String

  /// Initializes a new `GetNamedShadowSubscriptionRequest`
  public init(
    thingName: String, shadowName: String
  ) {
    self.thingName = thingName
    self.shadowName = shadowName
  }

}

/// Data needed to subscribe to GetShadow responses.
///
final public class GetShadowSubscriptionRequest: Codable, Sendable {

  /// AWS IoT thing subscribe to GetShadow responses for.
  public let thingName: String

  /// Initializes a new `GetShadowSubscriptionRequest`
  public init(
    thingName: String
  ) {
    self.thingName = thingName
  }

}

/// Data needed to subscribe to UpdateNamedShadow responses.
///
final public class UpdateNamedShadowSubscriptionRequest: Codable, Sendable {

  /// Name of the AWS IoT thing to listen to UpdateNamedShadow responses for.
  public let thingName: String

  /// Name of the shadow to listen to UpdateNamedShadow responses for.
  public let shadowName: String

  /// Initializes a new `UpdateNamedShadowSubscriptionRequest`
  public init(
    thingName: String, shadowName: String
  ) {
    self.thingName = thingName
    self.shadowName = shadowName
  }

}

/// Data needed to subscribe to UpdateShadow responses.
///
final public class UpdateShadowSubscriptionRequest: Codable, Sendable {

  /// Name of the AWS IoT thing to listen to UpdateShadow responses for.
  public let thingName: String

  /// Initializes a new `UpdateShadowSubscriptionRequest`
  public init(
    thingName: String
  ) {
    self.thingName = thingName
  }

}

/// Data needed to subscribe to a device's NamedShadowDelta events.
///
final public class NamedShadowDeltaUpdatedSubscriptionRequest: Codable, Sendable {

  /// Name of the AWS IoT thing to get NamedShadowDelta events for.
  public let thingName: String

  /// Name of the shadow to get ShadowDelta events for.
  public let shadowName: String

  /// Initializes a new `NamedShadowDeltaUpdatedSubscriptionRequest`
  public init(
    thingName: String, shadowName: String
  ) {
    self.thingName = thingName
    self.shadowName = shadowName
  }

}

/// Data needed to subscribe to a device's NamedShadowUpdated events.
///
final public class NamedShadowUpdatedSubscriptionRequest: Codable, Sendable {

  /// Name of the AWS IoT thing to get NamedShadowUpdated events for.
  public let thingName: String

  /// Name of the shadow to get NamedShadowUpdated events for.
  public let shadowName: String

  /// Initializes a new `NamedShadowUpdatedSubscriptionRequest`
  public init(
    thingName: String, shadowName: String
  ) {
    self.thingName = thingName
    self.shadowName = shadowName
  }

}

/// Data needed to subscribe to a device's ShadowDelta events.
///
final public class ShadowDeltaUpdatedSubscriptionRequest: Codable, Sendable {

  /// Name of the AWS IoT thing to get ShadowDelta events for.
  public let thingName: String

  /// Initializes a new `ShadowDeltaUpdatedSubscriptionRequest`
  public init(
    thingName: String
  ) {
    self.thingName = thingName
  }

}

/// Data needed to subscribe to a device's ShadowUpdated events.
///
final public class ShadowUpdatedSubscriptionRequest: Codable, Sendable {

  /// Name of the AWS IoT thing to get ShadowUpdated events for.
  public let thingName: String

  /// Initializes a new `ShadowUpdatedSubscriptionRequest`
  public init(
    thingName: String
  ) {
    self.thingName = thingName
  }

}

/// Response document containing details about a failed request.
///
final public class ErrorResponse: Codable, Sendable {

  /// An HTTP response code that indicates the type of error.
  public let code: Int

  /// A text message that provides additional information.
  public let message: String?

  /// The date and time the response was generated by AWS IoT. This property is not present in all error response documents.
  public let timestamp: Foundation.Date?

  /// An opaque token used to correlate requests and responses.  Present only if a client token was used in the request.
  public let clientToken: String

  /// Initializes a new `ErrorResponse`
  public init(
    code: Int, message: String? = nil, timestamp: Foundation.Date? = nil
  ) {
    self.code = code
    self.message = message
    self.timestamp = timestamp
    self.clientToken = UUID().uuidString
  }

}

/// Response document containing details about a failed request.
///
final public class V2ErrorResponse: Codable, Sendable {

  /// An HTTP response code that indicates the type of error.
  public let code: Int

  /// A text message that provides additional information.
  public let message: String?

  /// The date and time the response was generated by AWS IoT. This property is not present in all error response documents.
  public let timestamp: Foundation.Date?

  /// An opaque token used to correlate requests and responses.  Present only if a client token was used in the request.
  public let clientToken: String

  /// Initializes a new `V2ErrorResponse`
  public init(
    code: Int, message: String? = nil, timestamp: Foundation.Date? = nil
  ) {
    self.code = code
    self.message = message
    self.timestamp = timestamp
    self.clientToken = UUID().uuidString
  }

}

/// Response payload to a DeleteShadow request.
///
final public class DeleteShadowResponse: Codable, Sendable {

  /// The time the response was generated by AWS IoT.
  public let timestamp: Foundation.Date?

  /// The current version of the document for the device's shadow.
  public let version: Int?

  /// An opaque token used to correlate requests and responses.  Present only if a client token was used in the request.
  public let clientToken: String

  /// Initializes a new `DeleteShadowResponse`
  public init(
    timestamp: Foundation.Date? = nil, version: Int? = nil
  ) {
    self.timestamp = timestamp
    self.version = version
    self.clientToken = UUID().uuidString
  }

}

/// Response payload to a GetShadow request.
///
final public class GetShadowResponse: Codable, Sendable {

  /// The (classic) shadow state of the AWS IoT thing.
  public let state: ShadowStateWithDelta?

  /// Contains the timestamps for each attribute in the desired and reported sections of the state.
  public let metadata: ShadowMetadata?

  /// The time the response was generated by AWS IoT.
  public let timestamp: Foundation.Date?

  /// The current version of the document for the device's shadow shared in AWS IoT. It is increased by one over the previous version of the document.
  public let version: Int?

  /// An opaque token used to correlate requests and responses.  Present only if a client token was used in the request.
  public let clientToken: String

  /// Initializes a new `GetShadowResponse`
  public init(
    state: ShadowStateWithDelta? = nil, metadata: ShadowMetadata? = nil,
    timestamp: Foundation.Date? = nil, version: Int? = nil
  ) {
    self.state = state
    self.metadata = metadata
    self.timestamp = timestamp
    self.version = version
    self.clientToken = UUID().uuidString
  }

}

/// Response payload to an UpdateShadow request.
///
final public class UpdateShadowResponse: Codable, Sendable {

  /// Updated device shadow state.
  public let state: ShadowState?

  /// Contains the timestamps for each attribute in the desired and reported sections so that you can determine when the state was updated.
  public let metadata: ShadowMetadata?

  /// The time the response was generated by AWS IoT.
  public let timestamp: Foundation.Date?

  /// The current version of the document for the device's shadow shared in AWS IoT. It is increased by one over the previous version of the document.
  public let version: Int?

  /// An opaque token used to correlate requests and responses.  Present only if a client token was used in the request.
  public let clientToken: String

  /// Initializes a new `UpdateShadowResponse`
  public init(
    state: ShadowState? = nil, metadata: ShadowMetadata? = nil,
    timestamp: Foundation.Date? = nil, version: Int? = nil
  ) {
    self.state = state
    self.metadata = metadata
    self.timestamp = timestamp
    self.version = version
    self.clientToken = UUID().uuidString
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
