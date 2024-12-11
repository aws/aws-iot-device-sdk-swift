///  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
///  SPDX-License-Identifier: Apache-2.0.

import Foundation
import AwsCommonRuntimeKit

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

public class Mqtt5ClientBuilder {

    var _endpoint: String? = nil
    var _port: UInt32 = 8883
    var _tlsCtx: TLSContext? = nil
    var _onWebsocketTransform: OnWebSocketHandshakeIntercept? = nil
    var _clientId: String? = nil
    var _username: String? = nil
    var _password: Data? = nil
    var _keepAliveInterval: TimeInterval = 1200
    var _sessionExpiryInterval: TimeInterval? = nil
    var _extendedValidationAndFlowControlOptions: ExtendedValidationAndFlowControlOptions? = .awsIotCoreDefaults
    var _onPublishReceived: OnPublishReceived? = nil
    var _onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect? = nil
    var _onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess? = nil
    var _onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure? = nil
    var _onLifecycleEventDisconnection: OnLifecycleEventDisconnection? = nil
    var _onLifecycleEventStopped: OnLifecycleEventStopped? = nil
    var _enableMetricsCollection: Bool = true

    // mtlsFromPath
    init (certPath: String, keyPath: String, endpoint: String, port: UInt32 = 8883) throws {
        let tlsOptions = try TLSContextOptions.makeMTLS(certificatePath: certPath, privateKeyPath: keyPath)
        _tlsCtx = try TLSContext(options:tlsOptions, mode: .client)
        _endpoint = endpoint
        _port = port
    }

    // mtlsFromData
    init (certData: Data, keyData: Data, endpoint: String, port: UInt32 = 8883) throws {
        let tlsOptions = try TLSContextOptions.makeMTLS(certificateData: certData, privateKeyData: keyData)
        _tlsCtx = try TLSContext(options:tlsOptions, mode: .client)
        _endpoint = endpoint
        _port = port
    }

    // mtlsFromPKCS12
    init (pkcs12Path: String, pkcs12Password: String, endpoint: String, port: UInt32 = 8883) throws {
        let tlsOptions = try TLSContextOptions.makeMTLS(pkcs12Path: pkcs12Path, password: pkcs12Password)
        _tlsCtx = try TLSContext(options:tlsOptions, mode: .client)
        _endpoint = endpoint
        _port = port
    }

    // websocketsWithDefaultAwsSigning
    init (endpoint: String, port: UInt32 = 443, region: String, credentialsProvider: CredentialsProvider) throws {
        let tlsOptions = TLSContextOptions.makeDefault()
        _tlsCtx = try TLSContext(options: tlsOptions, mode: .client)
        _endpoint = endpoint
        _port = port
            
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
          port: UInt32 = 443,
          authAuthorizerName: String? = nil,
          authPassword: Data? = nil,
          authAuthorizerSignature: String? = nil,
          authTokenKeyName: String? = nil,
          authTokenValue: String? = nil,
          authUsername: String? = nil,
          useWebsocket: Bool = true) throws {
        
        _endpoint = endpoint
        _port = port

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

        let tlsOptions = TLSContextOptions.makeDefault()

        if (useWebsocket) {
            _onWebsocketTransform = { httpRequest, completeCallback in 
                completeCallback(httpRequest, 0)            
            }
        } else {
            tlsOptions.setAlpnList(["mqtt"])
        }

        _tlsCtx = try TLSContext(options: tlsOptions, mode: .client)
    }

    public static func mtlsFromPath(
        certPath: String, 
        keyPath: String,
        endpoint: String,
        port: UInt32 = 8883) throws -> Mqtt5ClientBuilder {

        return try Mqtt5ClientBuilder(certPath: certPath, keyPath: keyPath, endpoint: endpoint, port: port)
    }

    public static func mtlsFromData(
        certData: Data, 
        keyData: Data,
        endpoint: String,
        port: UInt32 = 8883) throws -> Mqtt5ClientBuilder  {

        return try Mqtt5ClientBuilder(certData: certData, keyData: keyData, endpoint: endpoint, port: port)
    }

    public static func mtlsFromPKCS12(
        pkcs12Path: String, 
        pkcs12Password: String,
        endpoint: String,
        port: UInt32 = 8883) throws -> Mqtt5ClientBuilder {
        
        return try Mqtt5ClientBuilder(pkcs12Path: pkcs12Path, pkcs12Password: pkcs12Password, endpoint: endpoint, port: port)
    }

    public static func websocketsWithDefaultAwsSigning(endpoint: String,
                                                       port: UInt32 = 443,
                                                       region: String, 
                                                       credentialsProvider: CredentialsProvider) throws -> Mqtt5ClientBuilder {

        return try Mqtt5ClientBuilder(endpoint: endpoint, 
                                      port: port, 
                                      region: region, 
                                      credentialsProvider: credentialsProvider)
    }

    /// Custom Auth

    /// Creates and returns an Mqtt5ClientBuilder configured for an MQTT5 Client using a custom authorizer
    /// 
    /// - Parameters:
    ///   - endpoint: Host name of AWS IoT server.
    ///   - port: Override default server port.
    ///     Default port is 443 if system supports ALPN or websockets are being used.
    ///     Otherwise, default port is 8883.
    ///   - authUsername: The username to use with the custom authorizer.
    ///     If provided, the username given will be passed when connecting to the custom authorizer.
    ///     If not provided, it will check to see if a username has already been set (via username="example")
    ///     and will use that instead.  Custom authentication parameters will be appended as appropriate
    ///     to any supplied username value.
    ///   - authPassword: The password to use with the custom authorizer.
    ///     If not provided, then no password will be sent in the initial CONNECT packet.
    ///   - authAuthorizerName: Name of the custom authorizer to use.
    ///     Required if the endpoint does not have a default custom authorizer associated with it.  It is strongly
    ///     suggested to URL-encode this value; the SDK will not do so for you.
    ///   - authAuthorizerSignature: The digital signature of the token value in the `auth_token_value`
    ///     parameter. The signature must be based on the private key associated with the custom authorizer.  The
    ///     signature must be base64 encoded.
    ///     Required if the custom authorizer has signing enabled.
    ///   - authTokenKeyName: Key used to extract the custom authorizer token from MQTT username query-string
    ///     properties.
    ///     Required if the custom authorizer has signing enabled.  It is strongly suggested to URL-encode
    ///     this value; the SDK will not do so for you.
    ///   - authTokenValue: An opaque token value. This value must be signed by the private key associated with
    ///     the custom authorizer and the result passed in via the `auth_authorizer_signature` parameter.
    ///     Required if the custom authorizer has signing enabled.
    /// - Throws: 
    /// - Returns: an Mqtt5ClientBuilder configured for an MQTT5 Client using a custom authorizer


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

    public static func websocketsWithCustomAuthorizer(endpoint: String,
                                                      port: UInt32 = 443,
                                                      authAuthorizerName: String,
                                                      authPassword: Data,
                                                      authUsername: String? = nil) throws -> Mqtt5ClientBuilder {
        
        return try Mqtt5ClientBuilder(endpoint: endpoint,
                                      port:port,
                                      authAuthorizerName: authAuthorizerName,
                                      authPassword: authPassword,
                                      authUsername: authUsername,
                                      useWebsocket: true)
    }

    public static func websocketsWithUnsignedCustomAuthorizer(endpoint: String,
                                                              port: UInt32 = 443,
                                                              authAuthorizerName: String,
                                                              authPassword: Data? = nil,
                                                              authTokenKeyName: String,
                                                              authTokenValue: String,
                                                              authUsername: String? = nil) throws -> Mqtt5ClientBuilder {
        
        return try Mqtt5ClientBuilder(endpoint: endpoint,
                                      port:port,
                                      authAuthorizerName: authAuthorizerName,
                                      authPassword: authPassword,
                                      authTokenKeyName: authTokenKeyName,
                                      authTokenValue:authTokenValue,
                                      authUsername: authUsername,
                                      useWebsocket: true)
    }

    public static func websocketsWithSignedCustomAuthorizer(endpoint: String,
                                                            port: UInt32 = 443,
                                                            authAuthorizerName: String,
                                                            authPassword: Data? = nil,
                                                            authAuthorizerSignature: String,
                                                            authTokenKeyName: String,
                                                            authTokenValue: String,
                                                            authUsername: String? = nil) throws -> Mqtt5ClientBuilder {
        
        return try Mqtt5ClientBuilder(endpoint: endpoint,
                                      port:port,
                                      authAuthorizerName: authAuthorizerName,
                                      authPassword: authPassword,
                                      authAuthorizerSignature: authAuthorizerSignature,
                                      authTokenKeyName: authTokenKeyName,
                                      authTokenValue:authTokenValue,
                                      authUsername: authUsername,
                                      useWebsocket: true)
    }

    public static func directWithUnsignedCustomAuthorizer(endpoint: String,
                                                          port: UInt32 = 443,
                                                          authAuthorizerName: String? = nil,
                                                          authPassword: Data? = nil,
                                                          authUsername: String? = nil) throws -> Mqtt5ClientBuilder {
    
        return try Mqtt5ClientBuilder(endpoint: endpoint,
                                      port:port,
                                      authAuthorizerName: authAuthorizerName,
                                      authPassword: authPassword,
                                      authUsername: authUsername,
                                      useWebsocket: false)
    }

    public static func directWithSignedCustomAuthorizer(endpoint: String,
                                                        port: UInt32 = 443,
                                                        authAuthorizerName: String,
                                                        authAuthorizerSignature: String,
                                                        authTokenKeyName: String,
                                                        authTokenValue: String,
                                                        authUsername: String? = nil,
                                                        authPassword: Data? = nil) throws -> Mqtt5ClientBuilder {
        
        return try Mqtt5ClientBuilder(endpoint: endpoint,
                                      port:port,
                                      authAuthorizerName: authAuthorizerName,
                                      authPassword: authPassword,
                                      authAuthorizerSignature: authAuthorizerSignature,
                                      authTokenKeyName: authTokenKeyName,
                                      authTokenValue:authTokenValue,
                                      authUsername: authUsername,
                                      useWebsocket: false)
    }

    /*
    **client_options** (:class:`awscrt.mqtt5.ClientOptions`): This dataclass can be used to to apply all
            configuration options for Client creation. Any options set within will supercede defaults
            assigned by the builder. Any omitted arguments within this class will be filled by additional
            keyword arguments provided to the builder or be set to their default values.

    **connect_options** (:class:`awscrt.mqtt5.ConnectPacket`): This dataclass can be used to apply connection
            options for the client. Any options set within will supercede defaults assigned by the builder but
            will not overwrite options set by connect_options included within a client_options keyword argument.
            Any omitted arguments within this class will be assigned values of keyword arguments provided to
            the builder.

    **client_bootstrap** (:class:`awscrt.io.ClientBootstrap`): Client bootstrap used to establish connection.
        The ClientBootstrap will default to the static default (Io.ClientBootstrap.get_or_create_static_default)
        if the argument is omitted or set to 'None'.

    **http_proxy_options** (:class:`awscrt.http.HttpProxyOptions`): HTTP proxy options to use

    **request_response_information** (`bool`): If true, requests that the server send response information in
        the subsequent CONNACK.  This response information may be used to set up request-response implementations
        over MQTT, but doing so is outside the scope of the MQTT5 spec and client.

    **request_problem_information** (`bool`): If true, requests that the server send additional diagnostic
        information (via response string or user properties) in DISCONNECT or CONNACK packets from the server.

    **receive_maximum** (`int`): Notifies the server of the maximum number of in-flight QoS 1 and 2 messages the
        client is willing to handle.  If omitted or null, then no limit is requested.

    **maximum_packet_size** (`int`): Notifies the server of the maximum packet size the client is willing to handle.
        If omitted or null, then no limit beyond the natural limits of MQTT packet size is requested.

    **will_delay_interval_sec** (`int`): A time interval, in seconds, that the server should wait (for a session
        reconnection) before sending the will message associated with the connection's session.  If omitted or
        null, the server will send the will when the associated session is destroyed.  If the session is destroyed
        before a will delay interval has elapsed, then the will must be sent at the time of session destruction.

    **will** (:class:`awscrt.mqtt5.PublishPacket`): The definition of a message to be published when the connection's
        session is destroyed by the server or when the will delay interval has elapsed, whichever comes first.  If
        null, then nothing will be sent.

    **user_properties** (`Sequence` [:class:`awscrt.mqtt5.UserProperty`]): List of MQTT5 user properties included
        with the packet.

    **session_behavior** (:class:`awscrt.mqtt5.ClientSessionBehaviorType`): How the MQTT5 client should behave with
        respect to MQTT sessions.



    **offline_queue_behavior** (:class:`awscrt.mqtt5.ClientOperationQueueBehaviorType`): Returns how disconnects
        affect the queued and in-progress operations tracked by the client.  Also controls how new operations are
        handled while the client is not connected.  In particular, if the client is not connected, then any operation
        that would be failed on disconnect (according to these rules) will also be rejected.

    **topic_aliasing_options** (:class:`awscrt.mqtt5.TopicAliasingOptions`): Configuration options for how the client
        should use the topic aliasing features of MQTT5

    **retry_jitter_mode** (:class:`awscrt.mqtt5.ExponentialBackoffJitterMode`): How the reconnect delay is modified
        in order to smooth out the distribution of reconnection attempt timepoints for a large set of reconnecting
        clients.

    **min_reconnect_delay_ms** (`int`): The minimum amount of time to wait to reconnect after a disconnect.
        Exponential backoff is performed with jitter after each connection failure.

    **max_reconnect_delay_ms** (`int`): The maximum amount of time to wait to reconnect after a disconnect.
    Exponential backoff is performed with jitter after each connection failure.

    **min_connected_time_to_reset_reconnect_delay_ms** (`int`): The amount of time that must elapse with an
        established connection before the reconnect delay is reset to the minimum. This helps alleviate
        bandwidth-waste in fast reconnect cycles due to permission failures on operations.

    **ping_timeout_ms** (`int`): The time interval to wait after sending a PINGREQ for a PINGRESP to arrive. If one
        does not arrive, the client will close the current connection.

    **connack_timeout_ms** (`int`): The time interval to wait after sending a CONNECT request for a CONNACK to arrive.
        If one does not arrive, the connection will be shut down.

    **ack_timeout_sec** (`int`): The time interval to wait for an ack after sending a QoS 1+ PUBLISH, SUBSCRIBE,
        or UNSUBSCRIBE before failing the operation.

    **ca_filepath** (`str`): Override default trust store with CA certificates from this PEM formatted file.

    **ca_dirpath** (`str`): Override default trust store with CA certificates loaded from this directory (Unix only).

    **ca_bytes** (`bytes`): Override default trust store with CA certificates from these PEM formatted bytes.
    */

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

    /// Whether to send the SDK version number in the CONNECT packet.
    /// Default is True.
    ///
    /// - Parameter enableMetricsCollection: (Bool)
    public func withMetricsCollection(_ enableMetricsCollection: Bool) {
        _enableMetricsCollection = enableMetricsCollection
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
            sessionExpiryInterval: _sessionExpiryInterval
        )
    
        // Configure client options
        let clientOptions = MqttClientOptions(
            hostName: unwrappedEndpoint,
            port: _port,
            tlsCtx: _tlsCtx,
            onWebsocketTransform: _onWebsocketTransform,
            connectOptions: connectOptions,
            extendedValidationAndFlowControlOptions: _extendedValidationAndFlowControlOptions,
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
