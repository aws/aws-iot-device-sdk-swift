// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import SwiftUI
import AwsIotDeviceSdkSwift

// The app setup a direct connection with mTLS options.
// Update the host before run the app.
let TEST_HOST = "<endpoint>"
// The test topic we subscribe and publish to
let TEST_TOPIC = "test/topic"

var mqttTestContext = MqttTestContext()
var client: Mqtt5Client?
var publishCount = 0

struct ContentView: View {
    @ObservedObject var testContext = mqttTestContext
    var body: some View {
        VStack {
            Button("Setup Client and Start") {
                Task {
                    await setupClientAndStart()
                }
            }
            Button("Publish A Message") {
                Task {
                    await PublishAMessage()
                }
            }
            Button("Stop Connection") {
                Task {
                    await stopClient()
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
}

public var onLifecycleEventStopped: OnLifecycleEventStopped = { _ in
    mqttTestContext.printView("Lifecycle Event Stopped")
}

public var onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect = { _ in
    mqttTestContext.printView("Lifecycle Event Attempting Connect")
}

public var onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess = { _ in
    mqttTestContext.printView("Lifecycle Event Connection Success")
    // 3. If connection succeed, subscribe to topic
    do {
        let suback = try await client!.subscribe(subscribePacket: SubscribePacket(
            subscription: Subscription(topicFilter: TEST_TOPIC, qos: QoS.atLeastOnce)))
        print("SubackPacket received with result \(suback.reasonCodes[0])")
    } catch {
        print("Client failed to subscribe. ")
    }
}
public var onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure = { failureData in
    mqttTestContext.printView("Lifecycle Event Connection Failure: (\(failureData.crtError.code)) \(failureData.crtError.message)")
}
public var onLifecycleEventDisconnection: OnLifecycleEventDisconnection = { disconnectionData in
    mqttTestContext.printView("Lifecycle Event Disconnection:  (\(disconnectionData.crtError.code)) \(disconnectionData.crtError.message) ")
}

// This Function shows how to create a MQTT connection using a certificate file and key file.
// Here is the steps to setup a client and connection
// 0. Initialize the library
// 1. Setup Connect Options & Create a Mqtt Client
// 2. Start a connection session
// 3. Subscribe to test topic
// 4. Publish Messages
// 5. Stop session
func setupClientAndStart() async {

    // Grab credential data from file
    let certData = try! Data(contentsOf: Bundle.main.url(forResource: "cert", withExtension: "pem")!)
    let keyData = try! Data(contentsOf: Bundle.main.url(forResource: "privatekey", withExtension: "pem")!)

    do {
        if client == nil {
            // 0. Initialize the library
            CommonRuntimeKit.initialize()
            // Uncomment the following line to init debug log to help with debugging.
            // try? Logger.initialize(target: .standardOutput, level: .debug)

            // 1. Setup Connect Options & Create a Mqtt Client
            // 1.1 Create and config a client builder to access credentials from data
            let clientBuilder = try Mqtt5ClientBuilder.mtlsFromData(certData: certData, keyData: keyData, endpoint: TEST_HOST)
            // 1.2 Setup callbacks and other client options
            clientBuilder.withClientId("test-" + UUID().uuidString)
            clientBuilder.withCallbacks(onPublishReceived: onPublishReceived,
                                        onLifecycleEventAttemptingConnect: onLifecycleEventAttemptingConnect,
                                        onLifecycleEventConnectionSuccess: onLifecycleEventConnectionSuccess,
                                        onLifecycleEventConnectionFailure: onLifecycleEventConnectionFailure,
                                        onLifecycleEventDisconnection: onLifecycleEventDisconnection,
                                        onLifecycleEventStopped: onLifecycleEventStopped)
            // 1.3 use the builder to create the Mqtt5 Client
            client = try clientBuilder.build()
        }

        if let _client  = client {
            // 2. Start a connection session
            try _client.start()
        }
    } catch let err {
        mqttTestContext.printView("Failed to setup client: \(err)")
    }
}

func PublishAMessage() async {
    if let _client  = client {
        do {
            // 4. Publish Messages
            let publishResult : PublishResult = try await _client.publish(publishPacket: PublishPacket(qos: QoS.atLeastOnce, topic: TEST_TOPIC, payload: ("Hello World \(publishCount)".data(using: .utf8))))
            publishCount += 1
            mqttTestContext.printView("Publish result with reason code: (\(String(describing: publishResult.puback?.reasonCode))) :  \(String(describing: publishResult.puback?.reasonString))")
        } catch let err {
            mqttTestContext.printView("Publish Message Failed: \(err)")
        }
    } else {
        mqttTestContext.printView("Client is not started, please \"Setup Client and Start\" first.")
    }
}

func stopClient() async {

    if let _client  = client {
        do {
            // 5. Stop connection session
            try _client.stop()
        } catch let err {
            mqttTestContext.printView("Failed to stop the client: \(err)")
        }
    } else {
        mqttTestContext.printView("Client is not started, please \"Setup Client and Start\" first.")
    }

}
