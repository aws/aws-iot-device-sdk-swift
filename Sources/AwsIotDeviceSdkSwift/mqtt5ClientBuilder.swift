///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import Foundation
@_exported import AwsCommonRuntimeKit
// import AwsCommonRuntimeKit

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
    private var _caPath: String? = nil
    private var _caFile: String? = nil
    private var _caData: Data? = nil

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

    public static func mtlsFromPath(
        certPath: String, 
        keyPath: String,
        endpoint: String) throws -> Mqtt5ClientBuilder {

        return try Mqtt5ClientBuilder(certPath: certPath, keyPath: keyPath, endpoint: endpoint)
    }

    public static func mtlsFromData(
        certData: Data, 
        keyData: Data,
        endpoint: String) throws -> Mqtt5ClientBuilder  {

        return try Mqtt5ClientBuilder(certData: certData, keyData: keyData, endpoint: endpoint)
    }

    public static func mtlsFromPKCS12(
        pkcs12Path: String, 
        pkcs12Password: String,
        endpoint: String) throws -> Mqtt5ClientBuilder {
        
        return try Mqtt5ClientBuilder(pkcs12Path: pkcs12Path, pkcs12Password: pkcs12Password, endpoint: endpoint)
    }

    public static func websocketsWithDefaultAwsSigning(endpoint: String,
                                                       region: String, 
                                                       credentialsProvider: CredentialsProvider) throws -> Mqtt5ClientBuilder {

        return try Mqtt5ClientBuilder(endpoint: endpoint,
                                      region: region, 
                                      credentialsProvider: credentialsProvider)
    }    

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

    public static func websocketsWithSignedCustomAuthorizer(endpoint: String,
                                                            authAuthorizerName: String,
                                                            authPassword: Data? = nil,
                                                            authAuthorizerSignature: String,
                                                            authTokenKeyName: String,
                                                            authTokenValue: String,
                                                            authUsername: String? = nil) throws -> Mqtt5ClientBuilder {
        
        return try Mqtt5ClientBuilder(endpoint: endpoint,
                                      authAuthorizerName: authAuthorizerName,
                                      authPassword: authPassword,
                                      authAuthorizerSignature: authAuthorizerSignature,
                                      authTokenKeyName: authTokenKeyName,
                                      authTokenValue:authTokenValue,
                                      authUsername: authUsername,
                                      useWebsocket: true)
    }

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

    /// Set callbacks for MQTT5 Client. 
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

    public func withOnPublishReceived(_ onPublishReceived: OnPublishReceived?) {
        _onPublishReceived = onPublishReceived
    }

    public func withOnLifecycleEventAttemptingConnect(_ onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect?) {
        _onLifecycleEventAttemptingConnect = onLifecycleEventAttemptingConnect
    }

    public func withOnLifecycleEventConnectionSuccess(_ onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess?) {
        _onLifecycleEventConnectionSuccess = onLifecycleEventConnectionSuccess
    }

    public func withOnLifecycleEventConnectionFailure(_ onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure?) {
        _onLifecycleEventConnectionFailure = onLifecycleEventConnectionFailure
    }

    public func withOnLifecycleEventDisconnection(_ onLifecycleEventDisconnection: OnLifecycleEventDisconnection?) {
        _onLifecycleEventDisconnection = onLifecycleEventDisconnection
    }

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
    public func withExtendedValidationAndFlowControlOptions(_ flowControlOptions: ExtendedValidationAndFlowControlOptions) {
        _extendedValidationAndFlowControlOptions = flowControlOptions
    }

    // DEBUG WIP we need to make sure the CA is being set properly in tls ctx    
    public func withCaPath(_ caPath: String) {
        _caPath = caPath
    }

    private var _caDirPath: String? = nil
    public func withCaDirPath(_ caDirPath: String) {
        _caDirPath = caDirPath
    }

    public func withCaData(_ caData: Data) {
        _caData = caData
    }

    private var _ackTimeout: TimeInterval? = nil
    public func withAckTimeout(_ ackTimeout: TimeInterval) {
        _ackTimeout = ackTimeout
    }

    private var _connackTimeout: TimeInterval? = nil
    public func withConnackTimeout(_ connackTimeout: TimeInterval) {
        _connackTimeout = connackTimeout
    }

    private var _pingTimeout: TimeInterval? = nil
    public func withPingTimeout(_ pingTimeout: TimeInterval) {
        _pingTimeout = pingTimeout
    }

    private var _minReconnectDelay: TimeInterval? = nil
    public func withMinReconnectDelay(_ minReconnectDelay: TimeInterval) {
        _minReconnectDelay = minReconnectDelay
    }
    private var _maxReconnectDelay: TimeInterval? = nil
    public func withMaxReconnectDelay(_ maxReconnectDelay: TimeInterval) {
        _maxReconnectDelay = maxReconnectDelay
    }
    private var _minConnectedTimeToResetReconnectDelay: TimeInterval? = nil
    public func withMinConnectedTimeToResetReconnectDelay(_ minConnectedTimeToResetReconnectDelay: TimeInterval) {
        _minConnectedTimeToResetReconnectDelay = minConnectedTimeToResetReconnectDelay
    }

    private var _retryJitterMode: ExponentialBackoffJitterMode? = nil
    public func withRetryJitterMode(_ retryJitterMode: ExponentialBackoffJitterMode) {
        _retryJitterMode = retryJitterMode
    }

    private var _clientOperationQueueBehaviorType: ClientOperationQueueBehaviorType? = nil
    public func withClientOperationQueueBehaviorType(_ clientOperationQueueBehaviorType: ClientOperationQueueBehaviorType) {
        _clientOperationQueueBehaviorType = clientOperationQueueBehaviorType
    }

    private var _clientSessionBehaviorType: ClientSessionBehaviorType? = nil
    public func withClientSessionBehaviorType(_ clientSessionBehaviorType: ClientSessionBehaviorType) {
        _clientSessionBehaviorType = clientSessionBehaviorType
    }

    private var _topicAliasingOptions: TopicAliasingOptions? = nil
    public func withTopicAliasingOptions(_ topicAliasingOptions: TopicAliasingOptions) {
        _topicAliasingOptions = topicAliasingOptions
    }

    private var _httpProxyOptions: HTTPProxyOptions? = nil
    public func withHttyProxyOptions(_ httpProxyOptions: HTTPProxyOptions) {
        _httpProxyOptions = httpProxyOptions
    }

    private var _socketOptions: SocketOptions? = nil
    public func withSocketOptions(_ socketOptions: SocketOptions) {
        _socketOptions = socketOptions
    }

    private var _clientBootstrap: ClientBootstrap? = nil
    public func withBootstrap(_ clientBootstrap: ClientBootstrap){
        _clientBootstrap = clientBootstrap
    }

    private var _requestResponseInformation: Bool? = nil
    public func withRequestResponseInformation(_ requestResponseInformation: Bool) {
        _requestResponseInformation = requestResponseInformation
    }

    private var _requestProblemInformation: Bool? = nil
    public func withRequestProblemInformation(_ requestProblemInformation: Bool){
        _requestProblemInformation = requestProblemInformation
    }

    private var _receiveMaximum: UInt16? = nil
    public func withReceiveMaximum(_ receiveMaximum: UInt16) {
        _receiveMaximum = receiveMaximum
    }

    private var _maximumPacketSize: UInt32? = nil
    public func withMaximumPacketSize(_ maximumPacketSize: UInt32) {
        _maximumPacketSize = maximumPacketSize
    }

    private var _willDelayInterval: TimeInterval? = nil
    public func withWillDelayInterval(_ willDelayInterval: TimeInterval) {
        _willDelayInterval = willDelayInterval
    }

    private var _will: PublishPacket? = nil
    public func withWill(_ will: PublishPacket) {
        _will = will
    }

    private var _userProperties: [UserProperty]? = nil 
    public func withUserProperties(_ userProperties: [UserProperty]) {
        _userProperties = userProperties
    }

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
                if let caPath = _caPath {
                    try tlsOptions.overrideDefaultTrustStoreWithPath(caPath: caPath)
                } else if let caFile = _caFile {
                    try tlsOptions.overrideDefaultTrustStoreWithFile(caFile: caFile)
                } else if let caData = _caData {
                    try tlsOptions.overrideDefaultTrustStoreWithData(caData: caData)
                }
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
