///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

@_exported import AwsCommonRuntimeKit
import Foundation

// Helper function to append parameters to username
private func appendToUsernameParameter(
  inputString: String, parameterValue: String, parameterPretext: String
) -> String {
  var returnString = inputString

  if returnString.contains("?") {
    returnString += "&"
  } else {
    returnString += "?"
  }

  if parameterValue.contains(parameterPretext) {
    return returnString + parameterValue
  } else {
    return returnString + parameterPretext + parameterValue
  }
}

/// A utility class used to build an MQTT5 Client configured for use with AWS IoT Core.
public class Mqtt5ClientBuilder {

  private var _endpoint: String?
  private var _port: UInt32 = 8883
  private var _onWebsocketTransform: OnWebSocketHandshakeIntercept?
  private var _clientId: String?
  private var _username: String?
  private var _authUsername: String?
  private var _authorizerName: String?
  private var _authorizerSiganture: String?
  private var _authTokenKeyName: String?
  private var _authTokenValue: String?
  private var _password: Data?
  private var _keepAliveInterval: TimeInterval = 1200
  private var _sessionExpiryInterval: TimeInterval?
  private var _extendedValidationAndFlowControlOptions: ExtendedValidationAndFlowControlOptions? =
    .awsIotCoreDefaults
  private var _onPublishReceived: OnPublishReceived?
  private var _onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect?
  private var _onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess?
  private var _onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure?
  private var _onLifecycleEventDisconnection: OnLifecycleEventDisconnection?
  private var _onLifecycleEventStopped: OnLifecycleEventStopped?
  private var _enableMetricsCollection: Bool = true
  private var _tlsOptions: TLSContextOptions?
  private var _caPath: String?
  private var _caFile: String?
  private var _caData: Data?
  private var _caDirPath: String?
  private var _certLabel: String?
  private var _keyLabel: String?
  private var _ackTimeout: TimeInterval?
  private var _connackTimeout: TimeInterval?
  private var _pingTimeout: TimeInterval?
  private var _minReconnectDelay: TimeInterval?
  private var _maxReconnectDelay: TimeInterval?
  private var _minConnectedTimeToResetReconnectDelay: TimeInterval?
  private var _retryJitterMode: ExponentialBackoffJitterMode?
  private var _clientOperationQueueBehaviorType: ClientOperationQueueBehaviorType?
  private var _clientSessionBehaviorType: ClientSessionBehaviorType?
  private var _topicAliasingOptions: TopicAliasingOptions?
  private var _httpProxyOptions: HTTPProxyOptions?
  private var _socketOptions: SocketOptions?
  private var _clientBootstrap: ClientBootstrap?
  private var _requestResponseInformation: Bool?
  private var _requestProblemInformation: Bool?
  private var _receiveMaximum: UInt16?
  private var _maximumPacketSize: UInt32?
  private var _willDelayInterval: TimeInterval?
  private var _will: PublishPacket?
  private var _userProperties: [UserProperty] = []

  // mtlsFromPath
  init(certPath: String, keyPath: String, endpoint: String) throws {
    _tlsOptions = try TLSContextOptions.makeMTLS(
      certificatePath: certPath, privateKeyPath: keyPath)
    _endpoint = endpoint
    _port = 8883
  }

  // mtlsFromData
  init(certData: Data, keyData: Data, endpoint: String) throws {
    _tlsOptions = try TLSContextOptions.makeMTLS(
      certificateData: certData, privateKeyData: keyData)
    _endpoint = endpoint
    _port = 8883
  }

  // mtlsFromPKCS12
  init(pkcs12Path: String, pkcs12Password: String, endpoint: String) throws {
    _tlsOptions = try TLSContextOptions.makeMTLS(
      pkcs12Path: pkcs12Path, password: pkcs12Password)
    _endpoint = endpoint
    _port = 8883
  }

  // websocketsWithDefaultAwsSigning
  init(
    endpoint: String, region: String, credentialsProvider: CredentialsProvider,
    bootstrap: ClientBootstrap? = nil
  ) throws {
    _tlsOptions = TLSContextOptions.makeDefault()
    _endpoint = endpoint
    _port = 443
    _clientBootstrap = bootstrap
    let signingConfig = SigningConfig(
      algorithm: SigningAlgorithmType.signingV4,
      signatureType: SignatureType.requestQueryParams,
      service: "iotdevicegateway",
      region: region,
      credentialsProvider: credentialsProvider,
      omitSessionToken: true)
    _onWebsocketTransform = { httpRequest, completCallback in
      Task {
        do {
          let returnedHttpRequest = try await Signer.signRequest(
            request: httpRequest, config: signingConfig)
          completCallback(returnedHttpRequest, 0)
        } catch {
          completCallback(httpRequest, -1)
        }
      }
    }
  }

  // Custom Auth
  init(
    endpoint: String,
    authAuthorizerName: String? = nil,
    authPassword: Data? = nil,
    authAuthorizerSignature: String? = nil,
    authTokenKeyName: String? = nil,
    authTokenValue: String? = nil,
    authUsername: String? = nil,
    useWebsocket: Bool = true
  ) throws {

    _endpoint = endpoint
    _port = 443

    _authorizerName = authAuthorizerName
    _password = authPassword
    _authorizerSiganture = authAuthorizerSignature
    _authTokenKeyName = authTokenKeyName
    _authTokenValue = authTokenValue
    _authUsername = authUsername

    _tlsOptions = TLSContextOptions.makeDefault()

    if useWebsocket {
      _onWebsocketTransform = { httpRequest, completeCallback in
        completeCallback(httpRequest, 0)
      }
    } else {
      _tlsOptions?.setAlpnList(["mqtt"])
    }
  }

  private func buildUsername() {
    var usernameString = ""

    if let username = _username {
      usernameString += username
    }

    if let authUsernameSet = _authUsername {
      usernameString = appendToUsernameParameter(
        inputString: usernameString,
        parameterValue: authUsernameSet,
        parameterPretext: "")

      usernameString += authUsernameSet
    }

    if let authorizerName = _authorizerName {
      usernameString = appendToUsernameParameter(
        inputString: usernameString,
        parameterValue: authorizerName,
        parameterPretext: "x-amz-customauthorizer-name=")
    }

    if let authAuthorizerSignature = _authorizerSiganture {
      var encodedSignature = authAuthorizerSignature
      if !encodedSignature.contains("%") {
        encodedSignature =
          encodedSignature.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
          ?? encodedSignature
      }
      usernameString = appendToUsernameParameter(
        inputString: usernameString,
        parameterValue: encodedSignature,
        parameterPretext: "x-amz-customauthorizer-signature=")
    }

    if let tokenKeyName = _authTokenKeyName, let tokenValue = _authTokenValue {
      usernameString = appendToUsernameParameter(
        inputString: usernameString,
        parameterValue: tokenValue,
        parameterPretext: "\(tokenKeyName)=")
    }

    if _enableMetricsCollection {
      usernameString = appendToUsernameParameter(
        inputString: usernameString,
        parameterValue: "SDK=Swift&Version=\(packageVersion)",
        parameterPretext: "")
    }

    if !usernameString.isEmpty {
      _username = usernameString
    } else {
      _username = nil
    }
  }

  /// Create an Mqtt5ClientBuilder configured to connect using certificate and private key file paths.
  ///
  /// - Parameters:
  ///   - certPath: Path to certificate file.
  ///   - keyPath: Path to private key file.
  ///   - endpoint: Host name of AWS IoT server.
  /// - Throws: `CommonRuntimeError.crtError`
  /// - Returns: An Mqtt5ClientBuilder configured to connect using Mutual TLS.
  public static func mtlsFromPath(
    certPath: String,
    keyPath: String,
    endpoint: String
  ) throws -> Mqtt5ClientBuilder {

    return try Mqtt5ClientBuilder(certPath: certPath, keyPath: keyPath, endpoint: endpoint)
  }

  /// Create an Mqtt5ClientBuilder configured to connect using certificate and private key data.
  ///
  /// - Parameters:
  ///   - certData: Certificate file bytes.
  ///   - keyData: Private key bytes.
  ///   - endpoint: Host name of AWS IoT server.
  /// - Throws: `CommonRuntimeError.crtError`
  /// - Returns: An Mqtt5ClientBuilder configured to connect using Mutual TLS.
  public static func mtlsFromData(
    certData: Data,
    keyData: Data,
    endpoint: String
  ) throws -> Mqtt5ClientBuilder {

    return try Mqtt5ClientBuilder(certData: certData, keyData: keyData, endpoint: endpoint)
  }

  /// Create an Mqtt5ClientBuilder configured to connect using a PKCS12 file.
  ///
  /// - Parameters:
  ///   - pkcs12Path: Path to the PKCS12 file to use
  ///   - pkcs12Password: The password for the PKCS12 file.
  ///   - endpoint: Host name of AWS IoT server.
  /// - Throws: `CommonRuntimeError.crtError`
  /// - Returns: An Mqtt5ClientBuilder configured to connect using Mutual TLS.
  public static func mtlsFromPKCS12(
    pkcs12Path: String,
    pkcs12Password: String,
    endpoint: String
  ) throws -> Mqtt5ClientBuilder {

    return try Mqtt5ClientBuilder(
      pkcs12Path: pkcs12Path, pkcs12Password: pkcs12Password, endpoint: endpoint)
  }

  /// Create a Mqtt5ClientBuilder that will use websockets and AWS Sigv4 signing to establish mutually-authenticated (mTLS) connections.
  ///
  /// - Parameters:
  ///   - endpoint: Host name of AWS IoT server.
  ///   - region: The AWS region the websocket connection is being established in. Must match the region embedded in the endpoint.
  ///   - credentialProvider: Sources the AWS Credentials used to sign the websocket connection handshake.
  /// - Throws: `CommonRuntimeError.crtError`
  /// - Returns: An Mqtt5ClientBuilder configured to connect using Mutual TLS.
  public static func websocketsWithDefaultAwsSigning(
    endpoint: String,
    region: String,
    credentialsProvider: CredentialsProvider,
    bootstrap: ClientBootstrap? = nil
  ) throws -> Mqtt5ClientBuilder {

    return try Mqtt5ClientBuilder(
      endpoint: endpoint,
      region: region,
      credentialsProvider: credentialsProvider,
      bootstrap: bootstrap)
  }

  /// Create an Mqtt5ClientBuilder that will use websockets and a custom authenticator controlled by the username and password values.
  ///
  /// - Parameters:
  ///   - authAuthorizerName: Name of the custom authorizer to use. It is strongly suggested to URL-encode this value; the SDK will not do so for you.
  ///   - authPassword: The password to use with the custom authorizer. Becomes the MQTT5 CONNECT packet's password property. AWS IoT Core will base64 encode this binary data before passing it to the authorizer's lambda function.
  ///   - authUsername: The username to use with the custom authorizer. Query-string elements of this property value will be unioned with the query-string elements implied by other properties in this object.
  ///                   For example, if you set `authUsername` to `MyUsername?someKey=someValue`, and use authorizerName to specify the authorizer, the final username would look like:
  ///                   `MyUsername?someKey=someValue&x-amz-customauthorizer-name=<your authorizer's name >`
  ///   - endpoint: Host name of AWS IoT server.
  /// - Throws: `CommonRuntimeError.crtError`
  /// - Returns: An Mqtt5ClientBuilder configured to connect using websockets with custom authorization.
  public static func websocketsWithCustomAuthorizer(
    authAuthorizerName: String,
    authPassword: Data,
    authUsername: String? = nil,
    endpoint: String
  ) throws -> Mqtt5ClientBuilder {

    return try Mqtt5ClientBuilder(
      endpoint: endpoint,
      authAuthorizerName: authAuthorizerName,
      authPassword: authPassword,
      authUsername: authUsername,
      useWebsocket: true)
  }

  /// Create an Mqtt5ClientBuilder that will use websockets and an unsigned custom authorizer.
  ///
  /// - Parameters:
  ///   - authAuthorizerName: Name of the custom authorizer to use. It is strongly suggested to URL-encode this value; the SDK will not do so for you.
  ///   - authPassword: The password to use with the custom authorizer. Becomes the MQTT5 CONNECT packet's password property.
  ///                   AWS IoT Core will base64 encode this binary data before passing it to the authorizer's lambda function
  ///   - authTokenKeyName: The key used to extract the custom authorizer token from MQTT username query-string properties. It is strongly suggested to URL-encode this value; the SDK will not do so for you.
  ///   - authTokenValue: An opaque token value. This value must be signed by the private key associated with the custom authorizer and the result placed in the tokenSignature property.
  ///   - authUsername: The username to use with the custom authorizer. Query-string elements of this property value will be unioned with the query-string elements implied by other properties in this object.
  ///                   For example, if you set `authUsername` to `MyUsername?someKey=someValue`, and use authorizerName to specify the authorizer, the final username would look like:
  ///                   `MyUsername?someKey=someValue&x-amz-customauthorizer-name=<your authorizer's name >`
  ///   - endpoint: Host name of AWS IoT server.
  /// - Throws: `CommonRuntimeError.crtError`
  /// - Returns: An Mqtt5ClientBuilder configured to connect using websockets with unsigned custom authorization.
  public static func websocketsWithUnsignedCustomAuthorizer(
    authAuthorizerName: String,
    authPassword: Data? = nil,
    authTokenKeyName: String,
    authTokenValue: String,
    authUsername: String? = nil,
    endpoint: String
  ) throws -> Mqtt5ClientBuilder {

    return try Mqtt5ClientBuilder(
      endpoint: endpoint,
      authAuthorizerName: authAuthorizerName,
      authPassword: authPassword,
      authTokenKeyName: authTokenKeyName,
      authTokenValue: authTokenValue,
      authUsername: authUsername,
      useWebsocket: true)
  }

  /// Create an Mqtt5ClientBuilder that will use websockets and a signed custom authorizer.
  ///
  /// - Parameters:
  ///   - authAuthorizerName: Name of the custom authorizer to use. It is strongly suggested to URL-encode this value; the SDK will not do so for you.
  ///   - authAuthorizerSignature: The digital signature of the token value in the tokenValue property. The signature must be based on the private key associated with the custom authorizer.
  ///                              The signature must be base64 encoded. It is strongly suggested to URL-encode this value; the SDK will not do so for you.
  ///   - authPassword: The password to use with the custom authorizer.
  ///   - authTokenKeyName: The key name for the authorization token.
  ///   - authTokenValue: The authorization token value.
  ///   - authUsername: The username to use with the custom authorizer.
  ///   - endpoint: Host name of AWS IoT server.
  /// - Throws: `CommonRuntimeError.crtError`
  /// - Returns: An Mqtt5ClientBuilder configured to connect using websockets with signed custom authorization.
  public static func websocketsWithSignedCustomAuthorizer(
    authAuthorizerName: String,
    authAuthorizerSignature: String,
    authPassword: Data? = nil,
    authTokenKeyName: String,
    authTokenValue: String,
    authUsername: String? = nil,
    endpoint: String
  ) throws -> Mqtt5ClientBuilder {

    return try Mqtt5ClientBuilder(
      endpoint: endpoint,
      authAuthorizerName: authAuthorizerName,
      authPassword: authPassword,
      authAuthorizerSignature: authAuthorizerSignature,
      authTokenKeyName: authTokenKeyName,
      authTokenValue: authTokenValue,
      authUsername: authUsername,
      useWebsocket: true)
  }

  /// Create an Mqtt5ClientBuilder that will use direct MQTT and an unsigned custom authorizer.
  ///
  /// - Parameters:
  ///   - authAuthorizerName: Name of the custom authorizer to use. It is strongly suggested to URL-encode this value; the SDK will not do so for you.
  ///   - authPassword: The password to use with the custom authorizer. Becomes the MQTT5 CONNECT packet's password property. AWS IoT Core will base64 encode this binary data before passing it to the authorizer's lambda function.
  ///   - authUsername: The username to use with the custom authorizer. Query-string elements of this property value will be unioned with the query-string elements implied by other properties in this object.
  ///                   For example, if you set `authUsername` to `MyUsername?someKey=someValue`, and use authorizerName to specify the authorizer, the final username would look like:
  ///                   `MyUsername?someKey=someValue&x-amz-customauthorizer-name=<your authorizer's name >`
  ///   - endpoint: Host name of AWS IoT server.
  /// - Throws: `CommonRuntimeError.crtError`
  /// - Returns: An Mqtt5ClientBuilder configured to connect using direct MQTT with unsigned custom authorization.
  public static func directWithUnsignedCustomAuthorizer(
    authAuthorizerName: String? = nil,
    authPassword: Data? = nil,
    authUsername: String? = nil,
    endpoint: String
  ) throws -> Mqtt5ClientBuilder {

    return try Mqtt5ClientBuilder(
      endpoint: endpoint,
      authAuthorizerName: authAuthorizerName,
      authPassword: authPassword,
      authUsername: authUsername,
      useWebsocket: false)
  }

  /// Create an Mqtt5ClientBuilder that will use direct MQTT and a signed custom authorizer.
  ///
  /// - Parameters:
  ///   - authAuthorizerName: Name of the custom authorizer to use. It is strongly suggested to URL-encode this value; the SDK will not do so for you.
  ///   - authAuthorizerSignature: The digital signature of the token value in the tokenValue property. The signature must be based on the private key associated with the custom authorizer.
  ///                              The signature must be base64 encoded. It is strongly suggested to URL-encode this value; the SDK will not do so for you.
  ///   - authPassword: The password to use with the custom authorizer. Becomes the MQTT5 CONNECT packet's password property. AWS IoT Core will base64 encode this binary data before passing it to the authorizer's lambda function.
  ///   - authTokenKeyName: The key name for the authorization token.
  ///   - authTokenValue: The authorization token value.
  ///   - authUsername: The username to use with the custom authorizer. Query-string elements of this property value will be unioned with the query-string elements implied by other properties in this object.
  ///                   For example, if you set `authUsername` to `MyUsername?someKey=someValue`, and use authorizerName to specify the authorizer, the final username would look like:
  ///                   `MyUsername?someKey=someValue&x-amz-customauthorizer-name=<your authorizer's name >`
  ///   - endpoint: Host name of AWS IoT server.
  /// - Throws: `CommonRuntimeError.crtError`
  /// - Returns: An Mqtt5ClientBuilder configured to connect using direct MQTT with signed custom authorization.
  public static func directWithSignedCustomAuthorizer(
    authAuthorizerName: String,
    authAuthorizerSignature: String,
    authPassword: Data? = nil,
    authTokenKeyName: String,
    authTokenValue: String,
    authUsername: String? = nil,
    endpoint: String
  ) throws -> Mqtt5ClientBuilder {

    return try Mqtt5ClientBuilder(
      endpoint: endpoint,
      authAuthorizerName: authAuthorizerName,
      authPassword: authPassword,
      authAuthorizerSignature: authAuthorizerSignature,
      authTokenKeyName: authTokenKeyName,
      authTokenValue: authTokenValue,
      authUsername: authUsername,
      useWebsocket: false)
  }

  /// Set callbacks for MQTT5 Client.
  ///
  /// - Parameters:
  ///   - onPublishReceived: Callback invoked for all publish packets received by client.
  ///   - onLifecycleEventAttemptingConnect: Callback invoked for Lifecycle Event Attempting Connect.
  ///   - onLifecycleEventConnectionSuccess: Callback invoked for Lifecycle Event Connection Success.
  ///   - onLifecycleEventConnectionFailure: Callback invoked for Lifecycle Event Connection Failure.
  ///   - onLifecycleEventDisconnection: Callback invoked for Lifecycle Event Disconnection.
  ///   - onLifecycleEventStopped: Callback invoked for Lifecycle Event Stopped.
  public func withCallbacks(
    onPublishReceived: OnPublishReceived? = nil,
    onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect? = nil,
    onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess? = nil,
    onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure? = nil,
    onLifecycleEventDisconnection: OnLifecycleEventDisconnection? = nil,
    onLifecycleEventStopped: OnLifecycleEventStopped? = nil
  ) {

    withOnPublishReceived(onPublishReceived)
    withOnLifecycleEventAttemptingConnect(onLifecycleEventAttemptingConnect)
    withOnLifecycleEventConnectionSuccess(onLifecycleEventConnectionSuccess)
    withOnLifecycleEventConnectionFailure(onLifecycleEventConnectionFailure)
    withOnLifecycleEventDisconnection(onLifecycleEventDisconnection)
    withOnLifecycleEventStopped(onLifecycleEventStopped)
  }

  /// Set callback invoked for all publish packets received by client.
  ///
  /// - Parameter onPublishReceived: Callback invoked for all publish packets received by client.
  public func withOnPublishReceived(_ onPublishReceived: OnPublishReceived?) {
    _onPublishReceived = onPublishReceived
  }

  /// Set callback invoked for Lifecycle Event Attempting Connect.
  ///
  /// - Parameter onLifecycleEventAttemptingConnect: Callback invoked for Lifecycle Event Attempting Connect.
  public func withOnLifecycleEventAttemptingConnect(
    _ onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect?
  ) {
    _onLifecycleEventAttemptingConnect = onLifecycleEventAttemptingConnect
  }

  /// Set callback invoked for Lifecycle Event Connection Success.
  ///
  /// - Parameter onLifecycleEventConnectionSuccess: Callback invoked for Lifecycle Event Connection Success.
  public func withOnLifecycleEventConnectionSuccess(
    _ onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess?
  ) {
    _onLifecycleEventConnectionSuccess = onLifecycleEventConnectionSuccess
  }

  /// Set callback invoked for Lifecycle Event Connection Failure.
  ///
  /// - Parameter onLifecycleEventConnectionFailure: Callback invoked for Lifecycle Event Connection Failure.
  public func withOnLifecycleEventConnectionFailure(
    _ onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure?
  ) {
    _onLifecycleEventConnectionFailure = onLifecycleEventConnectionFailure
  }

  /// Set callback invoked for Lifecycle Event Disconnection.
  ///
  /// - Parameter onLifecycleEventDisconnection: Callback invoked for Lifecycle Event Disconnection.
  public func withOnLifecycleEventDisconnection(
    _ onLifecycleEventDisconnection: OnLifecycleEventDisconnection?
  ) {
    _onLifecycleEventDisconnection = onLifecycleEventDisconnection
  }

  /// Set callback invoked for Lifecycle Event Stopped.
  ///
  /// - Parameter onLifecycleEventStopped: Callback invoked for Lifecycle Event Stopped.
  public func withOnLifecycleEventStopped(_ onLifecycleEventStopped: OnLifecycleEventStopped?) {
    _onLifecycleEventStopped = onLifecycleEventStopped
  }

  /// **port** (`int`): Override default server port.
  /// Default port is 443 if system supports ALPN or websockets are being used.
  /// Otherwise, default port is 8883.
  ///
  /// - Parameter port: (UInt32)
  public func withPort(_ port: UInt32) {
    _port = port
  }

  /// ID to place in CONNECT packet. Must be unique across all devices/clients.
  /// If an ID is already in use, the other client will be disconnected. If one is not provided,
  /// AWS IoT server will assign a unique ID for use and return it in the CONNACK packet.
  ///
  /// - Parameter clientId: (String)
  public func withClientId(_ clientId: String) {
    _clientId = clientId
  }

  /// Username to connect with.
  ///
  /// - Parameter username: (String)
  public func withUsername(_ username: String) {
    _username = username
  }

  /// Password to connect with.
  ///
  /// - Parameter password: (Data)
  public func withPassword(_ password: Data) {
    _password = password
  }

  /// The maximum time interval, in seconds, that is permitted to elapse between the point at which the
  /// client finishes transmitting one MQTT packet and the point it starts sending the next.
  /// The client will use PINGREQ packets to maintain this property. If the responding CONNACK contains
  /// a keep alive property value, then that is the negotiated keep alive value. Otherwise, the keep
  /// alive sent by the client is the negotiated value. keep_alive_interval_sec must be set to at least
  /// 1 second greater than ping_timeout_ms (default 30,000 ms) or it will fail validation.
  ///
  /// - Parameter keepAliveInterval: (TimeInterval)
  public func withKeepAliveInterval(_ keepAliveInterval: TimeInterval) {
    _keepAliveInterval = keepAliveInterval
  }

  /// A time interval, in seconds, that the client requests the server to persist this connection's MQTT
  /// session state for.  Has no meaning if the client has not been configured to rejoin sessions.
  /// Must be non-zero in order to successfully rejoin a session. If the responding CONNACK contains
  /// a session expiry property value, then that is the negotiated session expiry value.  Otherwise,
  /// the session expiry sent by the client is the negotiated value.
  ///
  /// - Parameter sessionExpiryInterval: (TimeInterval)
  public func withSessionExpiryInterval(_ sessionExpiryInterval: TimeInterval) {
    _sessionExpiryInterval = sessionExpiryInterval
  }

  /// The additional controls for client behavior with respect to operation validation and flow control; these
  /// checks go beyond the base MQTT5 spec to respect limits of specific MQTT brokers. If argument is omitted or null,
  /// then set to AWS_IOT_CORE_DEFAULTS.
  ///
  /// - Parameter flowControlOptions: (ExtendedValidationAndFlowControlOptions)
  public func withExtendedValidationAndFlowControlOptions(
    _ flowControlOptions: ExtendedValidationAndFlowControlOptions
  ) {
    _extendedValidationAndFlowControlOptions = flowControlOptions
  }

  /// Overrides the default system trust store.
  ///
  /// - Parameter caPath: Single file containing all trust CAs in PEM format
  public func withCaPath(_ caPath: String) {
    _caPath = caPath
  }

  /// Overrides the default system trust store.
  ///
  /// - Parameter caDirPath: Only used on Unix-style systems where all trust anchors are stored in a directory
  /// (e.g. /etc/ssl/certs).
  public func withCaDirPath(_ caDirPath: String) {
    _caDirPath = caDirPath
  }

  /// Overrides the default system trust store.
  ///
  /// - Parameter caData: Data containing all trust CAs, in PEM format
  public func withCaData(_ caData: Data) {
    _caData = caData
  }

  /// Provide specific human readable labels for the certificate and private key being stored in the
  /// Apple keychain. Only used with secitem.
  ///
  /// - Parameters:
  ///   - certLabel: Human readable label to use with certificate
  ///   - keyLabel: Human readable label to be used with private key
  public func withSecitemLabels(certLabel: String? = nil, keyLabel: String? = nil) {
    _certLabel = certLabel
    _keyLabel = keyLabel
  }

  /// Overrides the time interval to wait for an ack after sending a QoS 1+ PUBLISH, SUBSCRIBE, or UNSUBSCRIBE before
  /// failing the operation.  Defaults to no timeout.
  ///
  /// - Parameter ackTimeout:time interval to wait for an ack after sending a QoS 1+ PUBLISH, SUBSCRIBE,
  /// or UNSUBSCRIBE before failing the operation
  public func withAckTimeout(_ ackTimeout: TimeInterval) {
    _ackTimeout = ackTimeout
  }

  /// Overrides the time interval to wait after sending a CONNECT request for a CONNACK to arrive.  If one does not
  /// arrive, the connection will be shut down.
  ///
  /// - Parameter connackTimeout: time interval to wait after sending a CONNECT request for a CONNACK to arrive
  public func withConnackTimeout(_ connackTimeout: TimeInterval) {
    _connackTimeout = connackTimeout
  }

  /// Overrides the time interval to wait after sending a PINGREQ for a PINGRESP to arrive.  If one does not arrive,
  /// the client will close the current connection.
  ///
  /// - Parameter pingTimeout: time interval to wait after sending a PINGREQ for a PINGRESP to arrive
  public func withPingTimeout(_ pingTimeout: TimeInterval) {
    _pingTimeout = pingTimeout
  }

  /// Overrides the minimum amount of time to wait to reconnect after a disconnect.  Exponential backoff is performed
  /// with controllable jitter after each connection failure.
  ///
  /// - Parameter minReconnectDelay: minimum amount of time to wait to reconnect after a disconnect
  public func withMinReconnectDelay(_ minReconnectDelay: TimeInterval) {
    _minReconnectDelay = minReconnectDelay
  }

  /// Overrides the maximum amount of time to wait to reconnect after a disconnect.  Exponential backoff is performed
  /// with controllable jitter after each connection failure.
  ///
  /// - Parameter maxReconnectDelay: maximum amount of time to wait to reconnect after a disconnect
  public func withMaxReconnectDelay(_ maxReconnectDelay: TimeInterval) {
    _maxReconnectDelay = maxReconnectDelay
  }

  /// Overrides the amount of time that must elapse with an established connection before the reconnect delay is
  /// reset to the minimum.  This helps alleviate bandwidth-waste in fast reconnect cycles due to permission
  /// failures on operations.
  ///
  /// - Parameter minConnectedTimeToResetReconnectDelay: the amount of time that must elapse with an established
  /// connection before the reconnect delay is reset to the minimum
  public func withMinConnectedTimeToResetReconnectDelay(
    _ minConnectedTimeToResetReconnectDelay: TimeInterval
  ) {
    _minConnectedTimeToResetReconnectDelay = minConnectedTimeToResetReconnectDelay
  }

  /// Overrides how the reconnect delay is modified in order to smooth out the distribution of reconnection attempt
  /// timepoints for a large set of reconnecting clients.
  ///
  /// - Parameter retryJitterMode: controls how the reconnect delay is modified in order to smooth out the distribution of
  /// reconnection attempt timepoints for a large set of reconnecting clients.
  public func withRetryJitterMode(_ retryJitterMode: ExponentialBackoffJitterMode) {
    _retryJitterMode = retryJitterMode
  }

  /// Overrides how disconnects affect the queued and in-progress operations tracked by the client.  Also controls
  /// how new operations are handled while the client is not connected.  In particular, if the client is not connected,
  /// then any operation that would be failed on disconnect (according to these rules) will also be rejected.
  ///
  /// - Parameter clientOperationQueueBehaviorType: how disconnects affect the queued and in-progress operations tracked by the client
  public func withClientOperationQueueBehaviorType(
    _ clientOperationQueueBehaviorType: ClientOperationQueueBehaviorType
  ) {
    _clientOperationQueueBehaviorType = clientOperationQueueBehaviorType
  }

  /// Overrides how the MQTT5 client should behave with respect to MQTT sessions.
  ///
  /// - Parameter clientSessionBehaviorType: how the MQTT5 client should behave with respect to MQTT sessions
  public func withClientSessionBehaviorType(
    _ clientSessionBehaviorType: ClientSessionBehaviorType
  ) {
    _clientSessionBehaviorType = clientSessionBehaviorType
  }

  /// Overrides how the MQTT5 client should behave with respect to topic aliasing.
  ///
  /// - Parameter topicAliasingOptions: how the MQTT5 client should behave with respect to topic aliasing
  public func withTopicAliasingOptions(_ topicAliasingOptions: TopicAliasingOptions) {
    _topicAliasingOptions = topicAliasingOptions
  }

  /// Overrides (tunneling) HTTP proxy usage when establishing MQTT connections.
  ///
  /// - Parameter httpProxyOptions: HTTP proxy options to use when establishing MQTT connections
  public func withHttyProxyOptions(_ httpProxyOptions: HTTPProxyOptions) {
    _httpProxyOptions = httpProxyOptions
  }

  /// Overrides the socket properties of the underlying MQTT connections made by the client.  Leave undefined to use
  /// defaults (no TCP keep alive, 10 second socket timeout).
  ///
  /// - Parameter socketOptions: socket properties of the underlying MQTT connections made by the client
  public func withSocketOptions(_ socketOptions: SocketOptions) {
    _socketOptions = socketOptions
  }

  /// Set the client bootstrap used to establish connection.
  ///
  /// - Parameter clientBootstrap: client bootstrap used to establish connection.
  public func withBootstrap(_ clientBootstrap: ClientBootstrap) {
    _clientBootstrap = clientBootstrap
  }

  /// If true, requests that the server send response information in the subsequent CONNACK.  This response
  /// information may be used to set up request-response implementations over MQTT, but doing so is outside
  /// the scope of the MQTT5 spec and client.
  ///
  /// - Parameter requestResponseInformation: requests that the server send response information in the subsequent CONNACK
  public func withRequestResponseInformation(_ requestResponseInformation: Bool) {
    _requestResponseInformation = requestResponseInformation
  }

  /// If true, requests that the server send additional diagnostic information (via response string or user properties)
  /// in DISCONNECT or CONNACK packets from the server.
  ///
  /// - Parameter requestProblemInformation: requests that the server send additional diagnostic information in
  /// DISCONNECT or CONNACK packets from the server
  public func withRequestProblemInformation(_ requestProblemInformation: Bool) {
    _requestProblemInformation = requestProblemInformation
  }

  /// Notifies the server of the maximum number of in-flight QoS 1 and 2 messages the
  /// client is willing to handle.  If omitted or null, then no limit is requested.
  ///
  /// - Parameter receiveMaximum: maximum number of in-flight QoS 1 and 2 messages the
  /// client is willing to handle
  public func withReceiveMaximum(_ receiveMaximum: UInt16) {
    _receiveMaximum = receiveMaximum
  }

  /// Notifies the server of the maximum packet size the client is willing to handle.
  /// If omitted or null, then no limit beyond the natural limits of MQTT packet size is requested.
  ///
  /// - Parameter maximumPacketSize: maximum packet size the client is willing to handle
  public func withMaximumPacketSize(_ maximumPacketSize: UInt32) {
    _maximumPacketSize = maximumPacketSize
  }

  /// A time interval, in seconds, that the server should wait (for a session reconnection) before sending
  /// the will message associated with the connection's session.  If omitted, the server will send the will
  /// when the associated session is destroyed.  If the session is destroyed before a will delay interval has
  /// elapsed, then the will must be sent at the time of session destruction.
  ///
  /// - Parameter willDelayInterval: time interval that the server should wait (for a session reconnection)
  /// before sending the will message associated with the connection's session
  public func withWillDelayInterval(_ willDelayInterval: TimeInterval) {
    _willDelayInterval = willDelayInterval
  }

  /// The definition of a message to be published when the connection's session is destroyed by the server or
  /// when the will delay interval has elapsed, whichever comes first. If omitted, then nothing will be sent.
  ///
  /// - Parameter will: the definition of a message to be published when the connection's session is destroyed
  /// by the server or when the will delay interval has elapsed
  public func withWill(_ will: PublishPacket) {
    _will = will
  }

  /// Array of MQTT5 user properties included with the connect packet.
  ///
  /// - Parameter userProperties: user properties to include with the connect packet
  public func withUserProperties(_ userProperties: [UserProperty]) {
    _userProperties = userProperties
  }

  /// Builds an `Mqtt5Client` using the configuration set within.
  ///
  /// - Throws: CommonRuntimeError.crtError
  /// - Returns: `Mqtt5Client`
  public func build() throws -> Mqtt5Client {
    guard let unwrappedEndpoint = _endpoint else {
      throw AwsIotDeviceSdkError.missingParameter(
        parameterName: "Mqtt5ClientBuilder requires endpoint to build client.")
    }

    // Builds _username with one set by user, custom auth, and metrics
    buildUsername()

    _extendedValidationAndFlowControlOptions = .awsIotCoreDefaults

    // Configure connection options
    let connectOptions = MqttConnectOptions(
      keepAliveInterval: _keepAliveInterval,
      clientId: _clientId,
      username: _username,
      password: _password,
      sessionExpiryInterval: _sessionExpiryInterval,
      requestResponseInformation: _requestResponseInformation,
      requestProblemInformation: _requestProblemInformation,
      receiveMaximum: _receiveMaximum,
      maximumPacketSize: _maximumPacketSize,
      willDelayInterval: _willDelayInterval,
      will: _will,
      userProperties: _userProperties
    )

    var _tlsCtx: TLSContext?
    do {
      if let tlsOptions = _tlsOptions {
        // Handle CA override
        if let caPath = _caPath {
          try tlsOptions.overrideDefaultTrustStoreWithPath(caPath: caPath)
        } else if let caFile = _caFile {
          try tlsOptions.overrideDefaultTrustStoreWithFile(caFile: caFile)
        } else if let caData = _caData {
          try tlsOptions.overrideDefaultTrustStoreWithData(caData: caData)
        }

        // Apply labels if available
        if _certLabel != nil || _keyLabel != nil {
          try tlsOptions.setSecitemLabels(certLabel: _certLabel, keyLabel: _keyLabel)
        }

        _tlsCtx = try TLSContext(options: tlsOptions, mode: .client)
      }
    } catch {
      throw CommonRunTimeError.crtError(CRTError.makeFromLastError())
    }

    // Configure client options
    let clientOptions = MqttClientOptions(
      hostName: unwrappedEndpoint,
      port: _port,
      bootstrap: _clientBootstrap,
      socketOptions: _socketOptions,
      tlsCtx: _tlsCtx,
      onWebsocketTransform: _onWebsocketTransform,
      httpProxyOptions: _httpProxyOptions,
      connectOptions: connectOptions,
      sessionBehavior: _clientSessionBehaviorType,
      extendedValidationAndFlowControlOptions: _extendedValidationAndFlowControlOptions,
      offlineQueueBehavior: _clientOperationQueueBehaviorType,
      retryJitterMode: _retryJitterMode,
      minReconnectDelay: _minReconnectDelay,
      maxReconnectDelay: _maxReconnectDelay,
      minConnectedTimeToResetReconnectDelay: _minConnectedTimeToResetReconnectDelay,
      pingTimeout: _pingTimeout,
      connackTimeout: _connackTimeout,
      ackTimeout: _ackTimeout,
      topicAliasingOptions: _topicAliasingOptions,
      onPublishReceivedFn: _onPublishReceived,
      onLifecycleEventStoppedFn: _onLifecycleEventStopped,
      onLifecycleEventAttemptingConnectFn: _onLifecycleEventAttemptingConnect,
      onLifecycleEventConnectionSuccessFn: _onLifecycleEventConnectionSuccess,
      onLifecycleEventConnectionFailureFn: _onLifecycleEventConnectionFailure,
      onLifecycleEventDisconnectionFn: _onLifecycleEventDisconnection)

    // Return the configured Mqtt5Client
    return try Mqtt5Client(clientOptions: clientOptions)
  }
}
