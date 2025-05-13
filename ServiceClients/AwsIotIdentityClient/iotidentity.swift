// Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
// SPDX-License-Identifier: Apache-2.0.

// This file is generated

import Foundation
import AwsIotDeviceSdkSwift

/// An AWS IoT service that assists with provisioning a device and installing unique client certificates on it
/// AWS Docs: https://docs.aws.amazon.com/iot/latest/developerguide/provision-wo-cert.html
public class IotIdentityClient {
    internal let rrClient: AwsIotDeviceSdkSwift.MqttRequestResponseClient
    internal let encoder: JSONEncoder = JSONEncoder()
    internal let decoder: JSONDecoder = JSONDecoder()

    public init(mqttClient: AwsIotDeviceSdkSwift.Mqtt5Client, options: MqttRequestResponseClientOptions) throws {
        self.rrClient = try MqttRequestResponseClient.newFromMqtt5Client(
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
    public func createCertificateFromCsr(request: CreateCertificateFromCsrRequest) async throws -> CreateCertificateFromCsrResponse {

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
                return try decoder.decode(CreateCertificateFromCsrResponse.self, from: response.payload)
            } else {
                // Unsuccessful operation ack throws IotIdentityClientError.errorResponse
                throw IotIdentityClientError.errorResponse(try decoder.decode(V2ErrorResponse.self, from: response.payload))
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
    public func createKeysAndCertificate(request: CreateKeysAndCertificateRequest) async throws -> CreateKeysAndCertificateResponse {

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
                return try decoder.decode(CreateKeysAndCertificateResponse.self, from: response.payload)
            } else {
                // Unsuccessful operation ack throws IotIdentityClientError.errorResponse
                throw IotIdentityClientError.errorResponse(try decoder.decode(V2ErrorResponse.self, from: response.payload))
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
        var subscription0: String = "$aws/provisioning-templates/{templateName}/provision/json/accepted"
        subscription0 = subscription0.replacingOccurrences(of: "{templateName}", with: request.templateName)
        subscriptionTopicFilters.append(subscription0)
        var subscription1: String = "$aws/provisioning-templates/{templateName}/provision/json/rejected"
        subscription1 = subscription1.replacingOccurrences(of: "{templateName}", with: request.templateName)
        subscriptionTopicFilters.append(subscription1)

        // Response paths
        let responseTopic1: String = topic + "/accepted"
        let responseTopic2: String = topic + "/rejected"
        let token1 = ""
        let token2 = ""
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
                return try decoder.decode(RegisterThingResponse.self, from: response.payload)
            } else {
                // Unsuccessful operation ack throws IotIdentityClientError.errorResponse
                throw IotIdentityClientError.errorResponse(try decoder.decode(V2ErrorResponse.self, from: response.payload))
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
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class CreateCertificateFromCsrRequest: Codable {

    /// The CSR, in PEM format.
    public var certificateSigningRequest: String

    /// Initializes a new `CreateCertificateFromCsrRequest`
    public init(
                certificateSigningRequest: String) {
        self.certificateSigningRequest = certificateSigningRequest
    }

}

/// Data needed to perform a CreateKeysAndCertificate operation.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class CreateKeysAndCertificateRequest: Codable {

    /// This class has no properties.
}

/// Data needed to perform a RegisterThing operation.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class RegisterThingRequest: Codable {

    /// The provisioning template name.
    public var templateName: String

    /// The token to prove ownership of the certificate. The token is generated by AWS IoT when you create a certificate over MQTT.
    public var certificateOwnershipToken: String

    /// Optional. Key-value pairs from the device that are used by the pre-provisioning hooks to evaluate the registration request.
    public var parameters: [String: String]?

    /// Initializes a new `RegisterThingRequest`
    public init(
                templateName: String,
                certificateOwnershipToken: String) {
        self.templateName = templateName
        self.certificateOwnershipToken = certificateOwnershipToken
        self.parameters = nil
    }

    /// Assign the parameters property a `RegisterThingRequest` value
    ///
    /// - Parameters:
    ///   - parameters: `[String: String]` Optional. Key-value pairs from the device that are used by the pre-provisioning hooks to evaluate the registration request.
    public func withParameters(parameters: [String: String]) {
        self.parameters = parameters
    }

}

/// Data needed to subscribe to the responses of the CreateCertificateFromCsr operation.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class CreateCertificateFromCsrSubscriptionRequest: Codable {

    /// This class has no properties.
}

/// Data needed to subscribe to the responses of the CreateKeysAndCertificate operation.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class CreateKeysAndCertificateSubscriptionRequest: Codable {

    /// This class has no properties.
}

/// Data needed to subscribe to the responses of the RegisterThing operation.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class RegisterThingSubscriptionRequest: Codable {

    /// Name of the provisioning template to listen for RegisterThing responses for.
    public var templateName: String

    /// Initializes a new `RegisterThingSubscriptionRequest`
    public init(
                templateName: String) {
        self.templateName = templateName
    }

}

/// Response document containing details about a failed request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class ErrorResponse: Codable {

    /// Response status code
    public var statusCode: Int?

    /// Response error code
    public var errorCode: String?

    /// Response error message
    public var errorMessage: String?

    /// Initializes a new `ErrorResponse`
    /// - Parameters:
    public init() {
    }

    /// Assign the statusCode property a `ErrorResponse` value
    ///
    /// - Parameters:
    ///   - statusCode: `Int` Response status code
    public func withStatusCode(statusCode: Int) {
        self.statusCode = statusCode
    }

    /// Assign the errorCode property a `ErrorResponse` value
    ///
    /// - Parameters:
    ///   - errorCode: `String` Response error code
    public func withErrorCode(errorCode: String) {
        self.errorCode = errorCode
    }

    /// Assign the errorMessage property a `ErrorResponse` value
    ///
    /// - Parameters:
    ///   - errorMessage: `String` Response error message
    public func withErrorMessage(errorMessage: String) {
        self.errorMessage = errorMessage
    }

}

/// Response document containing details about a failed request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class V2ErrorResponse: Codable, @unchecked Sendable {

    /// Response status code
    public let statusCode: Int?

    /// Response error code
    public let errorCode: String?

    /// Response error message
    public let errorMessage: String?

    /// Initializes a new `V2ErrorResponse`
    public init(
                statusCode: Int? = nil,
                errorCode: String? = nil,
                errorMessage: String? = nil) {
        self.statusCode = statusCode
        self.errorCode = errorCode
        self.errorMessage = errorMessage
    }

}

/// Response payload to a CreateCertificateFromCsr request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class CreateCertificateFromCsrResponse: Codable {

    /// The ID of the certificate.
    public var certificateId: String?

    /// The certificate data, in PEM format.
    public var certificatePem: String?

    /// The token to prove ownership of the certificate during provisioning.
    public var certificateOwnershipToken: String?

    /// Initializes a new `CreateCertificateFromCsrResponse`
    /// - Parameters:
    public init() {
    }

    /// Assign the certificateId property a `CreateCertificateFromCsrResponse` value
    ///
    /// - Parameters:
    ///   - certificateId: `String` The ID of the certificate.
    public func withCertificateId(certificateId: String) {
        self.certificateId = certificateId
    }

    /// Assign the certificatePem property a `CreateCertificateFromCsrResponse` value
    ///
    /// - Parameters:
    ///   - certificatePem: `String` The certificate data, in PEM format.
    public func withCertificatePem(certificatePem: String) {
        self.certificatePem = certificatePem
    }

    /// Assign the certificateOwnershipToken property a `CreateCertificateFromCsrResponse` value
    ///
    /// - Parameters:
    ///   - certificateOwnershipToken: `String` The token to prove ownership of the certificate during provisioning.
    public func withCertificateOwnershipToken(certificateOwnershipToken: String) {
        self.certificateOwnershipToken = certificateOwnershipToken
    }

}

/// Response payload to a CreateKeysAndCertificate request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class CreateKeysAndCertificateResponse: Codable {

    /// The certificate id.
    public var certificateId: String?

    /// The certificate data, in PEM format.
    public var certificatePem: String?

    /// The private key.
    public var privateKey: String?

    /// The token to prove ownership of the certificate during provisioning.
    public var certificateOwnershipToken: String?

    /// Initializes a new `CreateKeysAndCertificateResponse`
    /// - Parameters:
    public init() {
    }

    /// Assign the certificateId property a `CreateKeysAndCertificateResponse` value
    ///
    /// - Parameters:
    ///   - certificateId: `String` The certificate id.
    public func withCertificateId(certificateId: String) {
        self.certificateId = certificateId
    }

    /// Assign the certificatePem property a `CreateKeysAndCertificateResponse` value
    ///
    /// - Parameters:
    ///   - certificatePem: `String` The certificate data, in PEM format.
    public func withCertificatePem(certificatePem: String) {
        self.certificatePem = certificatePem
    }

    /// Assign the privateKey property a `CreateKeysAndCertificateResponse` value
    ///
    /// - Parameters:
    ///   - privateKey: `String` The private key.
    public func withPrivateKey(privateKey: String) {
        self.privateKey = privateKey
    }

    /// Assign the certificateOwnershipToken property a `CreateKeysAndCertificateResponse` value
    ///
    /// - Parameters:
    ///   - certificateOwnershipToken: `String` The token to prove ownership of the certificate during provisioning.
    public func withCertificateOwnershipToken(certificateOwnershipToken: String) {
        self.certificateOwnershipToken = certificateOwnershipToken
    }

}

/// Response payload to a RegisterThing request.
///
/// This class initializes with all optional properties set to 'nil'.
/// Use the provided builder with() functions to configure optional properties after initialization.
public class RegisterThingResponse: Codable {

    /// The device configuration defined in the template.
    public var deviceConfiguration: [String: String]?

    /// The name of the IoT thing created during provisioning.
    public var thingName: String?

    /// Initializes a new `RegisterThingResponse`
    /// - Parameters:
    public init() {
    }

    /// Assign the deviceConfiguration property a `RegisterThingResponse` value
    ///
    /// - Parameters:
    ///   - deviceConfiguration: `[String: String]` The device configuration defined in the template.
    public func withDeviceConfiguration(deviceConfiguration: [String: String]) {
        self.deviceConfiguration = deviceConfiguration
    }

    /// Assign the thingName property a `RegisterThingResponse` value
    ///
    /// - Parameters:
    ///   - thingName: `String` The name of the IoT thing created during provisioning.
    public func withThingName(thingName: String) {
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

