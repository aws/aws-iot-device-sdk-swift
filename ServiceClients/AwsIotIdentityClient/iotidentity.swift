// Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
// SPDX-License-Identifier: Apache-2.0.

// This file is generated

import AwsIotDeviceSdkSwift
import Foundation

/// An AWS IoT service that assists with provisioning a device and installing unique client certificates on it
/// AWS Docs: https://docs.aws.amazon.com/iot/latest/developerguide/provision-wo-cert.html
public class IotIdentityClient {
  internal let rrClient: AwsIotDeviceSdkSwift.MqttRequestResponseClient
  internal let encoder: JSONEncoder = JSONEncoder()
  internal let decoder: JSONDecoder = JSONDecoder()

  public init(
    mqttClient: AwsIotDeviceSdkSwift.Mqtt5Client, options: MqttRequestResponseClientOptions
  ) throws {
    self.rrClient = try MqttRequestResponseClient(
      mqtt5Client: mqttClient, options: options)
  }

  /// Creates a certificate from a certificate signing request (CSR). AWS IoT provides client certificates that are signed by the Amazon Root certificate authority (CA). The new certificate has a PENDING_ACTIVATION status. When you call RegisterThing to provision a thing with this certificate, the certificate status changes to ACTIVE or INACTIVE as described in the template.
  ///
  /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/provision-wo-cert.html#fleet-provision-api
  ///
  /// - Parameters:
  ///     - request: `CreateCertificateFromCsrRequest` modeled request to perform.
  /// - Returns: `CreateCertificateFromCsrResponse`: with the corresponding response.
  ///
  /// - Throws: `IotIdentityClientError` Thrown when the provided request is rejected or when
  ///             a low-level `CRTError` or other underlying `Error` is thrown.
  public func createCertificateFromCsr(request: CreateCertificateFromCsrRequest) async throws
    -> CreateCertificateFromCsrResponse
  {
    let correlationToken: String? = nil

    // Publish Topic
    let topic: String = "$aws/certificates/create-from-csr/json"

    // Subscription Topic Filters
    var subscriptionTopicFilters: [String] = []
    let subscription0: String = "$aws/certificates/create-from-csr/json/accepted"
    subscriptionTopicFilters.append(subscription0)
    let subscription1: String = "$aws/certificates/create-from-csr/json/rejected"
    subscriptionTopicFilters.append(subscription1)

    // Response paths
    let responseTopic1: String = topic + "/accepted"
    let responseTopic2: String = topic + "/rejected"
    let token1 = ""
    let token2 = ""
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
          CreateCertificateFromCsrResponse.self, from: response.payload)
      } else {
        // Unsuccessful operation ack throws IotIdentityClientError.errorResponse
        throw IotIdentityClientError.errorResponse(
          try decoder.decode(V2ErrorResponse.self, from: response.payload))
      }
    } catch let clientErr as IotIdentityClientError {
      // Pass along the thrown IotIdentityClientError
      throw clientErr
    } catch let CommonRunTimeError.crtError(crtErr) {
      // Throw IotIdentityClientError.crt containing the `CRTError`
      throw IotIdentityClientError.crt(crtErr)
    } catch {
      // Throw IotIdentityClientError.underlying containing any other `Error`
      throw IotIdentityClientError.underlying(error)
    }
  }

  /// Creates new keys and a certificate. AWS IoT provides client certificates that are signed by the Amazon Root certificate authority (CA). The new certificate has a PENDING_ACTIVATION status. When you call RegisterThing to provision a thing with this certificate, the certificate status changes to ACTIVE or INACTIVE as described in the template.
  ///
  /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/provision-wo-cert.html#fleet-provision-api
  ///
  /// - Parameters:
  ///     - request: `CreateKeysAndCertificateRequest` modeled request to perform.
  /// - Returns: `CreateKeysAndCertificateResponse`: with the corresponding response.
  ///
  /// - Throws: `IotIdentityClientError` Thrown when the provided request is rejected or when
  ///             a low-level `CRTError` or other underlying `Error` is thrown.
  public func createKeysAndCertificate(request: CreateKeysAndCertificateRequest) async throws
    -> CreateKeysAndCertificateResponse
  {
    let correlationToken: String? = nil

    // Publish Topic
    let topic: String = "$aws/certificates/create/json"

    // Subscription Topic Filters
    var subscriptionTopicFilters: [String] = []
    let subscription0: String = "$aws/certificates/create/json/accepted"
    subscriptionTopicFilters.append(subscription0)
    let subscription1: String = "$aws/certificates/create/json/rejected"
    subscriptionTopicFilters.append(subscription1)

    // Response paths
    let responseTopic1: String = topic + "/accepted"
    let responseTopic2: String = topic + "/rejected"
    let token1 = ""
    let token2 = ""
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
          CreateKeysAndCertificateResponse.self, from: response.payload)
      } else {
        // Unsuccessful operation ack throws IotIdentityClientError.errorResponse
        throw IotIdentityClientError.errorResponse(
          try decoder.decode(V2ErrorResponse.self, from: response.payload))
      }
    } catch let clientErr as IotIdentityClientError {
      // Pass along the thrown IotIdentityClientError
      throw clientErr
    } catch let CommonRunTimeError.crtError(crtErr) {
      // Throw IotIdentityClientError.crt containing the `CRTError`
      throw IotIdentityClientError.crt(crtErr)
    } catch {
      // Throw IotIdentityClientError.underlying containing any other `Error`
      throw IotIdentityClientError.underlying(error)
    }
  }

  /// Provisions an AWS IoT thing using a pre-defined template.
  ///
  /// API Docs: https://docs.aws.amazon.com/iot/latest/developerguide/provision-wo-cert.html#fleet-provision-api
  ///
  /// - Parameters:
  ///     - request: `RegisterThingRequest` modeled request to perform.
  /// - Returns: `RegisterThingResponse`: with the corresponding response.
  ///
  /// - Throws: `IotIdentityClientError` Thrown when the provided request is rejected or when
  ///             a low-level `CRTError` or other underlying `Error` is thrown.
  public func registerThing(request: RegisterThingRequest) async throws -> RegisterThingResponse {
    let correlationToken: String? = nil

    // Publish Topic
    var topic: String = "$aws/provisioning-templates/{templateName}/provision/json"
    topic = topic.replacingOccurrences(of: "{templateName}", with: request.templateName)

    // Subscription Topic Filters
    var subscriptionTopicFilters: [String] = []
    var subscription0: String =
      "$aws/provisioning-templates/{templateName}/provision/json/accepted"
    subscription0 = subscription0.replacingOccurrences(
      of: "{templateName}", with: request.templateName)
    subscriptionTopicFilters.append(subscription0)
    var subscription1: String =
      "$aws/provisioning-templates/{templateName}/provision/json/rejected"
    subscription1 = subscription1.replacingOccurrences(
      of: "{templateName}", with: request.templateName)
    subscriptionTopicFilters.append(subscription1)

    // Response paths
    let responseTopic1: String = topic + "/accepted"
    let responseTopic2: String = topic + "/rejected"
    let token1 = ""
    let token2 = ""
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
        return try decoder.decode(RegisterThingResponse.self, from: response.payload)
      } else {
        // Unsuccessful operation ack throws IotIdentityClientError.errorResponse
        throw IotIdentityClientError.errorResponse(
          try decoder.decode(V2ErrorResponse.self, from: response.payload))
      }
    } catch let clientErr as IotIdentityClientError {
      // Pass along the thrown IotIdentityClientError
      throw clientErr
    } catch let CommonRunTimeError.crtError(crtErr) {
      // Throw IotIdentityClientError.crt containing the `CRTError`
      throw IotIdentityClientError.crt(crtErr)
    } catch {
      // Throw IotIdentityClientError.underlying containing any other `Error`
      throw IotIdentityClientError.underlying(error)
    }
  }

}

/// Data needed to perform a CreateCertificateFromCsr operation.
///
final public class CreateCertificateFromCsrRequest: Codable, Sendable {

  /// The CSR, in PEM format.
  public let certificateSigningRequest: String

  /// Initializes a new `CreateCertificateFromCsrRequest`
  public init(
    certificateSigningRequest: String
  ) {
    self.certificateSigningRequest = certificateSigningRequest
  }

}

/// Data needed to perform a CreateKeysAndCertificate operation.
///
final public class CreateKeysAndCertificateRequest: Codable, Sendable {

  /// Initializes a new `CreateKeysAndCertificateRequest`
  public init() {
  }

}

/// Data needed to perform a RegisterThing operation.
///
final public class RegisterThingRequest: Codable, Sendable {

  /// The provisioning template name.
  public let templateName: String

  /// The token to prove ownership of the certificate. The token is generated by AWS IoT when you create a certificate over MQTT.
  public let certificateOwnershipToken: String

  /// Optional. Key-value pairs from the device that are used by the pre-provisioning hooks to evaluate the registration request.
  public let parameters: [String: String]?

  /// Initializes a new `RegisterThingRequest`
  public init(
    templateName: String, certificateOwnershipToken: String, parameters: [String: String]? = nil
  ) {
    self.templateName = templateName
    self.certificateOwnershipToken = certificateOwnershipToken
    self.parameters = parameters
  }

}

/// Data needed to subscribe to the responses of the CreateCertificateFromCsr operation.
///
final public class CreateCertificateFromCsrSubscriptionRequest: Codable, Sendable {

  /// Initializes a new `CreateCertificateFromCsrSubscriptionRequest`
  public init() {
  }

}

/// Data needed to subscribe to the responses of the CreateKeysAndCertificate operation.
///
final public class CreateKeysAndCertificateSubscriptionRequest: Codable, Sendable {

  /// Initializes a new `CreateKeysAndCertificateSubscriptionRequest`
  public init() {
  }

}

/// Data needed to subscribe to the responses of the RegisterThing operation.
///
final public class RegisterThingSubscriptionRequest: Codable, Sendable {

  /// Name of the provisioning template to listen for RegisterThing responses for.
  public let templateName: String

  /// Initializes a new `RegisterThingSubscriptionRequest`
  public init(
    templateName: String
  ) {
    self.templateName = templateName
  }

}

/// Response document containing details about a failed request.
///
final public class ErrorResponse: Codable, Sendable {

  /// Response status code
  public let statusCode: Int?

  /// Response error code
  public let errorCode: String?

  /// Response error message
  public let errorMessage: String?

  /// Initializes a new `ErrorResponse`
  public init(
    statusCode: Int? = nil, errorCode: String? = nil, errorMessage: String? = nil
  ) {
    self.statusCode = statusCode
    self.errorCode = errorCode
    self.errorMessage = errorMessage
  }

}

/// Response document containing details about a failed request.
///
final public class V2ErrorResponse: Codable, Sendable {

  /// Response status code
  public let statusCode: Int?

  /// Response error code
  public let errorCode: String?

  /// Response error message
  public let errorMessage: String?

  /// Initializes a new `V2ErrorResponse`
  public init(
    statusCode: Int? = nil, errorCode: String? = nil, errorMessage: String? = nil
  ) {
    self.statusCode = statusCode
    self.errorCode = errorCode
    self.errorMessage = errorMessage
  }

}

/// Response payload to a CreateCertificateFromCsr request.
///
final public class CreateCertificateFromCsrResponse: Codable, Sendable {

  /// The ID of the certificate.
  public let certificateId: String?

  /// The certificate data, in PEM format.
  public let certificatePem: String?

  /// The token to prove ownership of the certificate during provisioning.
  public let certificateOwnershipToken: String?

  /// Initializes a new `CreateCertificateFromCsrResponse`
  public init(
    certificateId: String? = nil, certificatePem: String? = nil,
    certificateOwnershipToken: String? = nil
  ) {
    self.certificateId = certificateId
    self.certificatePem = certificatePem
    self.certificateOwnershipToken = certificateOwnershipToken
  }

}

/// Response payload to a CreateKeysAndCertificate request.
///
final public class CreateKeysAndCertificateResponse: Codable, Sendable {

  /// The certificate id.
  public let certificateId: String?

  /// The certificate data, in PEM format.
  public let certificatePem: String?

  /// The private key.
  public let privateKey: String?

  /// The token to prove ownership of the certificate during provisioning.
  public let certificateOwnershipToken: String?

  /// Initializes a new `CreateKeysAndCertificateResponse`
  public init(
    certificateId: String? = nil, certificatePem: String? = nil, privateKey: String? = nil,
    certificateOwnershipToken: String? = nil
  ) {
    self.certificateId = certificateId
    self.certificatePem = certificatePem
    self.privateKey = privateKey
    self.certificateOwnershipToken = certificateOwnershipToken
  }

}

/// Response payload to a RegisterThing request.
///
final public class RegisterThingResponse: Codable, Sendable {

  /// The device configuration defined in the template.
  public let deviceConfiguration: [String: String]?

  /// The name of the IoT thing created during provisioning.
  public let thingName: String?

  /// Initializes a new `RegisterThingResponse`
  public init(
    deviceConfiguration: [String: String]? = nil, thingName: String? = nil
  ) {
    self.deviceConfiguration = deviceConfiguration
    self.thingName = thingName
  }

}

/// Use the `IotIdentityClientError` enum to surface *all* errors thrown by the
/// IotIdentityClient. The three cases preserve the original error intact so
/// callers can inspect, log, or switch on them.
public enum IotIdentityClientError: Error, Sendable {
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
