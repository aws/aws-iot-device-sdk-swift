///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import Foundation
@_exported import AwsCommonRuntimeKit

/// Helper function that generates string used for AWS metrics.
fileprivate func getMetricsStr(currentUsername: String = "") -> String {
    // Check if the username being used already has a query
    var usernameHasQuery = false
    if currentUsername.contains("?") {
        usernameHasQuery = true
    }

    let metricsStr = "SDK=Swift&Version=\(packageVersion)"

    // Based on whether username already had a query, we are adding to the query
    // or beginning one.
    if usernameHasQuery {
        return "&" + metricsStr
    } else {
        return "?" + metricsStr
    }
}

// Helper function to append parameters to username
fileprivate func appendToUsernameParameter(inputString: String, parameterValue: String, parameterPretext: String) -> String {
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

///A utility class used to build an MQTT5 Client configured for use with AWS IoT Core.
public class Mqtt5ClientBuilder {

    private var _endpoint: String? = nil
    private var _port: UInt32 = 8883
    private var _onWebsocketTransform: OnWebSocketHandshakeIntercept? = nil
    private var _clientId: String? = nil
    private var _username: String? = nil
    private var _password: Data? = nil
    private var _keepAliveInterval: TimeInterval = 1200
    private var _sessionExpiryInterval: TimeInterval? = nil
    private var _extendedValidationAndFlowControlOptions: ExtendedValidationAndFlowControlOptions? = .awsIotCoreDefaults
    private var _onPublishReceived: OnPublishReceived? = nil
    private var _onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect? = nil
    private var _onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess? = nil
    private var _onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure? = nil
    private var _onLifecycleEventDisconnection: OnLifecycleEventDisconnection? = nil
    private var _onLifecycleEventStopped: OnLifecycleEventStopped? = nil
    private var _enableMetricsCollection: Bool = true
    private var _tlsOptions: TLSContextOptions? = nil
    private var _caFilePath: String? = nil
    private var _caData: Data? = nil
    private var _caDirPath: String? = nil
    private var _certLabel: String? = nil
    private var _keyLabel: String? = nil
    private var _ackTimeout: TimeInterval? = nil
    private var _connackTimeout: TimeInterval? = nil
    private var _pingTimeout: TimeInterval? = nil
    private var _minReconnectDelay: TimeInterval? = nil
    private var _maxReconnectDelay: TimeInterval? = nil
    private var _minConnectedTimeToResetReconnectDelay: TimeInterval? = nil
    private var _retryJitterMode: ExponentialBackoffJitterMode? = nil
    private var _clientOperationQueueBehaviorType: ClientOperationQueueBehaviorType? = nil
    private var _clientSessionBehaviorType: ClientSessionBehaviorType? = nil
    private var _topicAliasingOptions: TopicAliasingOptions? = nil
    private var _httpProxyOptions: HTTPProxyOptions? = nil
    private var _socketOptions: SocketOptions? = nil
    private var _clientBootstrap: ClientBootstrap? = nil
    private var _requestResponseInformation: Bool? = nil
    private var _requestProblemInformation: Bool? = nil
    private var _receiveMaximum: UInt16? = nil
    private var _maximumPacketSize: UInt32? = nil
    private var _willDelayInterval: TimeInterval? = nil
    private var _will: PublishPacket? = nil
    private var _userProperties: [UserProperty]? = nil 

    // mtlsFromPath
    init (certPath: String, keyPath: String, endpoint: String) throws {
        _tlsOptions = try TLSContextOptions.makeMTLS(certificatePath: certPath, privateKeyPath: keyPath)
        _endpoint = endpoint
        _port = 8883
    }

    // mtlsFromData
    init (certData: Data, keyData: Data, endpoint: String) throws {
        _tlsOptions = try TLSContextOptions.makeMTLS(certificateData: certData, privateKeyData: keyData)
        _endpoint = endpoint
        _port = 8883
    }

    // mtlsFromPKCS12
    init (pkcs12Path: String, pkcs12Password: String, endpoint: String) throws {
        _tlsOptions = try TLSContextOptions.makeMTLS(pkcs12Path: pkcs12Path, password: pkcs12Password)
        _endpoint = endpoint
        _port = 8883
    }

    // websocketsWithDefaultAwsSigning
    init (endpoint: String, region: String, credentialsProvider: CredentialsProvider, bootstrap: ClientBootstrap? = nil) throws {
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
                do
                {
                    let returnedHttpRequest = try await Signer.signRequest(request: httpRequest, config:signingConfig)
                    completCallback(returnedHttpRequest, 0)// DEBUG WIP need to return AWS_OP_SUCCESS)
                }
                catch
                {
                    completCallback(httpRequest, -1)// DEBUG WIP need to return Int32(AWS_ERROR_UNSUPPORTED_OPERATION.rawValue))
                }
            }
    }

    // Custom Auth
    init (endpoint: String,
          authAuthorizerName: String? = nil,
          authPassword: Data? = nil,
          authAuthorizerSignature: String? = nil,
          authTokenKeyName: String? = nil,
          authTokenValue: String? = nil,
          authUsername: String? = nil,
          useWebsocket: Bool = true) throws {
        
        _endpoint = endpoint
        _port = 443

        var usernameString = ""
        if let authUsernameSet = authUsername {
            usernameString += authUsernameSet
        } else if let existingUsername = _username { 
            usernameString += existingUsername
        }

        if let authorizerName = authAuthorizerName {
            usernameString = appendToUsernameParameter(inputString: usernameString, 
                                                        parameterValue: authorizerName, 
                                                        parameterPretext: "x-amz-customauthorizer-name=")
        }

        if let authAuthorizerSignature = authAuthorizerSignature {
            var encodedSignature = authAuthorizerSignature
            if !encodedSignature.contains("%") {
                encodedSignature = encodedSignature.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? encodedSignature
            }
            usernameString = appendToUsernameParameter(inputString: usernameString, 
                                                       parameterValue: encodedSignature, 
                                                       parameterPretext: "x-amz-customauthorizer-signature=")
        }

        if let tokenKeyName = authTokenKeyName, let tokenValue = authTokenValue {
            usernameString = appendToUsernameParameter(inputString: usernameString, 
                                                       parameterValue: tokenValue, 
                                                       parameterPretext: "\(tokenKeyName)=")
        }

        _username = usernameString
        _password = authPassword

        _tlsOptions = TLSContextOptions.makeDefault()

        if (useWebsocket) {
            _onWebsocketTransform = { httpRequest, completeCallback in
                completeCallback(httpRequest, 0)
            }
        } else {
            _tlsOptions?.setAlpnList(["mqtt"])
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
        endpoint: String) throws -> Mqtt5ClientBuilder {

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
        endpoint: String) throws -> Mqtt5ClientBuilder  {

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
        endpoint: String) throws -> Mqtt5ClientBuilder {
        
        return try Mqtt5ClientBuilder(pkcs12Path: pkcs12Path, pkcs12Password: pkcs12Password, endpoint: endpoint)
    }

    /// Create an Mqtt5ClientBuilder configured to connect to AWS IoT over websockets using credentials from the credentialsProvider 
    /// for the websocket handshake.
    /// 
    /// - Parameters:
    ///   - endpoint: Host name of AWS IoT server.
    ///   - region: AWS region to use when signing.
    ///   - credentialsProvider: Source of AWS credentials to use when signing. 
    ///   - bootstrap: Bootstrap to use with MQTT5 Client. Sharing a bootstrap with the one used for the credentialsProvider
    ///     is recommended.
    /// - Throws: `CommonRuntimeError.crtError`
    /// - Returns: An Mqtt5ClientBuilder configured to connect using websockets and the credentials provider.
    public static func websocketsWithDefaultAwsSigning(endpoint: String,
                                                       region: String, 
                                                       credentialsProvider: CredentialsProvider,
                                                       bootstrap: ClientBootstrap? = nil) throws -> Mqtt5ClientBuilder {

        return try Mqtt5ClientBuilder(endpoint: endpoint,
                                      region: region, 
                                      credentialsProvider: credentialsProvider,
                                      bootstrap: bootstrap)
    }    

    /// Create an Mqtt5ClientBuilder configured to connect to AWS IoT over websockets using a custom authorizer.
    ///
    /// - Parameters:
    ///   - endpoint: Host name of AWS IoT server.
    ///   - authAuthorizerName: Name of the custom authorizer to use. It is strongly suggested to URL-encode this value; the SDK 
    ///     will not do so for you.
    ///   - authPassword: The password to use with the custom authorizer.  Becomes the MQTT5 CONNECT packet's password property. 
    ///     AWS IoT Core will base64 encode this binary data before passing it to the authorizer's lambda function.
    ///   - authUsername: The username to use with the custom authorizer. If provided, the username given will be passed when 
    ///     connecting to the custom authorizer. Custom authentication parameters will be appended as appropriate to any supplied 
    ///     username value.
    /// - Throws: `CommonRuntimeError.crtError`
    /// - Returns: An Mqtt5ClientBuilder configured to connect using websockets with a custom authorizer.
    public static func websocketsWithCustomAuthorizer(endpoint: String,
                                                      authAuthorizerName: String,
                                                      authPassword: Data,
                                                      authUsername: String? = nil) throws -> Mqtt5ClientBuilder {
        
        return try Mqtt5ClientBuilder(endpoint: endpoint,
                                      authAuthorizerName: authAuthorizerName,
                                      authPassword: authPassword,
                                      authUsername: authUsername,
                                      useWebsocket: true)
    }

    /// Create an Mqtt5ClientBuilder configured to connect to AWS IoT over websockets using a custom authorizer with an unsigned token.
    ///
    /// - Parameters:
    ///   - endpoint: Host name of AWS IoT server.
    ///   - authAuthorizerName: Name of the custom authorizer to use. It is strongly suggested to URL-encode this value; the SDK 
    ///     will not do so for you.
    ///   - authPassword: The password to use with the custom authorizer.  Becomes the MQTT5 CONNECT packet's password property. 
    ///     AWS IoT Core will base64 encode this binary data before passing it to the authorizer's lambda function.
    ///   - authTokenKeyName: Key used to extract the custom authorizer token from MQTT username query-string properties. It is 
    ///     strongly suggested to URL-encode this value; the SDK will not do so for you.
    ///   - authTokenValue: An opaque token value. This value must be signed by the private key associated with the custom 
    ///     authorizer.
    ///   - authUsername: The username to use with the custom authorizer. If provided, the username given will be passed when 
    ///     connecting to the custom authorizer. Custom authentication parameters will be appended as appropriate to any supplied 
    ///     username value.
    /// - Throws: `CommonRuntimeError.crtError`
    /// - Returns: An Mqtt5ClientBuilder configured to connect using websockets with a custom authorizer and unsigned token.
    public static func websocketsWithUnsignedCustomAuthorizer(endpoint: String,
                                                              authAuthorizerName: String,
                                                              authPassword: Data? = nil,
                                                              authTokenKeyName: String,
                                                              authTokenValue: String,
                                                              authUsername: String? = nil) throws -> Mqtt5ClientBuilder {
        
        return try Mqtt5ClientBuilder(endpoint: endpoint,
                                      authAuthorizerName: authAuthorizerName,
                                      authPassword: authPassword,
                                      authTokenKeyName: authTokenKeyName,
                                      authTokenValue:authTokenValue,
                                      authUsername: authUsername,
                                      useWebsocket: true)
    }

    /// Create an Mqtt5ClientBuilder configured to connect to AWS IoT over websockets using a custom authorizer with a signed token.
    ///
    /// - Parameters:
    ///   - endpoint: Host name of AWS IoT server.
    ///   - authAuthorizerName: Name of the custom authorizer to use. It is strongly suggested to URL-encode this value; the SDK 
    ///     will not do so for you.
    ///   - authPassword: The password to use with the custom authorizer.  Becomes the MQTT5 CONNECT packet's password property. 
    ///     AWS IoT Core will base64 encode this binary data before passing it to the authorizer's lambda function.
    ///   - authAuthorizerSignature: The digital signature of the token value.  The signature must be based on the private key 
    ///     associated with the custom authorizer.  The signature must be base64 encoded.
    ///   - authTokenKeyName: Key used to extract the custom authorizer token from MQTT username query-string properties. It is 
    ///     strongly suggested to URL-encode this value; the SDK will not do so for you.
    ///   - authTokenValue: An opaque token value. This value must be signed by the private key associated with the custom authorizer.
    ///   - authUsername: The username to use with the custom authorizer. If provided, the username given will be passed when 
    ///     connecting to the custom authorizer. Custom authentication parameters will be appended as appropriate to any supplied 
    ///     username value.
    /// - Throws: `CommonRuntimeError.crtError`
    /// - Returns: An Mqtt5ClientBuilder configured to connect using websockets with a custom authorizer with a signed token.
    public static func websocketsWithSignedCustomAuthorizer(endpoint: String,
                                                            authAuthorizerName: String,
                                                            authPassword: Data? = nil,
                                                            authAuthorizerSignature: String,
                                                            authTokenKeyName: String,
                                                            authTokenValue: String,
                                                            authUsername: String) throws -> Mqtt5ClientBuilder {
        
        return try Mqtt5ClientBuilder(endpoint: endpoint,
                                      authAuthorizerName: authAuthorizerName,
                                      authPassword: authPassword,
                                      authAuthorizerSignature: authAuthorizerSignature,
                                      authTokenKeyName: authTokenKeyName,
                                      authTokenValue:authTokenValue,
                                      authUsername: authUsername,
                                      useWebsocket: true)
    }

    /// Create an Mqtt5ClientBuilder configured to connect to AWS IoT using a custom authorizer with an unsigned token.
    ///
    /// - Parameters:
    ///   - endpoint: Host name of AWS IoT server.
    ///   - authAuthorizerName: Name of the custom authorizer to use. It is strongly suggested to URL-encode this value; the SDK 
    ///     will not do so for you.
    ///   - authPassword: The password to use with the custom authorizer.  Becomes the MQTT5 CONNECT packet's password property. 
    ///     AWS IoT Core will base64 encode this binary data before passing it to the authorizer's lambda function.
    ///   - authUsername: The username to use with the custom authorizer. If provided, the username given will be passed when 
    ///     connecting to the custom authorizer. Custom authentication parameters will be appended as appropriate to any supplied 
    ///     username value.
    /// - Throws: `CommonRuntimeError.crtError`
    /// - Returns: An Mqtt5ClientBuilder configured to connect to AWS IoT using a custom authorizer with an unsigned token.
    public static func directWithUnsignedCustomAuthorizer(endpoint: String,
                                                          authAuthorizerName: String? = nil,
                                                          authPassword: Data? = nil,
                                                          authUsername: String? = nil) throws -> Mqtt5ClientBuilder {
    
        return try Mqtt5ClientBuilder(endpoint: endpoint,
                                      authAuthorizerName: authAuthorizerName,
                                      authPassword: authPassword,
                                      authUsername: authUsername,
                                      useWebsocket: false)
    }

    /// Create an Mqtt5ClientBuilder configured to connect to AWS IoT using a custom authorizer with a signed token.
    ///
    /// - Parameters:
    ///   - endpoint: Host name of AWS IoT server.
    ///   - authAuthorizerName: Name of the custom authorizer to use. It is strongly suggested to URL-encode this value; the SDK 
    ///     will not do so for you.
    ///   - authAuthorizerSignature: The digital signature of the token value.  The signature must be based on the private key 
    ///     associated with the custom authorizer.  The signature must be base64 encoded.
    ///   - authTokenKeyName: Key used to extract the custom authorizer token from MQTT username query-string properties. It is 
    ///     strongly suggested to URL-encode this value; the SDK will not do so for you.
    ///   - authTokenValue: An opaque token value. This value must be signed by the private key associated with the custom authorizer.
    ///   - authUsername: The username to use with the custom authorizer. If provided, the username given will be passed when 
    ///     connecting to the custom authorizer. Custom authentication parameters will be appended as appropriate to any supplied 
    ///     username value.
    ///   - authPassword: The password to use with the custom authorizer.  Becomes the MQTT5 CONNECT packet's password property. 
    ///     AWS IoT Core will base64 encode this binary data before passing it to the authorizer's lambda function.
    /// - Throws: `CommonRuntimeError.crtError`
    /// - Returns: An Mqtt5ClientBuilder configured to connect to AWS IoT using a custom authorizer with a signed token.
    public static func directWithSignedCustomAuthorizer(endpoint: String,
                                                        authAuthorizerName: String,
                                                        authAuthorizerSignature: String,
                                                        authTokenKeyName: String,
                                                        authTokenValue: String,
                                                        authUsername: String? = nil,
                                                        authPassword: Data? = nil) throws -> Mqtt5ClientBuilder {
        
        return try Mqtt5ClientBuilder(endpoint: endpoint,
                                      authAuthorizerName: authAuthorizerName,
                                      authPassword: authPassword,
                                      authAuthorizerSignature: authAuthorizerSignature,
                                      authTokenKeyName: authTokenKeyName,
                                      authTokenValue:authTokenValue,
                                      authUsername: authUsername,
                                      useWebsocket: false)
    }

    /// Setup all callbacks for the MQTT5 Client.
    ///
    /// - Parameters:
    ///   - onPublishReceived: Callback invoked for all publish packets received by client.
    ///   - onLifecycleEventConnectionAttempt : Callback invoked for Lifecycle Event Attempting Connect.
    ///   - onLifecycleEventConnectionSuccess: Callback invoked for Lifecycle Event Connection Success.
    ///   - onLifecycleEventConnectionFailure: Callback invoked for Lifecycle Event Connection Failure.
    ///   - onLifecycleEventDisconnection: Callback invoked for Lifecycle Event Disconnection.
    ///   - onLifecycleEventStopped: Callback invoked for Lifecycle Event Stopped.
    public func withCallbacks(onPublishReceived: OnPublishReceived? = nil,
                              onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect? = nil,
                              onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess? = nil,
                              onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure? = nil,
                              onLifecycleEventDisconnection: OnLifecycleEventDisconnection? = nil,
                              onLifecycleEventStopped: OnLifecycleEventStopped? = nil) {
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
    public func withOnLifecycleEventAttemptingConnect(_ onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect?) {
        _onLifecycleEventAttemptingConnect = onLifecycleEventAttemptingConnect
    }

    /// Set callback invoked for Lifecycle Event Connection Success.
    ///
    /// - Parameter onLifecycleEventConnectionSuccess: Callback invoked for Lifecycle Event Connection Success.
    public func withOnLifecycleEventConnectionSuccess(_ onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess?) {
        _onLifecycleEventConnectionSuccess = onLifecycleEventConnectionSuccess
    }

    /// Set callback invoked for Lifecycle Event Connection Failure.
    ///
    /// - Parameter onLifecycleEventConnectionFailure: Callback invoked for Lifecycle Event Connection Failure.
    public func withOnLifecycleEventConnectionFailure(_ onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure?) {
        _onLifecycleEventConnectionFailure = onLifecycleEventConnectionFailure
    }

    /// Set callback invoked for Lifecycle Event Disconnection.
    ///
    /// - Parameter onLifecycleEventDisconnection: Callback invoked for Lifecycle Event Disconnection.
    public func withOnLifecycleEventDisconnection(_ onLifecycleEventDisconnection: OnLifecycleEventDisconnection?) {
        _onLifecycleEventDisconnection = onLifecycleEventDisconnection
    }

    /// Set callback invoked for Lifecycle Event Stopped.
    ///
    /// - Parameter onLifecycleEventStopped: Callback invoked for Lifecycle Event Stopped.
    public func withOnLifecycleEventStopped(_ onLifecycleEventStopped: OnLifecycleEventStopped?) {
        _onLifecycleEventStopped = onLifecycleEventStopped
    }

    /// Override default server port. Default port is 443 if system supports ALPN or websockets are being used. Otherwise, 
    /// default port is 8883.
    ///
    /// - Parameter port: The IoT endpoint port to connect to. Usually 8883 for MQTT, or 443 for websockets
    public func withPort(_ port: UInt32) {
        _port = port
    }

    /// Set Client Id to be used with MQTT5 client. Used to restore session state between connections. If left empty, the 
    /// broker will auto-assign a unique client id. When reconnecting, the mqtt5 client will always use the auto-assigned 
    /// client id.
    ///
    /// - Parameter clientId: A unique string identifying the client to the server.  
    public func withClientId(_ clientId: String) {
        _clientId = clientId
    }

    /// Set username to connect with. Overrides username set using any form of Custom Auth.
    ///
    /// - Parameter username: A string value that the server may use for client authentication and authorization.
    public func withUsername(_ username: String) {
        _username = username
    }

    /// Set password to connect with. Overrides password set using any form of Custom Auth.
    ///
    /// - Parameter password: Opaque binary data that the server may use for client authentication and authorization.
    public func withPassword(_ password: Data) {
        _password = password
    }
    
    /// The maximum time interval, in seconds, that is permitted to elapse between the point at which the 
    /// client finishes transmitting one MQTT packet and the point it starts sending the next.
    /// The client will use PINGREQ packets to maintain this property. 
    /// 
    /// If the responding CONNACK contains a keep alive property value, then that is the negotiated keep alive value. 
    /// Otherwise, the keep alive sent by the client is the negotiated value. keep_alive_interval_sec must be set to at 
    /// least 1 second greater than ping_timeout_ms (default 30 seconds) or it will fail validation.
    /// 
    /// See [MQTT5 Keep Alive](https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901045)
    ///
    /// - Parameter keepAliveInterval: Time in seconds that is permitted to elapse between the point at which the
    ///     client finishes transmitting one MQTT packet and the point it starts sending the next.
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
    /// - Parameter flowControlOptions: additional controls for client behavior with respect to operation validation and 
    ///   flow control.
    public func withExtendedValidationAndFlowControlOptions(_ flowControlOptions: ExtendedValidationAndFlowControlOptions) {
        _extendedValidationAndFlowControlOptions = flowControlOptions
    }

    /// Overrides the default system trust store.
    /// 
    /// - Parameter caPath: Single file containing all trust CAs, in PEM format
    public func withCaPath(_ caPath: String) {
        _caFilePath = caPath
    }
    
    
    /// Overrides the default system trust store. Only used on Unix-style systems where all trust anchors are stored in a 
    /// directory (e.g. /etc/ssl/certs).
    /// 
    /// - Parameter caDirPath: Path of directory containing all trust CAs, in PEM format.
    public func withCaDirPath(_ caDirPath: String) {
        _caDirPath = caDirPath
    }

    /// Overrides the default system trust store.
    /// 
    /// - Parameter caData: Data containing all trust CAs, in PEM format.
    public func withCaData(_ caData: Data) {
        _caData = caData
    }

    /// Use specified labels when importing certificate and key into keychain.
    ///
    /// NOTE: This option is only available on iOS and tvOS.
    /// 
    /// - Parameters:
    ///   - certLabel: Human readable label to apply to certificate being imported into keychain.
    ///   - keyLabel: Human readable label to apply to key being imported into keychain.
    public func withSecitemLabels(certLabel: String? = nil, keyLabel: String? = nil) {
        _certLabel = certLabel
        _keyLabel = keyLabel
    }

    /// Overrides the time interval to wait for an ack after sending a QoS 1+ PUBLISH, SUBSCRIBE, or UNSUBSCRIBE before
    /// failing the operation.  Defaults to no timeout.
    /// 
    /// - Parameter ackTimeout: Time interval to wait for an ack after sending a QoS 1+ PUBLISH, SUBSCRIBE,
    ///   or UNSUBSCRIBE before failing the operation.
    public func withAckTimeout(_ ackTimeout: TimeInterval) {
        _ackTimeout = ackTimeout
    }

    /// Overrides the time interval to wait after sending a CONNECT request for a CONNACK to arrive.  If one does not
    /// arrive, the connection will be shut down.
    /// 
    /// - Parameter connackTimeout: Time interval to wait after sending a CONNECT request for a CONNACK to arrive.
    public func withConnackTimeout(_ connackTimeout: TimeInterval) {
        _connackTimeout = connackTimeout
    }

    /// Overrides the time interval to wait after sending a PINGREQ for a PINGRESP to arrive.  If one does not arrive,
    /// the client will close the current connection.
    /// 
    /// - Parameter pingTimeout: Time interval to wait after sending a PINGREQ for a PINGRESP to arrive.
    public func withPingTimeout(_ pingTimeout: TimeInterval) {
        _pingTimeout = pingTimeout
    }

    /// Overrides the minimum amount of time to wait to reconnect after a disconnect.  Exponential backoff is performed
    /// with controllable jitter after each connection failure.
    /// 
    /// - Parameter minReconnectDelay: Minimum amount of time to wait to reconnect after a disconnect.
    public func withMinReconnectDelay(_ minReconnectDelay: TimeInterval) {
        _minReconnectDelay = minReconnectDelay
    }

    /// Overrides the maximum amount of time to wait to reconnect after a disconnect.  Exponential backoff is performed
    /// with controllable jitter after each connection failure.
    /// 
    /// - Parameter maxReconnectDelay: Maximum amount of time to wait to reconnect after a disconnect.
    public func withMaxReconnectDelay(_ maxReconnectDelay: TimeInterval) {
        _maxReconnectDelay = maxReconnectDelay
    }

    /// Overrides the amount of time that must elapse with an established connection before the reconnect delay is
    /// reset to the minimum.  This helps alleviate bandwidth-waste in fast reconnect cycles due to permission
    /// failures on operations.
    /// 
    /// - Parameter minConnectedTimeToResetReconnectDelay: The amount of time that must elapse with an established
    ///   connection before the reconnect delay is reset to the minimum
    public func withMinConnectedTimeToResetReconnectDelay(_ minConnectedTimeToResetReconnectDelay: TimeInterval) {
        _minConnectedTimeToResetReconnectDelay = minConnectedTimeToResetReconnectDelay
    }

    /// Overrides how the reconnect delay is modified in order to smooth out the distribution of reconnection attempt
    /// timepoints for a large set of reconnecting clients.
    /// 
    /// - Parameter retryJitterMode: Controls how the reconnect delay is modified in order to smooth out the distribution of
    ///   reconnection attempt timepoints for a large set of reconnecting clients.
    public func withRetryJitterMode(_ retryJitterMode: ExponentialBackoffJitterMode) {
        _retryJitterMode = retryJitterMode
    }

    /// Overrides how disconnects affect the queued and in-progress operations tracked by the client.  Also controls
    /// how new operations are handled while the client is not connected.  In particular, if the client is not connected,
    /// then any operation that would be failed on disconnect (according to these rules) will also be rejected.
    /// 
    /// - Parameter clientOperationQueueBehaviorType: How disconnects affect the queued and in-progress operations tracked 
    ///   by the client.
    public func withClientOperationQueueBehaviorType(_ clientOperationQueueBehaviorType: ClientOperationQueueBehaviorType) {
        _clientOperationQueueBehaviorType = clientOperationQueueBehaviorType
    }

    /// Overrides how the MQTT5 client should behave with respect to MQTT sessions.
    /// 
    /// - Parameter clientSessionBehaviorType: How the MQTT5 client should behave with respect to MQTT sessions.
    public func withClientSessionBehaviorType(_ clientSessionBehaviorType: ClientSessionBehaviorType) {
        _clientSessionBehaviorType = clientSessionBehaviorType
    }

    /// Overrides how the MQTT5 client should behave with respect to topic aliasing
    /// 
    /// - Parameter topicAliasingOptions: How the MQTT5 client should behave with respect to topic aliasing.
    public func withTopicAliasingOptions(_ topicAliasingOptions: TopicAliasingOptions) {
        _topicAliasingOptions = topicAliasingOptions
    }

    /// Overrides (tunneling) HTTP proxy usage when establishing MQTT connections.
    /// 
    /// - Parameter httpProxyOptions: HTTP proxy options to use when establishing MQTT connections.
    public func withHttyProxyOptions(_ httpProxyOptions: HTTPProxyOptions) {
        _httpProxyOptions = httpProxyOptions
    }

    /// Overrides the socket properties of the underlying MQTT connections made by the client.  Leave undefined to use
    /// defaults (no TCP keep alive, 10 second socket timeout).
    /// 
    /// - Parameter socketOptions: Socket properties of the underlying MQTT connections made by the client.
    public func withSocketOptions(_ socketOptions: SocketOptions) {
        _socketOptions = socketOptions
    }

    /// Overrides the ClientBootstrap used by the MQTT5 client to establish MQTT connections. If one isn't provided, 
    /// one will be created during MQTT5 Client creation.
    /// 
    /// - Parameter clientBootstrap: The client boootstrap to be used when establishing MQTT connections.
    public func withBootstrap(_ clientBootstrap: ClientBootstrap){
        _clientBootstrap = clientBootstrap
    }

    /// If true, requests that the server send response information in the subsequent CONNACK.  This response 
    /// information may be used to set up request-response implementations over MQTT, but doing so is outside 
    /// the scope of the MQTT5 spec and client.
    /// 
    /// See [MQTT5 Request Response Information](https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901052)
    /// 
    /// - Parameter requestResponseInformation: Set requestResponseInformation.
    public func withRequestResponseInformation(_ requestResponseInformation: Bool) {
        _requestResponseInformation = requestResponseInformation
    }

    /// If true, requests that the server send additional diagnostic information (via response string or user properties)
    /// in DISCONNECT or CONNACK packets from the server.
    /// 
    /// See [MQTT5 Request Problem Information](https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901053)
    /// 
    /// - Parameter requestProblemInformation: Set requestProblemInformation.
    public func withRequestProblemInformation(_ requestProblemInformation: Bool){
        _requestProblemInformation = requestProblemInformation
    }

    /// Notifies the server of the maximum number of in-flight QoS 1 and 2 messages the client is willing to handle.
    /// If omitted or null, then no limit is requested.
    /// 
    /// See [MQTT5 Receive Maximum](https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901049)
    /// 
    /// - Parameter receiveMaximum: Maximum number of in-flight QoS 1 and 2 messages the client is willing to handle.
    public func withReceiveMaximum(_ receiveMaximum: UInt16) {
        _receiveMaximum = receiveMaximum
    }

    /// Notifies the server of the maximum packet size the client is willing to handle.  If omitted, then no limit 
    /// beyond the natural limits of MQTT packet size is requested.
    /// 
    /// See [MQTT5 Maximum Packet Size](https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901050)
    /// 
    /// - Parameter maximumPacketSize: Maximum packet size the client is willing to handle.
    public func withMaximumPacketSize(_ maximumPacketSize: UInt32) {
        _maximumPacketSize = maximumPacketSize
    }

    /// A time interval, in seconds, that the server should wait (for a session reconnection) before sending the
    /// will message associated with the connection's session.  If omitted, the server will send the will when the
    /// associated session is destroyed.  If the session is destroyed before a will delay interval has elapsed, then
    /// the will must be sent at the time of session destruction.
    /// 
    /// See [MQTT5 Will Delay Interval](https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901062)
    /// 
    /// - Parameter willDelayInterval: Time interval, in seconds, that the server should wait (for a session reconnection) 
    ///   before sending the will message associated with the connection's session.
    public func withWillDelayInterval(_ willDelayInterval: TimeInterval) {
        _willDelayInterval = willDelayInterval
    }

    /// The definition of a message to be published when the connection's session is destroyed by the server or when the 
    /// will delay interval has elapsed, whichever comes first.  If undefined, then nothing will be sent.
    /// 
    /// See [MQTT5 Will](https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901040)
    /// 
    /// - Parameter will: The definition of a message to be published when the connection's session is destroyed by the server or when the 
    ///   will delay interval has elapsed, whichever comes first.
    public func withWill(_ will: PublishPacket) {
        _will = will
    }
    
    /// Set of MQTT5 user properties included with the packet.
    /// 
    /// See [MQTT5 User Property](https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901054)
    /// 
    /// - Parameter userProperties: Set of MQTT5 user properties included with the packet.
    public func withUserProperties(_ userProperties: [UserProperty]) {
        _userProperties = userProperties
    }

    /// Constructs an MQTT5 Client configured using properties and set in the mqtt5ClientBuilder.
    /// 
    /// - Throws: `CommonRuntimeError.crtError`
    /// - Returns: An MQTT5 Client configured using the connection method and options set on the mqtt5ClientBuilder.
    public func build() throws -> Mqtt5Client {
        guard let unwrappedEndpoint = _endpoint else {
            throw AwsIotDeviceSdkError.missingParameter(parameterName: "Mqtt5ClientBuilder requires endpoint to build client.")
        }

        var metricsUsername: String? = _username ?? nil
        if _enableMetricsCollection {
            metricsUsername = ""
            let baseUsername = _username ?? ""
            metricsUsername = baseUsername + getMetricsStr(currentUsername: baseUsername)
        }

        _extendedValidationAndFlowControlOptions = .awsIotCoreDefaults

        // Configure connection options
        let connectOptions = MqttConnectOptions(
            keepAliveInterval: _keepAliveInterval,
            clientId: _clientId,
            username: metricsUsername,
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

        var _tlsCtx: TLSContext? = nil
        do {
            if let tlsOptions = _tlsOptions {
                // Handle CA override
                if let caPath = _caDirPath {
                    try tlsOptions.overrideDefaultTrustStoreWithPath(caPath: caPath)
                } else if let caFile = _caFilePath {
                    try tlsOptions.overrideDefaultTrustStoreWithFile(caFile: caFile)
                } else if let caData = _caData {
                    try tlsOptions.overrideDefaultTrustStoreWithData(caData: caData)
                }

                // Apply labels if available
                try tlsOptions.setSecitemLabels(certLabel: _certLabel, keyLabel: _keyLabel)
                
                _tlsCtx = try TLSContext(options:tlsOptions, mode: .client)
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
