// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import SwiftUI
import AwsIotDeviceSdkSwift

// The app setup a direct connection with mTLS options.
// Update the host before run the app.
let TEST_HOST = "<endpoint>"
let TEST_TOPIC = "test/topic";
let MESSAGE_NUMBER = 10;

var mqttTestContext = MqttTestContext()
var client: Mqtt5Client?

struct ContentView: View {
    @ObservedObject var testContext = mqttTestContext
    var body: some View {
        VStack {
            Button("Setup Client and Start") {
                Task {
                    await setupClientAndStart()
                }
            }
            NavigationView {
                List(testContext.messages) { message in
                    HStack {
                        Text(message.text)
                    }
                }.navigationBarTitle(Text("Messages"))
            }
        }
        .padding()
    }
    
}

/// Message struct for information print
struct Message: Identifiable {
    let id: Int
    let text: String
}


// We wait on smaphore to demostrate the client features and testing. However, you probably do not want to block
// the application in a real product.
public let semaphorePublishReceived: DispatchSemaphore = DispatchSemaphore(value: 0)
public let semaphoreConnectionSuccess: DispatchSemaphore = DispatchSemaphore(value: 0)
public let semaphoreConnectionFailure: DispatchSemaphore = DispatchSemaphore(value: 0)
public let semaphoreDisconnection: DispatchSemaphore = DispatchSemaphore(value: 0)
public let semaphoreStopped: DispatchSemaphore = DispatchSemaphore(value: 0)
public var publishCount = 0;

/// Test context to print messages on content view
class MqttTestContext: ObservableObject {
    @Published var messages: [Message] = [Message(id: 0, text: "Click the \"Setup Client and Start\" to start the client.")]
    
    /// Print the text and pending new message to message list
    func printView(_ txt: String) {
        let newMessage = Message(id: self.messages.count, text: txt)
        self.messages.append(newMessage)
        print(txt)
    }
}

public var onPublishReceived: OnPublishReceived = { publishData in
    var message = "Mqtt5ClientTests: onPublishReceived." +
    "Topic:\'\(publishData.publishPacket.topic)\' QoS:\(publishData.publishPacket.qos)"
    if let payloadString = publishData.publishPacket.payloadAsString() {
        message += "payload:\'\(payloadString)\'"
    }
    // Pending received publish to message list
    mqttTestContext.printView(message)
    publishCount += 1
    if(publishCount == MESSAGE_NUMBER)
    {
        semaphorePublishReceived.signal()
    }
}
public var onLifecycleEventStopped: OnLifecycleEventStopped = { _ in
    mqttTestContext.printView("Mqtt5ClientTests: onLifecycleEventStopped")
    semaphoreStopped.signal()
}

public var onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect = { _ in
    mqttTestContext.printView("Mqtt5ClientTests: onLifecycleEventAttemptingConnect")
}
public var onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess = { _ in
    mqttTestContext.printView("Mqtt5ClientTests: onLifecycleEventConnectionSuccess")
    semaphoreConnectionSuccess.signal()
}
public var onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure = { failureData in
    mqttTestContext.printView("Mqtt5ClientTests: onLifecycleEventConnectionFailure")
    semaphoreConnectionFailure.signal()
}
public var onLifecycleEventDisconnection: OnLifecycleEventDisconnection = { disconnectionData in
    mqttTestContext.printView("Mqtt5ClientTests: onLifecycleEventDisconnection:  \(disconnectionData.crtError.code)")
    semaphoreDisconnection.signal()
}

// This Function shows how to create a MQTT connection using a certificate file and key file.
// Here is the steps to setup a client and connection
// 0. Initialize the library
// 1. Setup Connect Options & Create a Mqtt Client
// 2. Start a connection session
// 3. Subscribe to topic
// 4. Publish Messages
// 5. Stop session
func setupClientAndStart() async {
    
    // 0. Initialize the library
    // Init the library
    CommonRuntimeKit.initialize()
    // Optional init debug log to help with debugging.
    try? Logger.initialize(target: .standardOutput, level: .debug)

    // 1.Setup Connect Options & Create a Mqtt Client
    // 1.1 Grab credential data from file
    let certData = try! Data(contentsOf: Bundle.main.url(forResource: "cert", withExtension: "pem")!)
    let keyData = try! Data(contentsOf: Bundle.main.url(forResource: "privatekey", withExtension: "pem")!)
    
    do {
        // 1.2 Create and config a client builder to access credentials from data
        let clientBuilder = try Mqtt5ClientBuilder.mtlsFromData(certData: certData, keyData: keyData, endpoint: TEST_HOST)
        // 1.3 Setup callbacks and other client options
        clientBuilder.withCallbacks(onPublishReceived: onPublishReceived,
                                    onLifecycleEventAttemptingConnect: onLifecycleEventAttemptingConnect,
                                    onLifecycleEventConnectionSuccess: onLifecycleEventConnectionSuccess,
                                    onLifecycleEventConnectionFailure: onLifecycleEventConnectionFailure,
                                    onLifecycleEventDisconnection: onLifecycleEventDisconnection,
                                    onLifecycleEventStopped: onLifecycleEventStopped)
        // 1.4 use the builder to create the Mqtt5 Client
        client = try clientBuilder.build()
        
        if let _client  = client {
            // 2. Start a connection session
            try _client.start()
            if semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
                print("Client failed to connect after 5 seconds")
            }
            
            // 3. Subscribe to topic
             async let _ = try await client!.subscribe(subscribePacket: SubscribePacket(
                subscription: Subscription(topicFilter: TEST_TOPIC, qos: QoS.atLeastOnce)))
            
            // 4. Publish Messages
            Task{
                var index = 0;
                while(index < MESSAGE_NUMBER){
                    let _: PublishResult = try! await _client.publish(publishPacket: PublishPacket(qos: QoS.atLeastOnce, topic: TEST_TOPIC, payload: ("Hello World \(index)".data(using: .utf8))))
                    index += 1;
                }
            }
            
            // Wait for all message get received
            semaphorePublishReceived.wait()
            
            // 5. Disconnect
            try _client.stop()
            if semaphoreDisconnection.wait(timeout: .now() + 5) == .timedOut {
                print("Client stop Failed after 5 seconds")
            }
            
        }
    } catch {
        mqttTestContext.printView("Failed to setup client.")
    }
}
